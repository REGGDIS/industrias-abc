from pathlib import Path

from etl.config.settings import get_rrhh_db_config
from etl.extract.postgres import get_postgres_connection


SQL_DIR = Path(__file__).resolve().parents[1] / "sql" / "extract" / "rrhh"


def extract_empleados():
    sql_path = SQL_DIR / "empleados.sql"
    sql = sql_path.read_text(encoding="utf-8")

    config = get_rrhh_db_config()

    with get_postgres_connection(config) as connection:
        with connection.cursor() as cursor:
            cursor.execute(sql)

            columns = [description.name for description in cursor.description]
            rows = cursor.fetchall()

    return [dict(zip(columns, row)) for row in rows]
