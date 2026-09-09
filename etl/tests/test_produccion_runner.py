from datetime import date
from pathlib import Path

from etl.validate.produccion_calidad import (
    QualityFinding,
    QualitySummary,
)
from etl.validate import produccion_runner


def test_runner_ok(monkeypatch, tmp_path: Path):
    monkeypatch.setattr(
        produccion_runner,
        "read_csv_consumos",
        lambda: [object()] * 6,
    )
    monkeypatch.setattr(
        produccion_runner,
        "fetch_mysql_consumos",
        lambda: [object()] * 6,
    )
    monkeypatch.setattr(
        produccion_runner,
        "profile_quality",
        lambda csv_rows, mysql_rows: QualitySummary(
            rows_processed=6,
            valid_rows=6,
            exact_duplicates=0,
            key_duplicates=0,
            rows_with_error=0,
            rows_with_warning=0,
            findings=(),
        ),
    )

    output = tmp_path / "evidencia.json"

    report = produccion_runner.run(output)

    assert report["status"] == "OK"
    assert report["procesados"] == 6
    assert report["validos"] == 6
    assert report["errores"] == 0
    assert report["warnings"] == 0
    assert report["controles_error"] == 0
    assert output.exists()


def test_runner_error_calidad(monkeypatch):
    finding = QualityFinding(
        row_number=2,
        business_key=("OP-001", 101, date(2026, 1, 10)),
        rule="VALIDACION_CSV",
        severity="ERROR",
        detail="cantidad_consumida mayor que cantidad_planificada",
    )

    monkeypatch.setattr(
        produccion_runner,
        "read_csv_consumos",
        lambda: [object()] * 6,
    )
    monkeypatch.setattr(
        produccion_runner,
        "fetch_mysql_consumos",
        lambda: [object()] * 6,
    )
    monkeypatch.setattr(
        produccion_runner,
        "profile_quality",
        lambda csv_rows, mysql_rows: QualitySummary(
            rows_processed=6,
            valid_rows=5,
            exact_duplicates=0,
            key_duplicates=0,
            rows_with_error=1,
            rows_with_warning=0,
            findings=(finding,),
        ),
    )

    report = produccion_runner.run()

    assert report["status"] == "ERROR"
    assert report["stage"] == "validacion"
    assert report["procesados"] == 6
    assert report["validos"] == 5
    assert report["errores"] == 1
    assert report["controles_error"] == 1


def test_runner_warning_no_bloquea(monkeypatch):
    finding = QualityFinding(
        row_number=2,
        business_key=("OP-001", 101, date(2026, 1, 10)),
        rule="NO_MATCH",
        severity="WARNING",
        detail="No existe consumo equivalente en MySQL",
    )

    monkeypatch.setattr(
        produccion_runner,
        "read_csv_consumos",
        lambda: [object()] * 6,
    )
    monkeypatch.setattr(
        produccion_runner,
        "fetch_mysql_consumos",
        lambda: [object()] * 6,
    )
    monkeypatch.setattr(
        produccion_runner,
        "profile_quality",
        lambda csv_rows, mysql_rows: QualitySummary(
            rows_processed=6,
            valid_rows=5,
            exact_duplicates=0,
            key_duplicates=0,
            rows_with_error=0,
            rows_with_warning=1,
            findings=(finding,),
        ),
    )

    report = produccion_runner.run()

    assert report["status"] == "OK"
    assert report["review"] == 1
    assert report["warnings"] == 1
    assert report["errores"] == 0
    assert report["controles_error"] == 0


def test_runner_genera_run_id_unico(monkeypatch):
    monkeypatch.setattr(
        produccion_runner,
        "read_csv_consumos",
        lambda: [],
    )
    monkeypatch.setattr(
        produccion_runner,
        "fetch_mysql_consumos",
        lambda: [],
    )
    monkeypatch.setattr(
        produccion_runner,
        "profile_quality",
        lambda csv_rows, mysql_rows: QualitySummary(
            rows_processed=0,
            valid_rows=0,
            exact_duplicates=0,
            key_duplicates=0,
            rows_with_error=0,
            rows_with_warning=0,
            findings=(),
        ),
    )

    first = produccion_runner.run()
    second = produccion_runner.run()

    assert first["run_id"] != second["run_id"]
