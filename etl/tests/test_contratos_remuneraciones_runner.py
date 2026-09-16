from pathlib import Path

from etl.validate.contratos_remuneraciones import runner
from etl.validate.contratos_remuneraciones.validator import Finding


def test_runner_ok_sin_errores(monkeypatch, tmp_path):
    monkeypatch.setattr(
        runner,
        "_contar_entidades",
        lambda: {
            "empleado": 80,
            "contrato": 21,
            "liquidacion": 19,
            "concepto_pago": 9,
            "detalle_liquidacion": 106,
        },
    )

    monkeypatch.setattr(
        runner,
        "run_validation",
        lambda: [],
    )

    output = tmp_path / "evidencia.json"

    report = runner.run(output)

    assert report["status"] == "OK"
    assert report["stage"] is None
    assert report["procesados"] == 235
    assert report["validos"] == 235
    assert report["errores"] == 0
    assert report["warnings"] == 0
    assert report["controles_error"] == 0
    assert output.exists()


def test_runner_error_calidad_bloquea(monkeypatch):
    monkeypatch.setattr(
        runner,
        "_contar_entidades",
        lambda: {
            "empleado": 80,
            "contrato": 21,
            "liquidacion": 19,
            "concepto_pago": 9,
            "detalle_liquidacion": 106,
        },
    )

    monkeypatch.setattr(
        runner,
        "run_validation",
        lambda: [
            Finding(
                entidad="DetalleLiquidacion",
                identificador=1,
                regla="monto_negativo",
                severidad="ERROR",
                detalle="monto=-100",
            )
        ],
    )

    report = runner.run()

    assert report["status"] == "ERROR"
    assert report["stage"] == "validacion"
    assert report["procesados"] == 235
    assert report["validos"] == 234
    assert report["errores"] == 1
    assert report["controles_error"] == 1


def test_runner_warning_no_bloquea(monkeypatch):
    monkeypatch.setattr(
        runner,
        "_contar_entidades",
        lambda: {
            "empleado": 80,
            "contrato": 21,
            "liquidacion": 19,
            "concepto_pago": 9,
            "detalle_liquidacion": 106,
        },
    )

    monkeypatch.setattr(
        runner,
        "run_validation",
        lambda: [
            Finding(
                entidad="Contrato",
                identificador=1,
                regla="contrato_vencido",
                severidad="WARNING",
                detalle="contrato vencido",
            )
        ],
    )

    report = runner.run()

    assert report["status"] == "OK"
    assert report["stage"] is None
    assert report["procesados"] == 235
    assert report["errores"] == 0
    assert report["warnings"] == 1
    assert report["review"] == 1
    assert report["controles_error"] == 0


def test_runner_run_id_unico(monkeypatch):
    monkeypatch.setattr(
        runner,
        "_contar_entidades",
        lambda: {
            "empleado": 1,
            "contrato": 0,
            "liquidacion": 0,
            "concepto_pago": 0,
            "detalle_liquidacion": 0,
        },
    )

    monkeypatch.setattr(
        runner,
        "run_validation",
        lambda: [],
    )

    a = runner.run()
    b = runner.run()

    assert a["run_id"] != b["run_id"]
