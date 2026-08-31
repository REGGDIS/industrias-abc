from pathlib import Path

from etl.config.settings import get_rrhh_db_config
from etl.extract.postgres import get_postgres_connection


SQL_DIR = Path(__file__).resolve().parents[1] / "sql" / "staging" / "rrhh"


def create_empleados_raw_table():
    sql_path = SQL_DIR / "create_empleados_raw.sql"
    sql = sql_path.read_text(encoding="utf-8")

    config = get_rrhh_db_config()

    with get_postgres_connection(config) as connection:
        with connection.cursor() as cursor:
            cursor.execute(sql)

        connection.commit()


def load_empleados_raw(rows: list[dict]):
    config = get_rrhh_db_config()

    insert_sql = """
        INSERT INTO stg_rrhh_empleados_raw (
            empleado_id,
            rut,
            nombres,
            apellido_paterno,
            apellido_materno,
            fecha_nacimiento,
            sexo,
            nacionalidad,
            fecha_ingreso,
            fecha_salida,
            area_id,
            cargo_id,
            estado
        )
        VALUES (
            %(empleado_id)s,
            %(rut)s,
            %(nombres)s,
            %(apellido_paterno)s,
            %(apellido_materno)s,
            %(fecha_nacimiento)s,
            %(sexo)s,
            %(nacionalidad)s,
            %(fecha_ingreso)s,
            %(fecha_salida)s,
            %(area_id)s,
            %(cargo_id)s,
            %(estado)s
        );
    """

    with get_postgres_connection(config) as connection:
        with connection.cursor() as cursor:
            cursor.executemany(insert_sql, rows)

        connection.commit()

    return len(rows)


def create_empleados_clean_table():
    sql_path = SQL_DIR / "limpiar_empleados.sql"
    select_sql = sql_path.read_text(encoding="utf-8").strip().rstrip(";")

    sql = f"""
        DROP TABLE IF EXISTS stg_rrhh_empleados_clean;

        CREATE TABLE stg_rrhh_empleados_clean AS
        {select_sql};
    """

    config = get_rrhh_db_config()

    with get_postgres_connection(config) as connection:
        with connection.cursor() as cursor:
            cursor.execute(sql)

        connection.commit()


def _execute_staging_sql(filename: str):
    sql_path = SQL_DIR / filename
    sql = sql_path.read_text(encoding="utf-8")

    config = get_rrhh_db_config()

    with get_postgres_connection(config) as connection:
        with connection.cursor() as cursor:
            cursor.execute(sql)

        connection.commit()


def create_areas_raw_table():
    _execute_staging_sql("create_areas_raw.sql")


def create_cargos_raw_table():
    _execute_staging_sql("create_cargos_raw.sql")


def create_centros_costo_raw_table():
    _execute_staging_sql("create_centros_costo_raw.sql")


def load_areas_raw(rows: list[dict]):
    config = get_rrhh_db_config()

    insert_sql = """
        INSERT INTO stg_rrhh_areas_raw (
            area_id,
            codigo_area,
            nombre_area,
            gerencia,
            centro_costo_id
        )
        VALUES (
            %(area_id)s,
            %(codigo_area)s,
            %(nombre_area)s,
            %(gerencia)s,
            %(centro_costo_id)s
        );
    """

    with get_postgres_connection(config) as connection:
        with connection.cursor() as cursor:
            cursor.executemany(insert_sql, rows)

        connection.commit()

    return len(rows)


def load_cargos_raw(rows: list[dict]):
    config = get_rrhh_db_config()

    insert_sql = """
        INSERT INTO stg_rrhh_cargos_raw (
            cargo_id,
            codigo_cargo,
            nombre_cargo,
            nivel,
            sueldo_base_referencial
        )
        VALUES (
            %(cargo_id)s,
            %(codigo_cargo)s,
            %(nombre_cargo)s,
            %(nivel)s,
            %(sueldo_base_referencial)s
        );
    """

    with get_postgres_connection(config) as connection:
        with connection.cursor() as cursor:
            cursor.executemany(insert_sql, rows)

        connection.commit()

    return len(rows)


def load_centros_costo_raw(rows: list[dict]):
    config = get_rrhh_db_config()

    insert_sql = """
        INSERT INTO stg_rrhh_centros_costo_raw (
            centro_costo_id,
            codigo_centro_costo,
            nombre_centro_costo
        )
        VALUES (
            %(centro_costo_id)s,
            %(codigo_centro_costo)s,
            %(nombre_centro_costo)s
        );
    """

    with get_postgres_connection(config) as connection:
        with connection.cursor() as cursor:
            cursor.executemany(insert_sql, rows)

        connection.commit()

    return len(rows)


def _create_clean_table(
    clean_table: str,
    sql_filename: str,
):
    sql_path = SQL_DIR / sql_filename
    select_sql = sql_path.read_text(encoding="utf-8").strip().rstrip(";")

    sql = f"""
        DROP TABLE IF EXISTS {clean_table};

        CREATE TABLE {clean_table} AS
        {select_sql};
    """

    config = get_rrhh_db_config()

    with get_postgres_connection(config) as connection:
        with connection.cursor() as cursor:
            cursor.execute(sql)

        connection.commit()


def create_areas_clean_table():
    _create_clean_table(
        "stg_rrhh_areas_clean",
        "limpiar_areas.sql",
    )


def create_cargos_clean_table():
    _create_clean_table(
        "stg_rrhh_cargos_clean",
        "limpiar_cargos.sql",
    )


def create_centros_costo_clean_table():
    _create_clean_table(
        "stg_rrhh_centros_costo_clean",
        "limpiar_centros_costo.sql",
    )
