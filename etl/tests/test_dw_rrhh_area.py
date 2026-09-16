from contextlib import contextmanager

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


def test_extract_areas_clean(monkeypatch):
    source_rows = [
        ("A01", "ADMINISTRACIÓN", "GERENCIA GENERAL"),
        ("A02", "RECURSOS HUMANOS", "GERENCIA DE PERSONAS"),
        (
            "A03",
            "FINANZAS Y CONTABILIDAD",
            "GERENCIA DE ADMINISTRACIÓN Y FINANZAS",
        ),
        ("A04", "COMPRAS Y ABASTECIMIENTO", "GERENCIA DE OPERACIONES"),
        ("A05", "PRODUCCIÓN", "GERENCIA DE OPERACIONES"),
        ("A06", "MANTENCIÓN", "GERENCIA DE OPERACIONES"),
        ("A07", "LOGÍSTICA", "GERENCIA DE OPERACIONES"),
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

    rows = dw_rrhh.extract_areas_clean()

    assert len(rows) == 7

    assert rows[0] == {
        "codigo_area": "A01",
        "nombre_area": "ADMINISTRACIÓN",
        "gerencia": "GERENCIA GENERAL",
    }

    assert rows[-1] == {
        "codigo_area": "A07",
        "nombre_area": "LOGÍSTICA",
        "gerencia": "GERENCIA DE OPERACIONES",
    }

    assert "stg_rrhh_areas_clean" in connection.fake_cursor.executed_sql
    assert "ORDER BY codigo_area" in connection.fake_cursor.executed_sql


def test_load_dim_area_vacio_no_conecta(monkeypatch):
    def fail_if_called():
        raise AssertionError(
            "No debe solicitar configuración DW para una carga vacía."
        )

    monkeypatch.setattr(
        dw_rrhh,
        "get_dw_db_config",
        fail_if_called,
    )

    result = dw_rrhh.load_dim_area([])

    assert result == 0


def test_load_dim_area_ejecuta_upsert_y_commit(monkeypatch):
    rows = [
        {
            "codigo_area": "A01",
            "nombre_area": "ADMINISTRACIÓN",
            "gerencia": "GERENCIA GENERAL",
        },
        {
            "codigo_area": "A02",
            "nombre_area": "RECURSOS HUMANOS",
            "gerencia": "GERENCIA DE PERSONAS",
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

    result = dw_rrhh.load_dim_area(rows)

    assert result == 2
    assert connection.committed is True

    sql = connection.fake_cursor.executemany_sql

    assert sql is not None
    assert "INSERT INTO dw.dim_area" in sql
    assert "ON CONFLICT (codigo_area)" in sql
    assert "DO UPDATE SET" in sql
    assert "nombre_area = EXCLUDED.nombre_area" in sql
    assert "gerencia = EXCLUDED.gerencia" in sql

    assert connection.fake_cursor.executemany_rows == rows


def test_upsert_area_protege_miembro_desconocido():
    sql_path = dw_rrhh.SQL_DIR / "cargar_dim_area.sql"

    sql = sql_path.read_text(encoding="utf-8")

    assert "area_key <> 0" in sql
    assert "codigo_area <> 'DESCONOCIDO'" in sql


def test_upsert_area_es_scd1_por_business_key():
    sql_path = dw_rrhh.SQL_DIR / "cargar_dim_area.sql"

    sql = sql_path.read_text(encoding="utf-8")

    assert "ON CONFLICT (codigo_area)" in sql
    assert "nombre_area = EXCLUDED.nombre_area" in sql
    assert "gerencia = EXCLUDED.gerencia" in sql
    assert "IS DISTINCT FROM EXCLUDED.nombre_area" in sql
    assert "IS DISTINCT FROM EXCLUDED.gerencia" in sql


def test_run_dim_area_reporta_conteos(monkeypatch):
    rows = [
        {
            "codigo_area": "A01",
            "nombre_area": "ADMINISTRACIÓN",
            "gerencia": "GERENCIA GENERAL",
        },
        {
            "codigo_area": "A02",
            "nombre_area": "RECURSOS HUMANOS",
            "gerencia": "GERENCIA DE PERSONAS",
        },
        {
            "codigo_area": "A03",
            "nombre_area": "FINANZAS Y CONTABILIDAD",
            "gerencia": "GERENCIA DE ADMINISTRACIÓN Y FINANZAS",
        },
    ]

    monkeypatch.setattr(
        dw_rrhh,
        "extract_areas_clean",
        lambda: rows,
    )
    monkeypatch.setattr(
        dw_rrhh,
        "load_dim_area",
        lambda received_rows: len(received_rows),
    )

    report = dw_rrhh.run_dim_area()

    assert report == {
        "source_rows": 3,
        "processed_rows": 3,
    }
