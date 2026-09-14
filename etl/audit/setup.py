from pathlib import Path

from etl.config.settings import DatabaseConfig
from etl.extract.postgres import get_postgres_connection


SQL_PATH = (
    Path(__file__).resolve().parents[1]
    / "sql"
    / "audit"
    / "001_create_etl_execution_log.sql"
)


def install_audit_tables(config: DatabaseConfig) -> None:
    sql = SQL_PATH.read_text(encoding="utf-8")

    with get_postgres_connection(config) as connection:
        with connection.cursor() as cursor:
            cursor.execute(sql)

        connection.commit()