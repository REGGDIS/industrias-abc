from pathlib import Path

from etl.validate import rrhh_runner


def test_runner_ok(monkeypatch, tmp_path: Path):
    monkeypatch.setattr(
        rrhh_runner,
        "run_rrhh_etl",
        lambda: {
            "execution_id": 10,
            "records_read": 80,
            "records_valid": 80,
            "records_rejected": 0,
            "areas": 7,
            "cargos": 12,
            "centros_costo": 7,
            "status": "SUCCESS",
        },
    )

    monkeypatch.setattr(
        rrhh_runner,
        "_fetch_staging_counts",
        lambda: {
            "empleados": {"raw": 80, "clean": 80},
            "areas": {"raw": 7, "clean": 7},
            "cargos": {"raw": 12, "clean": 12},
            "centros_costo": {"raw": 7, "clean": 7},
        },
    )

    output = tmp_path / "evidencia.json"

    report = rrhh_runner.run(output)

    assert report["status"] == "OK"
    assert report["stage"] is None
    assert report["procesados"] == 80
    assert report["validos"] == 80
    assert report["errores"] == 0
    assert report["controles_error"] == 0
    assert report["execution_id_origen"] == 10
    assert output.exists()


def test_runner_detecta_descuadre_raw(monkeypatch):
    monkeypatch.setattr(
        rrhh_runner,
        "run_rrhh_etl",
        lambda: {
            "execution_id": 11,
            "records_read": 80,
            "records_valid": 80,
            "records_rejected": 0,
            "areas": 7,
            "cargos": 12,
            "centros_costo": 7,
            "status": "SUCCESS",
        },
    )

    monkeypatch.setattr(
        rrhh_runner,
        "_fetch_staging_counts",
        lambda: {
            "empleados": {"raw": 79, "clean": 80},
            "areas": {"raw": 7, "clean": 7},
            "cargos": {"raw": 12, "clean": 12},
            "centros_costo": {"raw": 7, "clean": 7},
        },
    )

    report = rrhh_runner.run()

    assert report["status"] == "ERROR"
    assert report["stage"] == "verificacion_staging"
    assert report["controles_error"] == 1
    assert report["entidades"]["empleados"]["raw_ok"] is False
    assert report["entidades"]["empleados"]["clean_ok"] is True


def test_runner_detecta_descuadre_clean(monkeypatch):
    monkeypatch.setattr(
        rrhh_runner,
        "run_rrhh_etl",
        lambda: {
            "execution_id": 12,
            "records_read": 80,
            "records_valid": 80,
            "records_rejected": 0,
            "areas": 7,
            "cargos": 12,
            "centros_costo": 7,
            "status": "SUCCESS",
        },
    )

    monkeypatch.setattr(
        rrhh_runner,
        "_fetch_staging_counts",
        lambda: {
            "empleados": {"raw": 80, "clean": 80},
            "areas": {"raw": 7, "clean": 6},
            "cargos": {"raw": 12, "clean": 12},
            "centros_costo": {"raw": 7, "clean": 7},
        },
    )

    report = rrhh_runner.run()

    assert report["status"] == "ERROR"
    assert report["stage"] == "verificacion_staging"
    assert report["controles_error"] == 1
    assert report["entidades"]["areas"]["raw_ok"] is True
    assert report["entidades"]["areas"]["clean_ok"] is False


def test_runner_error_tecnico_no_expone_detalle(monkeypatch):
    monkeypatch.setattr(
        rrhh_runner,
        "run_rrhh_etl",
        lambda: (_ for _ in ()).throw(
            RuntimeError("password=secreto123")
        ),
    )

    report = rrhh_runner.run()

    assert report["status"] == "ERROR"
    assert report["stage"] == "etl_rrhh"
    assert report["controles_error"] == 1
    assert "secreto123" not in report["error"]
    assert "RuntimeError" in report["error"]


def test_runner_genera_run_id_unico(monkeypatch):
    monkeypatch.setattr(
        rrhh_runner,
        "run_rrhh_etl",
        lambda: {
            "execution_id": 13,
            "records_read": 0,
            "records_valid": 0,
            "records_rejected": 0,
            "areas": 0,
            "cargos": 0,
            "centros_costo": 0,
            "status": "SUCCESS",
        },
    )

    monkeypatch.setattr(
        rrhh_runner,
        "_fetch_staging_counts",
        lambda: {
            "empleados": {"raw": 0, "clean": 0},
            "areas": {"raw": 0, "clean": 0},
            "cargos": {"raw": 0, "clean": 0},
            "centros_costo": {"raw": 0, "clean": 0},
        },
    )

    first = rrhh_runner.run()
    second = rrhh_runner.run()

    assert first["run_id"] != second["run_id"]
