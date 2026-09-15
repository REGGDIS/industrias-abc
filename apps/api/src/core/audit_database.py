from __future__ import annotations

import psycopg
from psycopg.rows import dict_row

from .config import settings


def get_audit_connection() -> psycopg.Connection:
    return psycopg.connect(
        host=settings.audit_host,
        port=settings.audit_port,
        dbname=settings.audit_name,
        user=settings.audit_user,
        password=settings.audit_password,
        row_factory=dict_row,
    )
