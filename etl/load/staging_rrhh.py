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
