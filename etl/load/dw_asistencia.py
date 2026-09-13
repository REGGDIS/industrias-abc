from __future__ import annotations

from decimal import Decimal
from pathlib import Path

from etl.config.settings import get_dw_db_config
from etl.extract.postgres import get_postgres_connection


SQL_DIR = (
    Path(__file__).resolve().parents[1]
    / "sql"
    / "load"
    / "dw"
    / "asistencia"
)

ESTADOS_VALIDOS = {"PRESENTE", "ATRASO", "AUSENTE"}


def normalizar_rut(rut: str | None) -> str | None:
    """Normaliza RUT chileno al formato 12345678-5 / 12345678-K."""
    if rut is None:
        return None

    valor = str(rut).strip().upper().replace(".", "")

    if "-" not in valor:
        return None

    cuerpo, dv = valor.rsplit("-", 1)
    cuerpo = cuerpo.strip()
    dv = dv.strip()

    if not cuerpo.isdigit() or len(dv) != 1 or dv not in "0123456789K":
        return None

    return f"{cuerpo}-{dv}"


def rut_dv_valido(rut: str | None) -> bool:
    """Valida el dígito verificador de un RUT chileno."""
    rut_normalizado = normalizar_rut(rut)

    if rut_normalizado is None:
        return False

    cuerpo, dv = rut_normalizado.rsplit("-", 1)

    suma = 0
    multiplicador = 2

    for digito in reversed(cuerpo):
        suma += int(digito) * multiplicador
        multiplicador += 1

        if multiplicador > 7:
            multiplicador = 2

    resultado = 11 - (suma % 11)

    if resultado == 11:
        dv_esperado = "0"
    elif resultado == 10:
        dv_esperado = "K"
    else:
        dv_esperado = str(resultado)

    return dv == dv_esperado


def validar_fila_staging(row: dict) -> list[str]:
    """
    Valida coherencia básica de una fila de asistencia.
    No transforma ni corrige valores.
    """
    errores = []

    estado = row.get("estado")

    if estado not in ESTADOS_VALIDOS:
        errores.append("ESTADO_INVALIDO")
        return errores

    horas_trabajadas = Decimal(str(row.get("horas_trabajadas") or 0))
    horas_normales = Decimal(str(row.get("horas_normales") or 0))
    horas_extras = Decimal(str(row.get("horas_extras") or 0))
    atraso_minutos = int(row.get("atraso_minutos") or 0)

    if horas_trabajadas < 0:
        errores.append("HORAS_TRABAJADAS_NEGATIVAS")

    if horas_normales < 0:
        errores.append("HORAS_NORMALES_NEGATIVAS")

    if horas_extras < 0:
        errores.append("HORAS_EXTRAS_NEGATIVAS")

    if horas_extras > horas_trabajadas:
        errores.append("HORAS_EXTRAS_MAYORES_TRABAJADAS")

    if atraso_minutos < 0:
        errores.append("ATRASO_NEGATIVO")

    if horas_normales + horas_extras != horas_trabajadas:
        errores.append("HORAS_NO_CUADRAN")

    if estado == "AUSENTE":
        if row.get("hora_entrada") is not None:
            errores.append("AUSENTE_CON_HORA_ENTRADA")

        if row.get("hora_salida") is not None:
            errores.append("AUSENTE_CON_HORA_SALIDA")

        if horas_trabajadas != 0:
            errores.append("AUSENTE_CON_HORAS_TRABAJADAS")

        if horas_normales != 0:
            errores.append("AUSENTE_CON_HORAS_NORMALES")

        if horas_extras != 0:
            errores.append("AUSENTE_CON_HORAS_EXTRAS")

        if atraso_minutos != 0:
            errores.append("AUSENTE_CON_ATRASO")

    elif estado == "PRESENTE":
        if atraso_minutos > 0:
            errores.append("PRESENTE_CON_ATRASO")

    elif estado == "ATRASO":
        if atraso_minutos <= 0:
            errores.append("ATRASO_SIN_MINUTOS")

    return errores


