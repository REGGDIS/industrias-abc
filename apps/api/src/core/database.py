from __future__ import annotations

import psycopg
from psycopg.rows import dict_row

from .config import settings


def get_connection() -> psycopg.Connection:
    return psycopg.connect(
        host=settings.dw_host,
        port=settings.dw_port,
        dbname=settings.dw_name,
        user=settings.dw_user,
        password=settings.dw_password,
        row_factory=dict_row,
    )
