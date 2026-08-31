from datetime import datetime

from etl.config.settings import get_rrhh_db_config
from etl.extract.postgres import get_postgres_connection


def start_execution(source: str, process: str) -> int:
    config = get_rrhh_db_config()

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
):
    config = get_rrhh_db_config()

    sql = """
        UPDATE etl_execution_log
        SET
            finished_at = %s,
            records_read = %s,
            records_valid = %s,
            records_rejected = %s,
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
                    records_rejected,
                    status,
                    message,
                    execution_id,
                ),
            )

        connection.commit()
