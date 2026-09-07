"""
etl/tests/test_contratos_remuneraciones_validate.py

Pruebas del dominio Contratos y Remuneraciones (Encargo 0.2).

No requieren conexión a SQL Server: prueban directamente las funciones de
regla puras y las funciones evaluar_* de
etl/validate/contratos_remuneraciones.py, usando filas de ejemplo (dict).

Ejecutar desde la raíz del repositorio con:
    pytest etl/tests/test_contratos_remuneraciones_validate.py -v

El import de abajo carga el módulo directamente desde su ruta de archivo
(importlib), en vez de depender de que etl/ tenga __init__.py o de la
configuración de paquetes del repositorio. Así funciona sin importar cómo
esté configurado pytest en el resto del proyecto.
"""

import importlib.util
import sys
from datetime import date
from pathlib import Path

import pytest

_MODULE_PATH = Path(__file__).resolve().parent.parent / "validate" / "contratos_remuneraciones.py"
_spec = importlib.util.spec_from_file_location("contratos_remuneraciones_validate", _MODULE_PATH)
_module = importlib.util.module_from_spec(_spec)
sys.modules[_spec.name] = _module  # necesario para que @dataclass resuelva su módulo
_spec.loader.exec_module(_module)  # type: ignore[union-attr]

Finding = _module.Finding
evaluar_contrato = _module.evaluar_contrato
evaluar_empleado = _module.evaluar_empleado
evaluar_liquidacion = _module.evaluar_liquidacion
rule_contrato_vencido = _module.rule_contrato_vencido
rule_fecha_inicio_mayor_termino = _module.rule_fecha_inicio_mayor_termino
rule_liquidacion_sin_empleado = _module.rule_liquidacion_sin_empleado
rule_monto_negativo = _module.rule_monto_negativo
rule_rut_invalido = _module.rule_rut_invalido


# ---------------------------------------------------------------------------
# Reglas puras
# ---------------------------------------------------------------------------

@pytest.mark.parametrize("rut,esperado", [
    ("12345678-9", False),
    ("1234567-K", False),
    ("1234567-k", False),
    (None, True),
    ("", True),
    ("   ", True),
    ("no-es-un-rut", True),
    ("123-4", True),
])
def test_rule_rut_invalido(rut, esperado):
    assert rule_rut_invalido(rut) is esperado


def test_rule_fecha_inicio_mayor_termino_true():
    assert rule_fecha_inicio_mayor_termino(date(2026, 5, 1), date(2026, 1, 1)) is True


def test_rule_fecha_inicio_mayor_termino_false():
    assert rule_fecha_inicio_mayor_termino(date(2026, 1, 1), date(2026, 5, 1)) is False


def test_rule_fecha_inicio_mayor_termino_none_termino():
    # Contrato indefinido (fecha_termino NULL) no debe marcarse como error.
    assert rule_fecha_inicio_mayor_termino(date(2026, 1, 1), None) is False


def test_rule_contrato_vencido_true():
    hoy = date(2026, 9, 1)
    assert rule_contrato_vencido(date(2026, 1, 1), "VIGENTE", hoy) is True


def test_rule_contrato_vencido_false_si_terminado():
    hoy = date(2026, 9, 1)
    assert rule_contrato_vencido(date(2026, 1, 1), "TERMINADO", hoy) is False


def test_rule_contrato_vencido_false_si_no_vencido():
    hoy = date(2026, 1, 1)
    assert rule_contrato_vencido(date(2026, 9, 1), "VIGENTE", hoy) is False


def test_rule_liquidacion_sin_empleado():
    assert rule_liquidacion_sin_empleado(None) is True
    assert rule_liquidacion_sin_empleado("") is True
    assert rule_liquidacion_sin_empleado("   ") is True
    assert rule_liquidacion_sin_empleado("EMP001") is False


def test_rule_monto_negativo():
    assert rule_monto_negativo(100, 200, -1) is True
    assert rule_monto_negativo(100, 200, 0) is False
    assert rule_monto_negativo(None, None) is False


