from datetime import date
from pathlib import Path

from etl.config.settings import (
    get_dw_db_config,
    get_rrhh_db_config,
)
from etl.extract.postgres import get_postgres_connection


SQL_DIR = Path(__file__).resolve().parents[1] / "sql" / "load" / "dw" / "rrhh"


def extract_centros_costo_clean() -> list[dict]:
    config = get_rrhh_db_config()

    sql = """
        SELECT
            codigo_centro_costo,
            nombre_centro_costo
        FROM stg_rrhh_centros_costo_clean
        ORDER BY codigo_centro_costo;
    """

    with get_postgres_connection(config) as connection:
        with connection.cursor() as cursor:
            cursor.execute(sql)
            rows = cursor.fetchall()

    return [
        {
            "codigo_centro_costo": row[0],
            "nombre_centro_costo": row[1],
        }
        for row in rows
    ]


def load_dim_centro_costo(rows: list[dict]) -> int:
    if not rows:
        return 0

    sql_path = SQL_DIR / "cargar_dim_centro_costo.sql"
    sql = sql_path.read_text(encoding="utf-8")

    config = get_dw_db_config()

    with get_postgres_connection(config) as connection:
        with connection.cursor() as cursor:
            cursor.executemany(sql, rows)

        connection.commit()

    return len(rows)


def run_dim_centro_costo() -> dict:
    rows = extract_centros_costo_clean()
    loaded = load_dim_centro_costo(rows)

    return {
        "source_rows": len(rows),
        "processed_rows": loaded,
    }


def extract_areas_clean() -> list[dict]:
    config = get_rrhh_db_config()

    sql = """
        SELECT
            codigo_area,
            nombre_area,
            gerencia
        FROM stg_rrhh_areas_clean
        ORDER BY codigo_area;
    """

    with get_postgres_connection(config) as connection:
        with connection.cursor() as cursor:
            cursor.execute(sql)
            rows = cursor.fetchall()

    return [
        {
            "codigo_area": row[0],
            "nombre_area": row[1],
            "gerencia": row[2],
        }
        for row in rows
    ]


def load_dim_area(rows: list[dict]) -> int:
    if not rows:
        return 0

    sql_path = SQL_DIR / "cargar_dim_area.sql"
    sql = sql_path.read_text(encoding="utf-8")

    config = get_dw_db_config()

    with get_postgres_connection(config) as connection:
        with connection.cursor() as cursor:
            cursor.executemany(sql, rows)

        connection.commit()

    return len(rows)


def run_dim_area() -> dict:
    rows = extract_areas_clean()
    loaded = load_dim_area(rows)

    return {
        "source_rows": len(rows),
        "processed_rows": loaded,
    }


def extract_cargos_clean() -> list[dict]:
    config = get_rrhh_db_config()

    sql = """
        SELECT
            codigo_cargo,
            nombre_cargo,
            nivel,
            sueldo_base_referencial
        FROM stg_rrhh_cargos_clean
        ORDER BY codigo_cargo;
    """

    with get_postgres_connection(config) as connection:
        with connection.cursor() as cursor:
            cursor.execute(sql)
            rows = cursor.fetchall()

    return [
        {
            "codigo_cargo": row[0],
            "nombre_cargo": row[1],
            "nivel": row[2],
            "sueldo_base_referencial": row[3],
        }
        for row in rows
    ]


def load_dim_cargo(rows: list[dict]) -> int:
    if not rows:
        return 0

    sql_path = SQL_DIR / "cargar_dim_cargo.sql"
    sql = sql_path.read_text(encoding="utf-8")

    config = get_dw_db_config()

    with get_postgres_connection(config) as connection:
        with connection.cursor() as cursor:
            cursor.executemany(sql, rows)

        connection.commit()

    return len(rows)


def run_dim_cargo() -> dict:
    rows = extract_cargos_clean()
    loaded = load_dim_cargo(rows)

    return {
        "source_rows": len(rows),
        "processed_rows": loaded,
    }


def rut_dv_valido(rut: str | None) -> bool:
    if rut is None:
        return False

    rut = rut.strip().upper()

    if "-" not in rut:
        return False

    cuerpo, dv = rut.rsplit("-", 1)

    if len(cuerpo) not in {7, 8}:
        return False

    if not cuerpo.isdigit():
        return False

    if len(dv) != 1 or dv not in "0123456789K":
        return False

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


