from datetime import datetime

from etl.config.settings import DatabaseConfig, get_rrhh_db_config
from etl.extract.postgres import get_postgres_connection


def start_execution(
    source: str,
    process: str,
    db_config: DatabaseConfig | None = None,
) -> int:
    config = db_config or get_rrhh_db_config()

    sql = """
        INSERT INTO etl_execution_log (
            source,
            process,
            started_at,
            status
        )
        VALUES (%s, %s, %s, %s)
        RETURNING execution_id;
    """

    with get_postgres_connection(config) as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                sql,
                (
                    source,
                    process,
                    datetime.now(),
                    "RUNNING",
                ),
            )
            execution_id = cursor.fetchone()[0]

        connection.commit()

    return execution_id


def finish_execution(
    execution_id: int,
    records_read: int,
    records_valid: int,
    records_rejected: int,
    status: str,
    message: str | None = None,
    *,
    records_inserted: int = 0,
    records_updated: int = 0,
    records_unchanged: int = 0,
    records_review: int = 0,
    db_config: DatabaseConfig | None = None,
) -> None:
    config = db_config or get_rrhh_db_config()

    sql = """
        UPDATE etl_execution_log
        SET
            finished_at = %s,
            records_read = %s,
            records_valid = %s,
            records_inserted = %s,
            records_updated = %s,
            records_unchanged = %s,
            records_rejected = %s,
            records_review = %s,
            status = %s,
            message = %s
        WHERE execution_id = %s;
    """

    with get_postgres_connection(config) as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                sql,
                (
                    datetime.now(),
                    records_read,
                    records_valid,
                    records_inserted,
                    records_updated,
                    records_unchanged,
                    records_rejected,
                    records_review,
                    status,
                    message,
                    execution_id,
                ),
            )

        connection.commit()