# ---------------------------------------------------------------------------
# Funciones evaluar_* (clasificación de filas completas)
# ---------------------------------------------------------------------------

def test_evaluar_empleado_rut_invalido():
    row = {"empleado_id": "EMP001", "rut_referencia": None}
    findings = evaluar_empleado(row)
    assert len(findings) == 1
    assert findings[0].regla == "rut_invalido"
    assert findings[0].severidad == "ERROR"


def test_evaluar_empleado_ok():
    row = {"empleado_id": "EMP001", "rut_referencia": "12345678-9"}
    assert evaluar_empleado(row) == []


def test_evaluar_contrato_fecha_invalida():
    row = {
        "contrato_id": 1,
        "fecha_inicio": date(2026, 6, 1),
        "fecha_termino": date(2026, 1, 1),
        "sueldo_base": 500000,
        "estado": "VIGENTE",
    }
    findings = evaluar_contrato(row, hoy=date(2026, 1, 15))
    reglas = {f.regla for f in findings}
    assert "fecha_inicio_mayor_termino" in reglas


def test_evaluar_contrato_vencido_es_warning_no_error():
    row = {
        "contrato_id": 2,
        "fecha_inicio": date(2020, 1, 1),
        "fecha_termino": date(2025, 1, 1),
        "sueldo_base": 500000,
        "estado": "VIGENTE",
    }
    findings = evaluar_contrato(row, hoy=date(2026, 1, 1))
    vencidos = [f for f in findings if f.regla == "contrato_vencido"]
    assert len(vencidos) == 1
    assert vencidos[0].severidad == "WARNING"


def test_evaluar_contrato_sueldo_negativo():
    row = {
        "contrato_id": 3,
        "fecha_inicio": date(2026, 1, 1),
        "fecha_termino": None,
        "sueldo_base": -100,
        "estado": "VIGENTE",
    }
    findings = evaluar_contrato(row, hoy=date(2026, 1, 15))
    reglas = {f.regla for f in findings}
    assert "monto_negativo" in reglas


def test_evaluar_contrato_ok_sin_hallazgos():
    row = {
        "contrato_id": 4,
        "fecha_inicio": date(2026, 1, 1),
        "fecha_termino": None,
        "sueldo_base": 500000,
        "estado": "VIGENTE",
    }
    assert evaluar_contrato(row, hoy=date(2026, 1, 15)) == []


def test_evaluar_liquidacion_sin_empleado():
    row = {
        "liquidacion_id": 10,
        "empleado_id": None,
        "sueldo_base": 500000,
        "horas_extras": 0,
        "sueldo_imponible": 500000,
        "sueldo_liquido": 400000,
        "costo_empresa": 550000,
    }
    findings = evaluar_liquidacion(row)
    reglas = {f.regla for f in findings}
    assert "liquidacion_sin_empleado" in reglas


def test_evaluar_liquidacion_monto_negativo():
    row = {
        "liquidacion_id": 11,
        "empleado_id": "EMP001",
        "sueldo_base": 500000,
        "horas_extras": -2,
        "sueldo_imponible": 500000,
        "sueldo_liquido": 400000,
        "costo_empresa": 550000,
    }
    findings = evaluar_liquidacion(row)
    reglas = {f.regla for f in findings}
    assert "monto_negativo" in reglas


def test_evaluar_liquidacion_ok_sin_hallazgos():
    row = {
        "liquidacion_id": 12,
        "empleado_id": "EMP001",
        "sueldo_base": 500000,
        "horas_extras": 2,
        "sueldo_imponible": 520000,
        "sueldo_liquido": 430000,
        "costo_empresa": 560000,
    }
    assert evaluar_liquidacion(row) == []


def test_finding_es_dataclass_comparable():
    a = Finding(entidad="Contrato", identificador=1, regla="x", severidad="ERROR")
    b = Finding(entidad="Contrato", identificador=1, regla="x", severidad="ERROR")
    assert a == b
