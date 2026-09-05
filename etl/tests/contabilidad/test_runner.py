import json
import os
from contextlib import contextmanager
from decimal import Decimal

import pytest
from psycopg.rows import dict_row

from etl.validate.contabilidad import runner


def test_audit_connection_failure(tmp_path):
    @contextmanager
    def broken():
        raise RuntimeError("password=must-not-be-recorded")
        yield

    path = tmp_path / "failed.json"
    report = runner.run(path, broken)
    saved = json.loads(path.read_text(encoding="utf-8"))
    assert saved == report
    assert report["status"] == "ERROR"
    assert report["stage"] == "configuration"
    assert report["duration_seconds"] >= 0
    assert report["finished_at"] >= report["started_at"]
    assert "must-not-be-recorded" not in path.read_text()


def test_exact_json_decimals():
    assert runner.json_value(Decimal("123456789.123400")) == "123456789.123400"


def test_unique_run_ids(tmp_path):
    @contextmanager
    def broken():
        raise RuntimeError("unavailable")
        yield

    first = runner.run(tmp_path / "first.json", broken)
    second = runner.run(tmp_path / "second.json", broken)
    assert first["run_id"] != second["run_id"]


@pytest.fixture
def db():
    if os.getenv("CONTABILIDAD_INTEGRATION") != "1":
        pytest.skip("Activar CONTABILIDAD_INTEGRATION=1 para PostgreSQL real")
    with runner.get_postgres_connection(runner.get_contabilidad_db_config()) as conn:
        with conn.cursor(row_factory=dict_row) as cur:
            cur.execute("SET TRANSACTION ISOLATION LEVEL REPEATABLE READ")
            # Fuentes TEMP sin restricciones: casos adversos sin tocar operacionales.
            for entity in runner.ENTITIES:
                cur.execute(f"CREATE TEMP TABLE {entity} AS SELECT * FROM public.{entity}")
            yield cur
        conn.rollback()


def prepared(db):
    runner.prepare(db, "raw")
    runner.prepare(db, "clean")


def test_real_success_audit(db, tmp_path):
    @contextmanager
    def factory():
        yield db.connection

    report = runner.run(tmp_path / "success.json", factory)
    assert report["status"] == "OK", report
    assert report["procesados"] == report["validos"] > 0
    assert report["errores"] == report["review"] == 0
    assert report["controles_error"] == 0
    assert all(c["status"] == "OK" for c in report["controles"])
    assert json.loads((tmp_path / "success.json").read_text())["run_id"] == report["run_id"]


@pytest.mark.parametrize("assignment", [
    "debe=-1", "haber=-1", "debe=0, haber=0", "debe=1, haber=1",
    "tipo_cambio=0", "tipo_cambio=-1", "debe=NULL", "haber=NULL",
    "tipo_cambio=NULL", "cuenta_id=-999", "centro_costo_id=-999",
    "moneda=''", "documento_tipo=''",
])
def test_invalid_movements(db, assignment):
    prepared(db)
    db.execute(f"UPDATE stg_contabilidad_movimientos_contables_clean SET {assignment} "
               "WHERE movimiento_id=(SELECT MIN(movimiento_id) FROM movimientos_contables) RETURNING movimiento_id")
    changed = db.fetchone()["movimiento_id"]
    report = runner.validate(db)
    record = next(r for r in report["registros"] if r["entidad"] == "movimientos_contables" and r["id"] == changed)
    assert record["estado"] == "ERROR"
    assert report["procesados"] == report["validos"] + report["errores"]


@pytest.mark.parametrize("entity,assignment,rule", [
    ("centros_costo", "estado='INVALIDO'", "estado_centro"),
    ("cuentas_contables", "estado='INVALIDO'", "estado_cuenta"),
    ("centros_costo", "area_id=-999", "area_inexistente"),
    ("cuentas_contables", "cuenta_padre_id=-999", "padre_inexistente"),
    ("cuentas_contables", "nivel=0", "obligatorios_cuentas_contables"),
    ("areas", "codigo_area=' '", "obligatorios_areas"),
])
def test_invalid_masters(db, entity, assignment, rule):
    prepared(db)
    pk = runner.ENTITIES[entity]
    db.execute(f"UPDATE stg_contabilidad_{entity}_clean SET {assignment} WHERE {pk}=(SELECT MIN({pk}) FROM {entity})")
    report = runner.validate(db)
    assert next(c for c in report["controles"] if c["name"] == rule)["status"] == "ERROR"
    assert report["errores"] > 0


@pytest.mark.parametrize("entity,code,rule", [
    ("areas", "codigo_area", "codigo_area_duplicado"),
    ("centros_costo", "codigo", "codigo_centro_duplicado"),
    ("cuentas_contables", "codigo_cuenta", "codigo_cuenta_duplicado"),
])
def test_normalization_collision(db, entity, code, rule):
    db.execute(f"UPDATE {entity} SET {code}=' x '")
    prepared(db)
    result = runner.validate(db)
    assert next(c for c in result["controles"] if c["name"] == rule)["status"] == "ERROR"
    assert all(r["estado"] == "ERROR" for r in result["registros"] if r["entidad"] == entity)