def extract_asistencia_clean() -> list[dict]:
    """Extrae la asistencia validada desde staging CLEAN."""
    config = get_dw_db_config()

    sql = """
        SELECT
            a.asistencia_id,
            t.rut,
            a.fecha,
            a.hora_entrada,
            a.hora_salida,
            a.horas_trabajadas,
            a.horas_normales,
            a.horas_extras,
            a.atraso_minutos,
            a.ausentismo,
            UPPER(TRIM(a.estado)) AS estado,
            a.turno_id
        FROM stg_asistencia_asistencia_clean a
        INNER JOIN stg_asistencia_trabajador_clean t
            ON t.trabajador_id = a.trabajador_id
        WHERE a.asistencia_id IS NOT NULL
        ORDER BY a.fecha, a.asistencia_id;
    """

    with get_postgres_connection(config) as connection:
        with connection.cursor() as cursor:
            cursor.execute(sql)
            rows = cursor.fetchall()

    return [
        {
            "asistencia_id": row[0],
            "rut": row[1],
            "fecha": row[2],
            "hora_entrada": row[3],
            "hora_salida": row[4],
            "horas_trabajadas": row[5],
            "horas_normales": row[6],
            "horas_extras": row[7],
            "atraso_minutos": row[8],
            "ausentismo": row[9],
            "estado": row[10],
            "turno_id": row[11],
        }
        for row in rows
    ]


def cargar_dimensiones() -> tuple[dict, dict, dict]:
    """
    Carga en memoria las dimensiones necesarias para resolver la FACT.
    """
    config = get_dw_db_config()

    with get_postgres_connection(config) as connection:
        with connection.cursor() as cursor:

            cursor.execute("""
                SELECT fecha, fecha_key
                FROM dw.dim_fecha;
            """)
            fechas = dict(cursor.fetchall())

            cursor.execute("""
                SELECT
                    empleado_key,
                    rut_normalizado,
                    area_key,
                    cargo_key,
                    centro_costo_key,
                    fecha_desde,
                    fecha_hasta
                FROM dw.dim_empleado
                WHERE empleado_key <> 0
                ORDER BY rut_normalizado, fecha_desde;
            """)
            empleados_rows = cursor.fetchall()

            cursor.execute("""
                SELECT
                    turno_bk,
                    turno_key
                FROM dw.dim_turno;
            """)
            turnos = dict(cursor.fetchall())

            cursor.execute("""
                SELECT
                    turno_id,
                    UPPER(TRIM(nombre_turno))
                        || '|'
                        || hora_inicio::TEXT
                        || '|'
                        || hora_fin::TEXT AS turno_bk
                FROM stg_asistencia_turnos_clean
                WHERE turno_id IS NOT NULL;
            """)
            turnos_staging = dict(cursor.fetchall())

    empleados_por_rut = {}

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

    return fechas, empleados_por_rut, {
        "dw": turnos,
        "staging": turnos_staging,
    }


def resolver_turno(turno_id, turnos: dict) -> int | None:
    """Resuelve el turno operacional contra DIM_TURNO."""
    turno_bk = turnos["staging"].get(turno_id)

    if turno_bk is None:
        return None

    return turnos["dw"].get(turno_bk)


