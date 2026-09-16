from contextlib import contextmanager
from unittest.mock import MagicMock

import etl.audit.logger as audit_logger
from etl.config.settings import DatabaseConfig


def _build_fake_connection(fetchone_result=None):
    cursor = MagicMock()
    connection = MagicMock()

    if fetchone_result is not None:
        cursor.fetchone.return_value = fetchone_result

    cursor_context = MagicMock()
    cursor_context.__enter__.return_value = cursor
    cursor_context.__exit__.return_value = None
    connection.cursor.return_value = cursor_context

    return connection, cursor


@contextmanager
def _fake_connection_context(connection):
    yield connection


def test_start_execution_uses_explicit_database_config(monkeypatch):
    config = DatabaseConfig(
        host="localhost",
        port=5432,
        database="audit_test",
        user="test_user",
        password="test_password",
    )

    connection, cursor = _build_fake_connection(fetchone_result=(123,))

    captured = {}

    def fake_get_postgres_connection(received_config):
        captured["config"] = received_config
        return _fake_connection_context(connection)

    monkeypatch.setattr(
        audit_logger,
        "get_postgres_connection",
        fake_get_postgres_connection,
    )

    execution_id = audit_logger.start_execution(
        source="RRHH",
        process="ETL_RRHH_TEST",
        db_config=config,
    )

    assert execution_id == 123
    assert captured["config"] == config

    cursor.execute.assert_called_once()

    sql, params = cursor.execute.call_args.args

    assert "INSERT INTO etl_execution_log" in sql
    assert params[0] == "RRHH"
    assert params[1] == "ETL_RRHH_TEST"
    assert params[3] == "RUNNING"

    connection.commit.assert_called_once()


def test_start_execution_preserves_rrhh_fallback(monkeypatch):
    rrhh_config = DatabaseConfig(
        host="localhost",
        port=5434,
        database="rrhh",
        user="postgres",
        password="postgres",
    )

    connection, _ = _build_fake_connection(fetchone_result=(456,))

    monkeypatch.setattr(
        audit_logger,
        "get_rrhh_db_config",
        lambda: rrhh_config,
    )

    captured = {}

    def fake_get_postgres_connection(received_config):
        captured["config"] = received_config
        return _fake_connection_context(connection)

    monkeypatch.setattr(
        audit_logger,
        "get_postgres_connection",
        fake_get_postgres_connection,
    )

    execution_id = audit_logger.start_execution(
        source="RRHH",
        process="ETL_RRHH_COMPAT",
    )

    assert execution_id == 456
    assert captured["config"] == rrhh_config


def test_finish_execution_writes_transversal_metrics(monkeypatch):
    config = DatabaseConfig(
        host="localhost",
        port=5432,
        database="audit_test",
        user="test_user",
        password="test_password",
    )

    connection, cursor = _build_fake_connection()

    captured = {}

    def fake_get_postgres_connection(received_config):
        captured["config"] = received_config
        return _fake_connection_context(connection)

    monkeypatch.setattr(
        audit_logger,
        "get_postgres_connection",
        fake_get_postgres_connection,
    )

    audit_logger.finish_execution(
        execution_id=10,
        records_read=100,
        records_valid=95,
        records_rejected=3,
        status="PARTIAL",
        message="Prueba logger transversal v0.1",
        records_inserted=70,
        records_updated=15,
        records_unchanged=10,
        records_review=2,
        db_config=config,
    )

    assert captured["config"] == config

    cursor.execute.assert_called_once()

    sql, params = cursor.execute.call_args.args

    assert "UPDATE etl_execution_log" in sql
    assert "records_inserted = %s" in sql
    assert "records_updated = %s" in sql
    assert "records_unchanged = %s" in sql
    assert "records_review = %s" in sql

    assert params[1:] == (
        100,
        95,
        70,
        15,
        10,
        3,
        2,
        "PARTIAL",
        "Prueba logger transversal v0.1",
        10,
    )

    connection.commit.assert_called_once()


def test_finish_execution_keeps_new_metrics_optional(monkeypatch):
    rrhh_config = DatabaseConfig(
        host="localhost",
        port=5434,
        database="rrhh",
        user="postgres",
        password="postgres",
    )

    connection, cursor = _build_fake_connection()

    monkeypatch.setattr(
        audit_logger,
        "get_rrhh_db_config",
        lambda: rrhh_config,
    )

    monkeypatch.setattr(
        audit_logger,
        "get_postgres_connection",
        lambda config: _fake_connection_context(connection),
    )

    audit_logger.finish_execution(
        execution_id=11,
        records_read=80,
        records_valid=80,
        records_rejected=0,
        status="SUCCESS",
        message="Compatibilidad RRHH",
    )

    _, params = cursor.execute.call_args.args

    assert params[1:] == (
        80,
        80,
        0,
        0,
        0,
        0,
        0,
        "SUCCESS",
        "Compatibilidad RRHH",
        11,
    )

    connection.commit.assert_called_once()