def test_normalization_preservation_and_idempotence(db):
    db.execute("ALTER TABLE pg_temp.movimientos_contables ALTER COLUMN moneda TYPE text, "
               "ALTER COLUMN debe TYPE numeric, ALTER COLUMN haber TYPE numeric")
    db.execute("UPDATE movimientos_contables SET moneda=' usd ', documento_tipo=' factura ', "
               "debe=debe+0.1234, haber=haber+0.1234, tipo_cambio=1.2345")
    db.execute("UPDATE cuentas_contables SET codigo_cuenta=' ' || LOWER(codigo_cuenta) || ' ', estado=' activa '")
    prepared(db)
    trace = runner.normalization_trace(db)
    assert any(r["original"] == " usd " and r["normalizado"] == "USD" for r in trace)
    assert any(r["normalizado"] == "FACTURA" for r in trace)
    assert not any(r["campo"] in ("debe", "haber", "tipo_cambio", "cuenta_padre_id") for r in trace)
    db.execute("SELECT tipo_cambio, debe FROM stg_contabilidad_movimientos_contables_clean LIMIT 1")
    sample = db.fetchone()
    assert sample["tipo_cambio"] == Decimal("1.2345")
    assert sample["debe"] % 1 == Decimal("0.1234")
    for entity in runner.ENTITIES:
        db.execute(f"SELECT * FROM stg_contabilidad_{entity}_clean")
        first = db.fetchall()
        db.execute(f"TRUNCATE pg_temp.stg_contabilidad_{entity}_raw")
        db.execute(f"INSERT INTO stg_contabilidad_{entity}_raw SELECT * FROM stg_contabilidad_{entity}_clean")
        db.execute(runner.read_sql("staging", entity))
        assert db.fetchall() == first


@pytest.mark.parametrize("change,rule", [
    ("DELETE FROM stg_contabilidad_areas_clean", "conteos"),
    ("UPDATE stg_contabilidad_movimientos_contables_clean SET debe=debe+1", "sumas"),
    ("UPDATE stg_contabilidad_movimientos_contables_clean SET tipo_cambio=tipo_cambio+1", "preservacion_movimientos_contables"),
    ("UPDATE stg_contabilidad_cuentas_contables_clean SET cuenta_padre_id=NULL", "preservacion_cuentas_contables"),
    ("UPDATE stg_contabilidad_movimientos_contables_clean SET moneda='ZZZ'", "preservacion_moneda"),
    ("UPDATE stg_contabilidad_movimientos_contables_clean SET documento_tipo='ZZZ'", "preservacion_documento"),
])
def test_reconciliation_detects_changes(db, change, rule):
    prepared(db)
    db.execute(change)
    result = runner.validate(db)
    assert next(c for c in result["controles"] if c["name"] == rule)["status"] == "ERROR"


def test_failed_quality_audit(db, tmp_path):
    db.execute("UPDATE movimientos_contables SET tipo_cambio=0")

    @contextmanager
    def factory():
        yield db.connection

    result = runner.run(tmp_path / "quality.json", factory)
    assert result["status"] == "ERROR"
    assert result["stage"] == "validate"
    assert result["errores"] > 0
    assert result["error"]


def test_failure_normalizing(db, monkeypatch, tmp_path):
    original = runner.prepare

    def fail(cursor, stage):
        if stage == "clean":
            cursor.execute("SELECT 1 / 0")
        original(cursor, stage)

    @contextmanager
    def factory():
        yield db.connection

    monkeypatch.setattr(runner, "prepare", fail)
    report = runner.run(tmp_path / "sql-error.json", factory)
    assert report["status"] == "ERROR"
    assert report["stage"] == "normalize"
    assert "DivisionByZero" in report["error"]


def test_global_balance_and_area_cardinality(db):
    db.execute("UPDATE movimientos_contables SET debe=debe+1 WHERE debe>0")
    db.execute("UPDATE centros_costo SET area_id=(SELECT MIN(area_id) FROM areas)")
    prepared(db)
    report = runner.validate(db)
    for name in ("cuadratura", "area_multiples_centros"):
        assert next(c for c in report["controles"] if c["name"] == name)["status"] == "ERROR"


def test_empty_source(db):
    for entity in runner.ENTITIES:
        db.execute(f"TRUNCATE pg_temp.{entity}")
    prepared(db)
    report = runner.validate(db)
    assert report["procesados"] == 0
    assert all(c["status"] == "OK" for c in report["controles"])

def test_global_control_error_is_audited(db):
    prepared(db)

    db.execute("DELETE FROM stg_contabilidad_areas_clean")

    report = runner.validate(db)

    conteos = next(
        control
        for control in report["controles"]
        if control["name"] == "conteos"
    )

    assert conteos["status"] == "ERROR"
    assert report["controles_error"] >= 1

    # Los registros eliminados ya no existen en CLEAN y, por tanto,
    # no se inventan registros ERROR para representarlos.
    assert report["procesados"] == report["validos"] + report["errores"]
