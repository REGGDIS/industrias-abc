from contextlib import contextmanager
from datetime import date

import pytest

from etl.load import dw_rrhh


class FakeCursor:
    def __init__(self, rows=None):
        self.rows = rows or []
        self.executed = []
        self.executemany_sql = None
        self.executemany_rows = None

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        return False

    def execute(self, sql, params=None):
        self.executed.append((sql, params))

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


def empleado_base(**overrides):
    row = {
        "rut_normalizado": "15000984-7",
        "nombres": "PAULA",
        "apellido_paterno": "CIVIL",
        "apellido_materno": "MARTÍNEZ",
        "fecha_nacimiento": date(2002, 2, 1),
        "fecha_ingreso": date(2019, 6, 7),
        "fecha_salida": None,
        "codigo_area": "A01",
        "codigo_cargo": "C01",
        "codigo_centro_costo": "CC001",
        "estado_laboral": "ACTIVO",
        "sexo": "F",
        "nacionalidad": "CHILENA",
        "area_key": 1,
        "cargo_key": 1,
        "centro_costo_key": 1,
    }
    row.update(overrides)
    return row


def test_rut_dv_valido():
    assert dw_rrhh.rut_dv_valido("15000984-7") is True
    assert dw_rrhh.rut_dv_valido("15002952-K") is True
    assert dw_rrhh.rut_dv_valido("15000984-8") is False
    assert dw_rrhh.rut_dv_valido("123") is False
    assert dw_rrhh.rut_dv_valido(None) is False


def test_build_initial_versions_activo():
    versions = dw_rrhh.build_initial_empleado_versions(
        [empleado_base()],
        date(2026, 9, 9),
    )

    assert len(versions) == 2

    historical = versions[0]
    current = versions[1]

    assert historical["estado_laboral"] == "ACTIVO"
    assert historical["fecha_desde"] == date(2019, 6, 7)
    assert historical["fecha_hasta"] == date(2026, 9, 9)
    assert historical["es_actual"] is False
    assert historical["contexto_historico_estimado"] is True

    assert current["estado_laboral"] == "ACTIVO"
    assert current["fecha_desde"] == date(2026, 9, 9)
    assert current["fecha_hasta"] is None
    assert current["es_actual"] is True
    assert current["contexto_historico_estimado"] is False


def test_build_initial_versions_inactivo():
    row = empleado_base(
        rut_normalizado="15008765-1",
        fecha_ingreso=date(2024, 7, 18),
        fecha_salida=date(2025, 2, 15),
        estado_laboral="INACTIVO",
        area_key=2,
        cargo_key=12,
        centro_costo_key=2,
    )

    versions = dw_rrhh.build_initial_empleado_versions(
        [row],
        date(2026, 9, 9),
    )

    assert len(versions) == 3

    assert versions[0]["estado_laboral"] == "ACTIVO"
    assert versions[0]["fecha_desde"] == date(2024, 7, 18)
    assert versions[0]["fecha_hasta"] == date(2025, 2, 15)
    assert versions[0]["contexto_historico_estimado"] is True

    assert versions[1]["estado_laboral"] == "INACTIVO"
    assert versions[1]["fecha_desde"] == date(2025, 2, 15)
    assert versions[1]["fecha_hasta"] == date(2026, 9, 9)
    assert versions[1]["contexto_historico_estimado"] is True

    assert versions[2]["estado_laboral"] == "INACTIVO"
    assert versions[2]["fecha_desde"] == date(2026, 9, 9)
    assert versions[2]["fecha_hasta"] is None
    assert versions[2]["es_actual"] is True
    assert versions[2]["contexto_historico_estimado"] is False


def test_build_initial_versions_rechaza_inactivo_sin_salida():
    row = empleado_base(
        estado_laboral="INACTIVO",
        fecha_salida=None,
    )

    with pytest.raises(
        ValueError,
        match="INACTIVO sin fecha_salida",
    ):
        dw_rrhh.build_initial_empleado_versions(
            [row],
            date(2026, 9, 9),
        )


def test_validate_versions_no_overlap_ok():
    versions = dw_rrhh.build_initial_empleado_versions(
        [empleado_base()],
        date(2026, 9, 9),
    )

    dw_rrhh.validate_empleado_versions_no_overlap(versions)


def test_validate_versions_detecta_solapamiento():
    versions = [
        {
            "rut_normalizado": "15000984-7",
            "fecha_desde": date(2026, 1, 1),
            "fecha_hasta": date(2026, 3, 1),
            "es_actual": False,
        },
        {
            "rut_normalizado": "15000984-7",
            "fecha_desde": date(2026, 2, 1),
            "fecha_hasta": None,
            "es_actual": True,
        },
    ]

    with pytest.raises(
        ValueError,
        match="Solapamiento SCD2",
    ):
        dw_rrhh.validate_empleado_versions_no_overlap(
            versions
        )


def test_validate_versions_requiere_una_actual():
    versions = [
        {
            "rut_normalizado": "15000984-7",
            "fecha_desde": date(2026, 1, 1),
            "fecha_hasta": date(2026, 2, 1),
            "es_actual": False,
        }
    ]

    with pytest.raises(
        ValueError,
        match="exactamente una versión actual",
    ):
        dw_rrhh.validate_empleado_versions_no_overlap(
            versions
        )


def test_load_dim_empleado_vacio_no_conecta(monkeypatch):
    def fail_if_called():
        raise AssertionError(
            "No debe conectarse al DW para carga vacía."
        )

    monkeypatch.setattr(
        dw_rrhh,
        "get_dw_db_config",
        fail_if_called,
    )

    assert dw_rrhh.load_dim_empleado([]) == 0


def test_load_dim_empleado_ejecuta_upsert_y_commit(
    monkeypatch,
):
    rows = dw_rrhh.build_initial_empleado_versions(
        [empleado_base()],
        date(2026, 9, 9),
    )

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
    monkeypatch.setattr(
        dw_rrhh,
        "validate_empleado_versions_against_dw",
        lambda received_rows: None,
    )

    result = dw_rrhh.load_dim_empleado(rows)

    assert result == 2
    assert connection.committed is True

    sql = connection.fake_cursor.executemany_sql

    assert sql is not None
    assert "INSERT INTO dw.dim_empleado" in sql
    assert (
        "ON CONFLICT (rut_normalizado, fecha_desde)"
        in sql
    )
    assert "empleado_key <> 0" in sql

    assert connection.fake_cursor.executemany_rows == rows


def test_run_dim_empleado_reporta_conteos(
    monkeypatch,
):
    source_rows = [empleado_base()]

    monkeypatch.setattr(
        dw_rrhh,
        "extract_empleados_clean",
        lambda: source_rows,
    )
    monkeypatch.setattr(
        dw_rrhh,
        "resolve_empleados_dimension_keys",
        lambda rows: rows,
    )
    monkeypatch.setattr(
        dw_rrhh,
        "load_dim_empleado",
        lambda rows: len(rows),
    )

    report = dw_rrhh.run_dim_empleado(
        date(2026, 9, 9)
    )

    assert report == {
        "source_rows": 1,
        "versions_generated": 2,
        "processed_rows": 2,
    }
