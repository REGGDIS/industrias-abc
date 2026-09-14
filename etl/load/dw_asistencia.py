from __future__ import annotations

from datetime import time, timedelta
from decimal import Decimal
from pathlib import Path

from etl.config.settings import get_dw_db_config
from etl.extract.postgres import get_postgres_connection
from etl.load.dw_rrhh import rut_dv_valido
from etl.transform.rut import normalize_rut
from etl.validate.asistencia.runner import obtener_datos, validar_datos


SQL_DIR = (
    Path(__file__).resolve().parents[1]
    / "sql"
    / "load"
    / "dw"
    / "asistencia"
)

FACT_COLUMNS = (
    "area_key",
    "cargo_key",
    "centro_costo_key",
    "turno_key",
    "hora_entrada",
    "hora_salida",
    "estado_asistencia",
    "horas_trabajadas",
    "horas_normales",
    "horas_extras",
    "minutos_atraso",
    "dias_trabajados",
    "dias_ausentes",
    "cantidad_registros",
)


def normalizar_rut(rut: str | None) -> str | None:
    """Alias compatible con el ETL previo, reutilizando la normalización Core."""
    return normalize_rut(rut)


def _to_time(value) -> time | None:
    if value is None:
        return None
    if isinstance(value, time):
        return value
    if isinstance(value, timedelta):
        seconds = int(value.total_seconds()) % (24 * 3600)
        return time(seconds // 3600, (seconds % 3600) // 60, seconds % 60)
    if isinstance(value, str):
        return time.fromisoformat(value)
    raise TypeError(f"Hora no soportada: {type(value).__name__}")


def _turno_bk(turno: dict) -> str:
    inicio = _to_time(turno["hora_inicio"])
    fin = _to_time(turno["hora_fin"])
    return (
        f"{str(turno['nombre_turno']).strip().upper()}|"
        f"{inicio.isoformat()}|{fin.isoformat()}"
    )


def extract_asistencia_clean() -> dict:
    """Reutiliza las salidas CLEAN y validaciones del ETL Asistencia cerrado."""
    trabajadores, turnos, asistencias = obtener_datos()
    resumen, resultados = validar_datos(trabajadores, turnos, asistencias)

    validas = [
        resultado["record"]
        for resultado in resultados
        if resultado["status"] == "VALID"
    ]
    rechazadas = [
        {
            "asistencia_id": resultado["record"].get("asistencia_id"),
            "reglas": list(resultado["errors"]),
            "severidad": "ERROR",
        }
        for resultado in resultados
        if resultado["status"] == "ERROR"
    ]

    return {
        "trabajadores": trabajadores,
        "turnos": turnos,
        "asistencias": asistencias,
        "validas": validas,
        "rechazadas": rechazadas,
        "resumen": resumen,
    }


def load_dim_turno(turnos: list[dict]) -> dict:
    """Carga DIM_TURNO SCD1 de forma idempotente desde el CLEAN vigente."""
    if not turnos:
        return {"inserted": 0, "updated": 0, "unchanged": 0}

    sql = (SQL_DIR / "cargar_dim_turno.sql").read_text(encoding="utf-8")
    config = get_dw_db_config()
    stats = {"inserted": 0, "updated": 0, "unchanged": 0}

    with get_postgres_connection(config) as connection:
        with connection.cursor() as cursor:
            for turno in turnos:
                row = {
                    "turno_bk": _turno_bk(turno),
                    "nombre_turno": str(turno["nombre_turno"]).strip().upper(),
                    "hora_inicio": _to_time(turno["hora_inicio"]),
                    "hora_fin": _to_time(turno["hora_fin"]),
                    "horas_jornada": Decimal(str(turno["horas_jornada"])),
                }
                cursor.execute(
                    """
                    SELECT nombre_turno, hora_inicio, hora_fin, horas_jornada
                    FROM dw.dim_turno
                    WHERE turno_bk = %s;
                    """,
                    (row["turno_bk"],),
                )
                existing = cursor.fetchone()

                if existing is None:
                    stats["inserted"] += 1
                    cursor.execute(sql, row)
                elif (
                    existing[0] == row["nombre_turno"]
                    and existing[1] == row["hora_inicio"]
                    and existing[2] == row["hora_fin"]
                    and Decimal(str(existing[3])) == row["horas_jornada"]
                ):
                    stats["unchanged"] += 1
                else:
                    stats["updated"] += 1
                    cursor.execute(sql, row)

        connection.commit()

    return stats


def cargar_dimensiones(turnos: list[dict]) -> dict:
    """Obtiene el contexto dimensional necesario para resolver la FACT."""
    config = get_dw_db_config()

    with get_postgres_connection(config) as connection:
        with connection.cursor() as cursor:
            cursor.execute("SELECT fecha, fecha_key FROM dw.dim_fecha;")
            fechas = dict(cursor.fetchall())

            cursor.execute(
                """
                SELECT empleado_key, rut_normalizado, area_key, cargo_key,
                       centro_costo_key, fecha_desde, fecha_hasta
                FROM dw.dim_empleado
                WHERE empleado_key <> 0
                ORDER BY rut_normalizado, fecha_desde;
                """
            )
            empleados_rows = cursor.fetchall()

            cursor.execute("SELECT turno_bk, turno_key FROM dw.dim_turno;")
            turnos_dw = dict(cursor.fetchall())

    empleados_por_rut: dict[str, list[dict]] = {}
    for row in empleados_rows:
        empleado = {
            "empleado_key": row[0],
            "rut_normalizado": row[1],
            "area_key": row[2],
            "cargo_key": row[3],
            "centro_costo_key": row[4],
            "fecha_desde": row[5],
            "fecha_hasta": row[6],
        }
        empleados_por_rut.setdefault(row[1], []).append(empleado)

    return {
        "fechas": fechas,
        "empleados": empleados_por_rut,
        "turnos_dw": turnos_dw,
        "turnos_origen": {turno["turno_id"]: _turno_bk(turno) for turno in turnos},
    }


def resolve_asistencia_dimension_keys(
    rows: list[dict],
    trabajadores: list[dict],
    dimensiones: dict,
) -> tuple[list[dict], list[dict], list[dict]]:
    """Resuelve claves conformadas; no fuerza homologaciones no determinísticas."""
    trabajadores_por_id = {
        trabajador["trabajador_id"]: trabajador
        for trabajador in trabajadores
    }
    resueltas: list[dict] = []
    rechazadas: list[dict] = []
    review: list[dict] = []
    claves_vistas: set[tuple[str, object]] = set()

    for row in rows:
        asistencia_id = row.get("asistencia_id")
        trabajador = trabajadores_por_id.get(row.get("trabajador_id"))
        if trabajador is None:
            rechazadas.append(
                {"asistencia_id": asistencia_id, "regla": "TRABAJADOR_NO_RESUELTO", "severidad": "ERROR"}
            )
            continue

        rut = normalizar_rut(trabajador.get("rut"))
        if not rut_dv_valido(rut):
            review.append(
                {"asistencia_id": asistencia_id, "regla": "RUT_INVALIDO", "severidad": "REVIEW"}
            )
            continue

        fecha = row.get("fecha")
        clave = (rut, fecha)
        if clave in claves_vistas:
            rechazadas.append(
                {"asistencia_id": asistencia_id, "regla": "DUPLICADO_RUT_FECHA", "severidad": "ERROR"}
            )
            continue
        claves_vistas.add(clave)

        fecha_key = dimensiones["fechas"].get(fecha)
        if fecha_key is None:
            rechazadas.append(
                {"asistencia_id": asistencia_id, "regla": "FECHA_NO_RESUELTA", "severidad": "ERROR"}
            )
            continue

        versiones = dimensiones["empleados"].get(rut, [])
        historicos = [
            empleado
            for empleado in versiones
            if empleado["fecha_desde"] <= fecha
            and (empleado["fecha_hasta"] is None or fecha < empleado["fecha_hasta"])
        ]
        if not historicos:
            review.append(
                {"asistencia_id": asistencia_id, "regla": "EMPLEADO_NO_RESUELTO", "severidad": "REVIEW"}
            )
            continue
        if len(historicos) > 1:
            rechazadas.append(
                {"asistencia_id": asistencia_id, "regla": "SCD2_AMBIGUO", "severidad": "ERROR"}
            )
            continue

        turno_bk = dimensiones["turnos_origen"].get(row.get("turno_id"))
        turno_key = dimensiones["turnos_dw"].get(turno_bk)
        if turno_key is None:
            review.append(
                {"asistencia_id": asistencia_id, "regla": "TURNO_NO_RESUELTO", "severidad": "REVIEW"}
            )
            continue

        empleado = historicos[0]
        resueltas.append(
            {
                **row,
                "rut_normalizado": rut,
                "fecha_key": fecha_key,
                "empleado_key": empleado["empleado_key"],
                "area_key": empleado["area_key"],
                "cargo_key": empleado["cargo_key"],
                "centro_costo_key": empleado["centro_costo_key"],
                "turno_key": turno_key,
            }
        )

    return resueltas, rechazadas, review


def build_fact_rows(rows: list[dict]) -> list[dict]:
    result = []
    for row in rows:
        estado = str(row["estado"]).strip().upper()
        result.append(
            {
                "fecha_key": row["fecha_key"],
                "empleado_key": row["empleado_key"],
                "area_key": row["area_key"],
                "cargo_key": row["cargo_key"],
                "centro_costo_key": row["centro_costo_key"],
                "turno_key": row["turno_key"],
                "hora_entrada": _to_time(row["hora_entrada"]),
                "hora_salida": _to_time(row["hora_salida"]),
                "estado_asistencia": estado,
                "horas_trabajadas": Decimal(str(row["horas_trabajadas"])),
                "horas_normales": Decimal(str(row["horas_normales"])),
                "horas_extras": Decimal(str(row["horas_extras"])),
                "minutos_atraso": int(row["atraso_minutos"]),
                "dias_trabajados": 1 if estado in {"PRESENTE", "ATRASO"} else 0,
                "dias_ausentes": 1 if estado == "AUSENTE" else 0,
                "cantidad_registros": 1,
            }
        )
    return result


def _fact_signature(row: dict | tuple) -> tuple:
    if isinstance(row, dict):
        values = [row[column] for column in FACT_COLUMNS]
    else:
        values = list(row)
    for index in (7, 8, 9):
        values[index] = Decimal(str(values[index]))
    return tuple(values)


def load_fact_asistencia(rows: list[dict]) -> dict:
    """UPSERT idempotente con métricas inserted/updated/unchanged."""
    if not rows:
        return {"inserted": 0, "updated": 0, "unchanged": 0}

    sql = (SQL_DIR / "cargar_fact_asistencia.sql").read_text(encoding="utf-8")
    config = get_dw_db_config()
    stats = {"inserted": 0, "updated": 0, "unchanged": 0}

    with get_postgres_connection(config) as connection:
        with connection.cursor() as cursor:
            for row in rows:
                cursor.execute(
                    """
                    SELECT area_key, cargo_key, centro_costo_key, turno_key,
                           hora_entrada, hora_salida, estado_asistencia,
                           horas_trabajadas, horas_normales, horas_extras,
                           minutos_atraso, dias_trabajados, dias_ausentes,
                           cantidad_registros
                    FROM dw.fact_asistencia
                    WHERE empleado_key = %s AND fecha_key = %s;
                    """,
                    (row["empleado_key"], row["fecha_key"]),
                )
                existing = cursor.fetchone()

                if existing is None:
                    stats["inserted"] += 1
                    cursor.execute(sql, row)
                elif _fact_signature(existing) == _fact_signature(row):
                    stats["unchanged"] += 1
                else:
                    stats["updated"] += 1
                    cursor.execute(sql, row)

        connection.commit()

    return stats


def run_dw_asistencia_load() -> dict:
    source = extract_asistencia_clean()
    turno_stats = load_dim_turno(source["turnos"])
    dimensiones = cargar_dimensiones(source["turnos"])
    resueltas, rechazadas_dw, review = resolve_asistencia_dimension_keys(
        source["validas"], source["trabajadores"], dimensiones
    )
    fact_rows = build_fact_rows(resueltas)
    fact_stats = load_fact_asistencia(fact_rows)

    rechazadas = list(source["rechazadas"]) + rechazadas_dw
    rejected_ids = {item.get("asistencia_id") for item in rechazadas}

    return {
        "records_read": len(source["asistencias"]),
        "records_valid": len(source["asistencias"]) - len(rejected_ids),
        "records_rejected": len(rejected_ids),
        "records_review": len(review),
        "records_inserted": turno_stats["inserted"] + fact_stats["inserted"],
        "records_updated": turno_stats["updated"] + fact_stats["updated"],
        "records_unchanged": turno_stats["unchanged"] + fact_stats["unchanged"],
        "source": {
            "trabajadores": len(source["trabajadores"]),
            "turnos": len(source["turnos"]),
            "asistencias": len(source["asistencias"]),
            "validas_etl_fuente": len(source["validas"]),
        },
        "dim_turno": turno_stats,
        "fact_asistencia": fact_stats,
        "resolved": len(resueltas),
        "rejected": rechazadas,
        "review": review,
    }


# Compatibilidad con el nombre usado en la primera entrega de Esteban.
def run_fact_asistencia() -> dict:
    return run_dw_asistencia_load()
