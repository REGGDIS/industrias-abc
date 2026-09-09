from contextlib import contextmanager
from decimal import Decimal

from etl.load import dw_rrhh


class FakeCursor:
    def __init__(self, rows=None):
        self.rows = rows or []
        self.executed_sql = None
        self.executemany_sql = None
        self.executemany_rows = None

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        return False

    def execute(self, sql):
        self.executed_sql = sql

    def executemany(self, sql, rows):
        self.executemany_sql = sql
        self.executemany_rows = rows

    def fetchall(self):
        return self.rows


class FakeConnection:
    def __init__(self, rows=None):
        self.fake_cursor = FakeCursor(rows)
        self.committed = False

    def cursor(self):
        return self.fake_cursor

    def commit(self):
        self.committed = True


def build_fake_connection(rows=None):
    connection = FakeConnection(rows)

    @contextmanager
    def fake_get_postgres_connection(config):
        yield connection

    return connection, fake_get_postgres_connection


def test_extract_cargos_clean(monkeypatch):
    source_rows = [
        (
            "C01",
            "GERENTE GENERAL",
            "DIRECCIÓN",
            Decimal("3500000.00"),
        ),
        (
            "C02",
            "JEFE DE ÁREA",
            "JEFATURA",
            Decimal("2200000.00"),
        ),
    ]

    connection, fake_connection = build_fake_connection(source_rows)

    monkeypatch.setattr(
        dw_rrhh,
        "get_rrhh_db_config",
        lambda: object(),
    )
    monkeypatch.setattr(
        dw_rrhh,
        "get_postgres_connection",
        fake_connection,
    )

    rows = dw_rrhh.extract_cargos_clean()

    assert len(rows) == 2

    assert rows[0] == {
        "codigo_cargo": "C01",
        "nombre_cargo": "GERENTE GENERAL",
        "nivel": "DIRECCIÓN",
        "sueldo_base_referencial": Decimal("3500000.00"),
    }

    assert rows[1] == {
        "codigo_cargo": "C02",
        "nombre_cargo": "JEFE DE ÁREA",
        "nivel": "JEFATURA",
        "sueldo_base_referencial": Decimal("2200000.00"),
    }

    assert "stg_rrhh_cargos_clean" in connection.fake_cursor.executed_sql
    assert "ORDER BY codigo_cargo" in connection.fake_cursor.executed_sql


def test_load_dim_cargo_vacio_no_conecta(monkeypatch):
    def fail_if_called():
        raise AssertionError(
            "No debe solicitar configuración DW para una carga vacía."
        )

    monkeypatch.setattr(
        dw_rrhh,
        "get_dw_db_config",
        fail_if_called,
    )

    result = dw_rrhh.load_dim_cargo([])

    assert result == 0


def test_load_dim_cargo_ejecuta_upsert_y_commit(monkeypatch):
    rows = [
        {
            "codigo_cargo": "C01",
            "nombre_cargo": "GERENTE GENERAL",
            "nivel": "DIRECCIÓN",
            "sueldo_base_referencial": Decimal("3500000.00"),
        },
        {
            "codigo_cargo": "C02",
            "nombre_cargo": "JEFE DE ÁREA",
            "nivel": "JEFATURA",
            "sueldo_base_referencial": Decimal("2200000.00"),
        },
    ]

    connection, fake_connection = build_fake_connection()

    monkeypatch.setattr(
        dw_rrhh,
        "get_dw_db_config",
        lambda: object(),
    )
    monkeypatch.setattr(
        dw_rrhh,
        "get_postgres_connection",
        fake_connection,
    )

    result = dw_rrhh.load_dim_cargo(rows)

    assert result == 2
    assert connection.committed is True

    sql = connection.fake_cursor.executemany_sql

    assert sql is not None
    assert "INSERT INTO dw.dim_cargo" in sql
    assert "ON CONFLICT (codigo_cargo)" in sql
    assert "DO UPDATE SET" in sql
    assert "nombre_cargo = EXCLUDED.nombre_cargo" in sql
    assert "nivel = EXCLUDED.nivel" in sql
    assert (
        "sueldo_base_referencial = EXCLUDED.sueldo_base_referencial"
        in sql
    )

    assert connection.fake_cursor.executemany_rows == rows


def test_upsert_cargo_protege_miembro_desconocido():
    sql_path = dw_rrhh.SQL_DIR / "cargar_dim_cargo.sql"

    sql = sql_path.read_text(encoding="utf-8")

    assert "cargo_key <> 0" in sql
    assert "codigo_cargo <> 'DESCONOCIDO'" in sql


def test_upsert_cargo_es_scd1_por_business_key():
    sql_path = dw_rrhh.SQL_DIR / "cargar_dim_cargo.sql"

    sql = sql_path.read_text(encoding="utf-8")

    assert "ON CONFLICT (codigo_cargo)" in sql
    assert "nombre_cargo = EXCLUDED.nombre_cargo" in sql
    assert "nivel = EXCLUDED.nivel" in sql
    assert (
        "sueldo_base_referencial = EXCLUDED.sueldo_base_referencial"
        in sql
    )
    assert "IS DISTINCT FROM EXCLUDED.nombre_cargo" in sql
    assert "IS DISTINCT FROM EXCLUDED.nivel" in sql
    assert (
        "IS DISTINCT FROM EXCLUDED.sueldo_base_referencial"
        in sql
    )


def test_run_dim_cargo_reporta_conteos(monkeypatch):
    rows = [
        {
            "codigo_cargo": "C01",
            "nombre_cargo": "GERENTE GENERAL",
            "nivel": "DIRECCIÓN",
            "sueldo_base_referencial": Decimal("3500000.00"),
        },
        {
            "codigo_cargo": "C02",
            "nombre_cargo": "JEFE DE ÁREA",
            "nivel": "JEFATURA",
            "sueldo_base_referencial": Decimal("2200000.00"),
        },
    ]

    monkeypatch.setattr(
        dw_rrhh,
        "extract_cargos_clean",
        lambda: rows,
    )
    monkeypatch.setattr(
        dw_rrhh,
        "load_dim_cargo",
        lambda received_rows: len(received_rows),
    )

    report = dw_rrhh.run_dim_cargo()

    assert report == {
        "source_rows": 2,
        "processed_rows": 2,
    }
