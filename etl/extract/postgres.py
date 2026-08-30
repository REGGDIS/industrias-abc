from contextlib import contextmanager

import psycopg

from etl.config.settings import DatabaseConfig


@contextmanager
def get_postgres_connection(config: DatabaseConfig):
    connection = psycopg.connect(
        host=config.host,
        port=config.port,
        dbname=config.database,
        user=config.user,
        password=config.password,
    )

    try:
        yield connection
    finally:
        connection.close()