def extract_empleados_clean() -> list[dict]:
    config = get_rrhh_db_config()

    sql = """
        SELECT
            e.rut,
            e.nombres,
            e.apellido_paterno,
            e.apellido_materno,
            e.fecha_nacimiento,
            e.fecha_ingreso,
            e.fecha_salida,
            a.codigo_area,
            c.codigo_cargo,
            cc.codigo_centro_costo,
            e.estado,
            e.sexo,
            e.nacionalidad
        FROM stg_rrhh_empleados_clean e
        LEFT JOIN stg_rrhh_areas_clean a
            ON a.area_id = e.area_id
        LEFT JOIN stg_rrhh_cargos_clean c
            ON c.cargo_id = e.cargo_id
        LEFT JOIN stg_rrhh_centros_costo_clean cc
            ON cc.centro_costo_id = a.centro_costo_id
        ORDER BY e.rut;
    """

    with get_postgres_connection(config) as connection:
        with connection.cursor() as cursor:
            cursor.execute(sql)
            rows = cursor.fetchall()

    return [
        {
            "rut_normalizado": row[0],
            "nombres": row[1],
            "apellido_paterno": row[2],
            "apellido_materno": row[3],
            "fecha_nacimiento": row[4],
            "fecha_ingreso": row[5],
            "fecha_salida": row[6],
            "codigo_area": row[7],
            "codigo_cargo": row[8],
            "codigo_centro_costo": row[9],
            "estado_laboral": row[10],
            "sexo": row[11],
            "nacionalidad": row[12],
        }
        for row in rows
    ]


def resolve_empleados_dimension_keys(rows: list[dict]) -> list[dict]:
    if not rows:
        return []

    config = get_dw_db_config()

    with get_postgres_connection(config) as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                """
                SELECT codigo_area, area_key
                FROM dw.dim_area;
                """
            )
            areas = dict(cursor.fetchall())

            cursor.execute(
                """
                SELECT codigo_cargo, cargo_key
                FROM dw.dim_cargo;
                """
            )
            cargos = dict(cursor.fetchall())

            cursor.execute(
                """
                SELECT codigo_centro_costo, centro_costo_key
                FROM dw.dim_centro_costo;
                """
            )
            centros_costo = dict(cursor.fetchall())

    resolved = []

    for row in rows:
        rut = row["rut_normalizado"]

        if not rut_dv_valido(rut):
            raise ValueError(
                f"RUT inválido para carga DIM_EMPLEADO: {rut}"
            )

        codigo_area = row["codigo_area"]
        codigo_cargo = row["codigo_cargo"]
        codigo_centro_costo = row["codigo_centro_costo"]

        if codigo_area not in areas:
            raise ValueError(
                f"Área no resuelta para {rut}: {codigo_area}"
            )

        if codigo_cargo not in cargos:
            raise ValueError(
                f"Cargo no resuelto para {rut}: {codigo_cargo}"
            )

        if codigo_centro_costo not in centros_costo:
            raise ValueError(
                "Centro de costo no resuelto para "
                f"{rut}: {codigo_centro_costo}"
            )

        resolved.append(
            {
                **row,
                "area_key": areas[codigo_area],
                "cargo_key": cargos[codigo_cargo],
                "centro_costo_key": centros_costo[
                    codigo_centro_costo
                ],
            }
        )

    return resolved


def build_initial_empleado_versions(
    rows: list[dict],
    fecha_observacion: date,
) -> list[dict]:
    versions = []

    for row in rows:
        rut = row["rut_normalizado"]
        fecha_ingreso = row["fecha_ingreso"]
        fecha_salida = row["fecha_salida"]
        estado = row["estado_laboral"]

        if fecha_ingreso is None:
            raise ValueError(
                f"Empleado sin fecha_ingreso: {rut}"
            )

        if fecha_ingreso > fecha_observacion:
            raise ValueError(
                f"fecha_ingreso posterior a fecha_observacion para {rut}"
            )

        if fecha_salida is not None and fecha_salida < fecha_ingreso:
            raise ValueError(
                f"fecha_salida anterior a fecha_ingreso para {rut}"
            )

        if fecha_salida is not None and fecha_salida > fecha_observacion:
            raise ValueError(
                f"fecha_salida posterior a fecha_observacion para {rut}"
            )

        base = {
            "rut_normalizado": rut,
            "nombres": row["nombres"],
            "apellido_paterno": row["apellido_paterno"],
            "apellido_materno": row["apellido_materno"],
            "fecha_nacimiento": row["fecha_nacimiento"],
            "fecha_ingreso": fecha_ingreso,
            "fecha_salida": fecha_salida,
            "area_key": row["area_key"],
            "cargo_key": row["cargo_key"],
            "centro_costo_key": row["centro_costo_key"],
            "sexo": row["sexo"],
            "nacionalidad": row["nacionalidad"],
        }

        if estado == "ACTIVO":
            # Contexto anterior a la primera observación:
            # se conserva para resolución histórica, pero se marca estimado.
            if fecha_ingreso < fecha_observacion:
                versions.append(
                    {
                        **base,
                        "estado_laboral": "ACTIVO",
                        "fecha_desde": fecha_ingreso,
                        "fecha_hasta": fecha_observacion,
                        "es_actual": False,
                        "contexto_historico_estimado": True,
                    }
                )

            # Primera versión efectivamente observada por el DW.
            versions.append(
                {
                    **base,
                    "estado_laboral": "ACTIVO",
                    "fecha_desde": fecha_observacion,
                    "fecha_hasta": None,
                    "es_actual": True,
                    "contexto_historico_estimado": False,
                }
            )

        elif estado == "INACTIVO":
            if fecha_salida is None:
                raise ValueError(
                    f"Empleado INACTIVO sin fecha_salida: {rut}"
                )

            # Período laboral previo a la salida.
            if fecha_ingreso < fecha_salida:
                versions.append(
                    {
                        **base,
                        "estado_laboral": "ACTIVO",
                        "fecha_desde": fecha_ingreso,
                        "fecha_hasta": fecha_salida,
                        "es_actual": False,
                        "contexto_historico_estimado": True,
                    }
                )

            # Estado inactivo anterior a la primera observación.
            if fecha_salida < fecha_observacion:
                versions.append(
                    {
                        **base,
                        "estado_laboral": "INACTIVO",
                        "fecha_desde": fecha_salida,
                        "fecha_hasta": fecha_observacion,
                        "es_actual": False,
                        "contexto_historico_estimado": True,
                    }
                )

            # Estado realmente observado por el DW.
            versions.append(
                {
                    **base,
                    "estado_laboral": "INACTIVO",
                    "fecha_desde": fecha_observacion,
                    "fecha_hasta": None,
                    "es_actual": True,
                    "contexto_historico_estimado": False,
                }
            )

        else:
            raise ValueError(
                f"Estado laboral no soportado para {rut}: {estado}"
            )

    return versions