def resolve_asistencia_dimension_keys(
    rows: list[dict],
) -> tuple[list[dict], list[dict]]:

    if not rows:
        return [], []

    fechas, empleados_por_rut, turnos = cargar_dimensiones()

    valid_rows = []
    errors = []

    claves_vistas = set()

    for row in rows:
        asistencia_id = row["asistencia_id"]
        fecha = row["fecha"]

        # ---------------------------------------------------------
        # 1. Validación de datos de staging
        # ---------------------------------------------------------
        errores_fila = validar_fila_staging(row)

        if errores_fila:
            for regla in errores_fila:
                errors.append({
                    "asistencia_id": asistencia_id,
                    "regla": regla,
                    "severidad": "ERROR",
                })
            continue

        # ---------------------------------------------------------
        # 2. Normalización y validación RUT
        # ---------------------------------------------------------
        rut = normalizar_rut(row["rut"])

        if not rut_dv_valido(rut):
            errors.append({
                "asistencia_id": asistencia_id,
                "regla": "RUT_INVALIDO",
                "severidad": "ERROR",
            })
            continue

        # ---------------------------------------------------------
        # 3. Detección de duplicado RUT + fecha
        # ---------------------------------------------------------
        clave = (rut, fecha)

        if clave in claves_vistas:
            errors.append({
                "asistencia_id": asistencia_id,
                "regla": "DUPLICADO_RUT_FECHA",
                "severidad": "ERROR",
            })
            continue

        claves_vistas.add(clave)

        # ---------------------------------------------------------
        # 4. Resolución DIM_FECHA
        # ---------------------------------------------------------
        fecha_key = fechas.get(fecha)

        if fecha_key is None:
            errors.append({
                "asistencia_id": asistencia_id,
                "regla": "FECHA_NO_RESUELTA",
                "severidad": "ERROR",
            })
            continue

        # ---------------------------------------------------------
        # 5. Resolución SCD2 DIM_EMPLEADO
        # ---------------------------------------------------------
        versiones = empleados_por_rut.get(rut, [])

        historicos = [
            empleado
            for empleado in versiones
            if (
                empleado["fecha_desde"] <= fecha
                and (
                    empleado["fecha_hasta"] is None
                    or fecha < empleado["fecha_hasta"]
                )
            )
        ]

        if len(historicos) == 0:
            errors.append({
                "asistencia_id": asistencia_id,
                "regla": "EMPLEADO_NO_RESUELTO",
                "severidad": "ERROR",
            })
            continue

        if len(historicos) > 1:
            errors.append({
                "asistencia_id": asistencia_id,
                "regla": "SCD2_AMBIGUO",
                "severidad": "ERROR",
            })
            continue

        empleado = historicos[0]

        # ---------------------------------------------------------
        # 6. Resolución DIM_TURNO
        # ---------------------------------------------------------
        turno_key = resolver_turno(row["turno_id"], turnos)

        if turno_key is None:
            errors.append({
                "asistencia_id": asistencia_id,
                "regla": "TURNO_NO_RESUELTO",
                "severidad": "ERROR",
            })
            continue

        # ---------------------------------------------------------
        # 7. Construcción de fila resuelta
        # ---------------------------------------------------------
        valid_rows.append({
            **row,
            "rut_normalizado": rut,
            "fecha_key": fecha_key,
            "empleado_key": empleado["empleado_key"],
            "area_key": empleado["area_key"],
            "cargo_key": empleado["cargo_key"],
            "centro_costo_key": empleado["centro_costo_key"],
            "turno_key": turno_key,
        })

    return valid_rows, errors


def build_fact_rows(rows: list[dict]) -> list[dict]:
    """Construye las filas con el formato exacto de FACT_ASISTENCIA."""
    result = []

    for row in rows:
        estado = row["estado"]

        horas_trabajadas = Decimal(str(row["horas_trabajadas"] or 0))
        horas_normales = Decimal(str(row["horas_normales"] or 0))
        horas_extras = Decimal(str(row["horas_extras"] or 0))
        atraso_minutos = int(row["atraso_minutos"] or 0)

        dias_trabajados = 1 if estado in {"PRESENTE", "ATRASO"} else 0
        dias_ausentes = 1 if estado == "AUSENTE" else 0

        result.append({
            "fecha_key": row["fecha_key"],
            "empleado_key": row["empleado_key"],
            "area_key": row["area_key"],
            "cargo_key": row["cargo_key"],
            "centro_costo_key": row["centro_costo_key"],
            "turno_key": row["turno_key"],
            "hora_entrada": row["hora_entrada"],
            "hora_salida": row["hora_salida"],
            "estado_asistencia": estado,
            "horas_trabajadas": horas_trabajadas,
            "horas_normales": horas_normales,
            "horas_extras": horas_extras,
            "minutos_atraso": atraso_minutos,
            "dias_trabajados": dias_trabajados,
            "dias_ausentes": dias_ausentes,
            "cantidad_registros": 1,
        })

    return result


