import json
from datetime import timedelta
from pathlib import Path

import pytest

from etl.validate.asistencia import runner


def test_unique_run_ids(tmp_path):
    def broken_connection():
        raise RuntimeError("fallo controlado")

    first = runner.run(
        tmp_path / "first.json",
        connection_factory=broken_connection,
    )

    second = runner.run(
        tmp_path / "second.json",
        connection_factory=broken_connection,
    )

    assert first["run_id"] != second["run_id"]


def test_audit_connection_failure(tmp_path):
    def broken_connection():
        raise RuntimeError("password=secreto")

    report = runner.run(
        tmp_path / "failure.json",
        connection_factory=broken_connection,
    )

    assert report["status"] == "ERROR"
    assert report["stage"] == "extract"
    assert report["procesados"] == 0
    assert report["validos"] == 0
    assert report["errores"] == 0
    assert report["warnings"] == 0
    assert report["error"] == "RuntimeError: fallo en extract"

    persisted = json.loads(
        (tmp_path / "failure.json").read_text(encoding="utf-8")
    )

    assert "secreto" not in json.dumps(persisted)


def test_json_timedelta_serialization():
    assert runner._json_value(timedelta(hours=8)) == 28800.0


def test_quality_failure(tmp_path):
    trabajadores = [
        {
            "trabajador_id": 1,
            "rut": "12.345.678-5",
            "nombre": "ANA",
            "apellido": "PEREZ",
            "fecha_ingreso": "2025-01-01",
        }
    ]

    turnos = [
        {
            "turno_id": 1,
            "horas_jornada": 8,
        }
    ]

    asistencias = [
        {
            "asistencia_id": 1,
            "trabajador_id": 1,
            "turno_id": 1,
            "fecha": "2026-07-01",
            "hora_entrada": "08:00:00",
            "hora_salida": "17:00:00",
            "horas_trabajadas": -1,
            "horas_normales": 8,
            "horas_extras": 0,
            "atraso_minutos": 0,
            "ausentismo": 0,
            "estado": "PRESENTE",
        }
    ]

    original = runner.obtener_datos

    try:
        runner.obtener_datos = lambda connection_factory=None: (
            trabajadores,
            turnos,
            asistencias,
        )

        report = runner.run(
            tmp_path / "quality_failure.json"
        )

    finally:
        runner.obtener_datos = original

    assert report["status"] == "ERROR"
    assert report["stage"] == "validate"
    assert report["procesados"] == 1
    assert report["validos"] == 0
    assert report["errores"] == 1
    assert report["warnings"] == 0
    assert report["error"] == (
        "Se detectaron registros de asistencia "
        "con errores de calidad."
    )


@pytest.mark.skipif(
    not bool(__import__("os").environ.get("ASISTENCIA_INTEGRATION")),
    reason="requiere ASISTENCIA_INTEGRATION=1",
)
def test_real_success_audit(tmp_path):
    report = runner.run(
        tmp_path / "success.json"
    )

    assert report["status"] == "OK"
    assert report["stage"] is None
    assert report["procesados"] > 0
    assert report["errores"] == 0
    assert report["warnings"] == 0
    assert report["procesados"] == report["validos"]

    persisted = json.loads(
        (tmp_path / "success.json").read_text(encoding="utf-8")
    )

    assert persisted["run_id"] == report["run_id"]