def validate_empleado_versions_no_overlap(rows: list[dict]) -> None:
    grouped: dict[str, list[dict]] = {}

    for row in rows:
        grouped.setdefault(
            row["rut_normalizado"],
            [],
        ).append(row)

    for rut, versions in grouped.items():
        ordered = sorted(
            versions,
            key=lambda row: row["fecha_desde"],
        )

        actuales = [
            row
            for row in ordered
            if row["es_actual"]
        ]

        if len(actuales) != 1:
            raise ValueError(
                f"RUT {rut} debe tener exactamente una versión actual"
            )

        for previous, current in zip(
            ordered,
            ordered[1:],
        ):
            previous_until = previous["fecha_hasta"]

            if previous_until is None:
                raise ValueError(
                    f"Versión abierta no final para RUT {rut}"
                )

            if current["fecha_desde"] < previous_until:
                raise ValueError(
                    f"Solapamiento SCD2 detectado para RUT {rut}: "
                    f"{current['fecha_desde']} < {previous_until}"
                )


def validate_empleado_versions_against_dw(rows: list[dict]) -> None:
    if not rows:
        return

    config = get_dw_db_config()

    ruts = sorted(
        {
            row["rut_normalizado"]
            for row in rows
        }
    )

    with get_postgres_connection(config) as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                """
                SELECT
                    rut_normalizado,
                    fecha_desde,
                    fecha_hasta
                FROM dw.dim_empleado
                WHERE empleado_key <> 0
                  AND rut_normalizado = ANY(%s)
                ORDER BY rut_normalizado, fecha_desde;
                """,
                (ruts,),
            )
            existing = cursor.fetchall()

    generated_keys = {
        (
            row["rut_normalizado"],
            row["fecha_desde"],
        )
        for row in rows
    }

    for rut, fecha_desde, fecha_hasta in existing:
        if (rut, fecha_desde) in generated_keys:
            continue

        for row in rows:
            if row["rut_normalizado"] != rut:
                continue

            new_from = row["fecha_desde"]
            new_until = row["fecha_hasta"]

            existing_until = fecha_hasta or date.max
            candidate_until = new_until or date.max

            if (
                fecha_desde < candidate_until
                and new_from < existing_until
            ):
                raise ValueError(
                    "Solapamiento con versión existente en DW "
                    f"para RUT {rut}: "
                    f"[{fecha_desde}, {fecha_hasta})"
                )


def load_dim_empleado(rows: list[dict]) -> int:
    if not rows:
        return 0

    validate_empleado_versions_no_overlap(rows)
    validate_empleado_versions_against_dw(rows)

    sql_path = SQL_DIR / "cargar_dim_empleado.sql"
    sql = sql_path.read_text(encoding="utf-8")

    config = get_dw_db_config()

    with get_postgres_connection(config) as connection:
        with connection.cursor() as cursor:
            cursor.executemany(sql, rows)

        connection.commit()

    return len(rows)


def run_dim_empleado(
    fecha_observacion: date,
) -> dict:
    source_rows = extract_empleados_clean()

    resolved_rows = resolve_empleados_dimension_keys(
        source_rows
    )

    versions = build_initial_empleado_versions(
        resolved_rows,
        fecha_observacion,
    )

    validate_empleado_versions_no_overlap(
        versions
    )

    processed = load_dim_empleado(
        versions
    )

    return {
        "source_rows": len(source_rows),
        "versions_generated": len(versions),
        "processed_rows": processed,
    }
