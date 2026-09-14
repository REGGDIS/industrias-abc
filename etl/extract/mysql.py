from contextlib import contextmanager
from typing import Iterator

import pymysql
from pymysql.connections import Connection

from etl.config.settings import DatabaseConfig


@contextmanager
def get_mysql_connection(config: DatabaseConfig) -> Iterator[Connection]:
    connection = pymysql.connect(
        host=config.host,
        port=config.port,
        database=config.database,
        user=config.user,
        password=config.password,
        charset="utf8mb4",
        cursorclass=pymysql.cursors.DictCursor,
        autocommit=False,
    )

    try:
        yield connection
    finally:
        connection.close()