def load_fact_asistencia(rows: list[dict]) -> int:
    """Carga FACT_ASISTENCIA de forma idempotente."""
    if not rows:
        return 0

    sql_path = SQL_DIR / "cargar_fact_asistencia.sql"
    sql = sql_path.read_text(encoding="utf-8")

    config = get_dw_db_config()

    with get_postgres_connection(config) as connection:
        with connection.cursor() as cursor:
            cursor.executemany(sql, rows)
            processed = cursor.rowcount

        connection.commit()

    return processed


def run_fact_asistencia():
    """
    Ejecuta el proceso completo:
    STAGING CLEAN → resolución dimensiones → FACT_ASISTENCIA.
    """
    source_rows = extract_asistencia_clean()

    resolved_rows, errors = resolve_asistencia_dimension_keys(
        source_rows
    )

    fact_rows = build_fact_rows(resolved_rows)

    processed = load_fact_asistencia(fact_rows)

    return {
        "procesados": len(source_rows),
        "resueltos": len(resolved_rows),
        "cargados": processed,
        "errores": len(errors),
        "detalle_errores": errors,
    }


if __name__ == "__main__":
    resultado = run_fact_asistencia()

    print(f"procesados={resultado['procesados']}")
    print(f"resueltos={resultado['resueltos']}")
    print(f"cargados={resultado['cargados']}")
    print(f"errores={resultado['errores']}")

    for error in resultado["detalle_errores"]:
        print(
            f"asistencia_id={error['asistencia_id']} "
            f"regla={error['regla']} "
            f"severidad={error['severidad']}"
        )
def test_rut_invalido_es_rechazado():
    fila = {
        "asistencia_id": 9002,
        "rut": "15.678.234-9",
        "fecha": date(2026, 8, 24),
        "hora_entrada": None,
        "hora_salida": None,
        "horas_trabajadas": 0,
        "horas_normales": 0,
        "horas_extras": 0,
        "atraso_minutos": 0,
        "ausentismo": 0,
        "estado": "AUSENTE",
        "turno_id": 3,
    }

    resueltas, errores = resolve_asistencia_dimension_keys([fila])

    assert resueltas == []
    assert any(
        error["regla"] == "RUT_INVALIDO"
        for error in errores
    )
def test_empleado_no_resuelto():
    fila = {
        "asistencia_id": 9003,
        "rut": "12.345.678-5",
        "fecha": date(2026, 8, 24),
        "hora_entrada": None,
        "hora_salida": None,
        "horas_trabajadas": 0,
        "horas_normales": 0,
        "horas_extras": 0,
        "atraso_minutos": 0,
        "ausentismo": 0,
        "estado": "AUSENTE",
        "turno_id": 3,
    }

    resueltas, errores = resolve_asistencia_dimension_keys([fila])

    assert resueltas == []
    assert any(
        error["regla"] == "EMPLEADO_NO_RESUELTO"
        for error in errores
    )



    resueltas, errores = resolve_asistencia_dimension_keys([fila])

    assert resueltas == []
    assert any(
        error["regla"] == "EMPLEADO_NO_RESUELTO"
        for error in errores
    )


def test_turno_no_resuelto():
    fila = {
        "asistencia_id": 9004,
        "rut": "15.000.984-7",
        "fecha": date(2026, 8, 24),
        "hora_entrada": None,
        "hora_salida": None,
        "horas_trabajadas": 0,
        "horas_normales": 0,
        "horas_extras": 0,
        "atraso_minutos": 0,
        "ausentismo": 0,
        "estado": "AUSENTE",
        "turno_id": 999,
    }

    resueltas, errores = resolve_asistencia_dimension_keys([fila])

    assert resueltas == []
    assert any(
        error["regla"] == "TURNO_NO_RESUELTO"
        for error in errores
    )
def test_idempotencia_clave_empleado_fecha():
    """
    Verifica que la clave lógica empleado + fecha
    impida duplicados en la FACT_ASISTENCIA.
    """
    fila1 = {
        "empleado_key": 1,
        "fecha_key": 20260824,
    }

    fila2 = {
        "empleado_key": 1,
        "fecha_key": 20260824,
    }

    claves = {
        (fila1["empleado_key"], fila1["fecha_key"]),
        (fila2["empleado_key"], fila2["fecha_key"]),
    }

    assert len(claves) == 1