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


def test_extract_centros_costo_clean(monkeypatch):
    source_rows = [
        ("CC001", "ADMINISTRACIÓN GENERAL"),
        ("CC002", "RECURSOS HUMANOS"),
        ("CC003", "FINANZAS"),
        ("CC004", "ABASTECIMIENTO"),
        ("CC005", "PLANTA DE PRODUCCIÓN"),
        ("CC006", "MANTENCIÓN INDUSTRIAL"),
        ("CC007", "LOGÍSTICA Y BODEGA"),
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

    rows = dw_rrhh.extract_centros_costo_clean()

    assert len(rows) == 7
    assert rows[0] == {
        "codigo_centro_costo": "CC001",
        "nombre_centro_costo": "ADMINISTRACIÓN GENERAL",
    }
    assert rows[-1] == {
        "codigo_centro_costo": "CC007",
        "nombre_centro_costo": "LOGÍSTICA Y BODEGA",
    }

    assert "stg_rrhh_centros_costo_clean" in (
        connection.fake_cursor.executed_sql
    )
    assert "ORDER BY codigo_centro_costo" in (
        connection.fake_cursor.executed_sql
    )


def test_load_dim_centro_costo_vacio_no_conecta(monkeypatch):
    def fail_if_called():
        raise AssertionError(
            "No debe solicitar configuración DW para una carga vacía."
        )

    monkeypatch.setattr(
        dw_rrhh,
        "get_dw_db_config",
        fail_if_called,
    )

    result = dw_rrhh.load_dim_centro_costo([])

    assert result == 0


def test_load_dim_centro_costo_ejecuta_upsert_y_commit(monkeypatch):
    rows = [
        {
            "codigo_centro_costo": "CC001",
            "nombre_centro_costo": "ADMINISTRACIÓN GENERAL",
        },
        {
            "codigo_centro_costo": "CC002",
            "nombre_centro_costo": "RECURSOS HUMANOS",
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

    result = dw_rrhh.load_dim_centro_costo(rows)

    assert result == 2
    assert connection.committed is True

    sql = connection.fake_cursor.executemany_sql

    assert sql is not None
    assert "INSERT INTO dw.dim_centro_costo" in sql
    assert "ON CONFLICT (codigo_centro_costo)" in sql
    assert "DO UPDATE SET" in sql
    assert "nombre_centro_costo = EXCLUDED.nombre_centro_costo" in sql

    assert connection.fake_cursor.executemany_rows == rows


def test_upsert_protege_miembro_desconocido():
    sql_path = (
        dw_rrhh.SQL_DIR
        / "cargar_dim_centro_costo.sql"
    )

    sql = sql_path.read_text(encoding="utf-8")

    assert "centro_costo_key <> 0" in sql
    assert "codigo_centro_costo <> 'DESCONOCIDO'" in sql


def test_upsert_es_scd1_por_business_key():
    sql_path = (
        dw_rrhh.SQL_DIR
        / "cargar_dim_centro_costo.sql"
    )

    sql = sql_path.read_text(encoding="utf-8")

    assert "ON CONFLICT (codigo_centro_costo)" in sql
    assert "nombre_centro_costo = EXCLUDED.nombre_centro_costo" in sql
    assert "IS DISTINCT FROM EXCLUDED.nombre_centro_costo" in sql


def test_run_dim_centro_costo_reporta_conteos(monkeypatch):
    rows = [
        {
            "codigo_centro_costo": "CC001",
            "nombre_centro_costo": "ADMINISTRACIÓN GENERAL",
        },
        {
            "codigo_centro_costo": "CC002",
            "nombre_centro_costo": "RECURSOS HUMANOS",
        },
        {
            "codigo_centro_costo": "CC003",
            "nombre_centro_costo": "FINANZAS",
        },
    ]

    monkeypatch.setattr(
        dw_rrhh,
        "extract_centros_costo_clean",
        lambda: rows,
    )
    monkeypatch.setattr(
        dw_rrhh,
        "load_dim_centro_costo",
        lambda received_rows: len(received_rows),
    )

    report = dw_rrhh.run_dim_centro_costo()

    assert report == {
        "source_rows": 3,
        "processed_rows": 3,
    }
