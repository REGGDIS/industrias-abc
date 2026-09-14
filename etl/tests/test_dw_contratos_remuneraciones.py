from datetime import date
from decimal import Decimal

from etl.load.dw_contratos_remuneraciones import (
    _canonical_rut,
    _period_date,
    _resolve_employee,
    build_contract_rows,
    build_fact_rows,
)


def test_canonical_rut_normaliza_puntos_y_guion():
    assert _canonical_rut("12.345.678-5") == "12345678-5"


def test_canonical_rut_inserta_guion_si_falta():
    assert _canonical_rut("123456785") == "12345678-5"


def test_period_date_usa_primer_dia_del_mes():
    assert _period_date("2025-07") == date(2025, 7, 1)


def test_resolve_employee_respeta_intervalo_semiabierto():
    versions = [
        {
            "empleado_key": 10,
            "area_key": 1,
            "cargo_key": 2,
            "centro_costo_key": 3,
            "fecha_desde": date(2025, 1, 1),
            "fecha_hasta": date(2025, 6, 1),
        },
        {
            "empleado_key": 11,
            "area_key": 4,
            "cargo_key": 5,
            "centro_costo_key": 6,
            "fecha_desde": date(2025, 6, 1),
            "fecha_hasta": None,
        },
    ]
    assert _resolve_employee(versions, date(2025, 5, 31))["empleado_key"] == 10
    assert _resolve_employee(versions, date(2025, 6, 1))["empleado_key"] == 11


def test_resolve_employee_devuelve_none_si_hay_ambiguedad():
    versions = [
        {"empleado_key": 1, "fecha_desde": date(2025, 1, 1), "fecha_hasta": None},
        {"empleado_key": 2, "fecha_desde": date(2025, 1, 1), "fecha_hasta": None},
    ]
    assert _resolve_employee(versions, date(2025, 2, 1)) is None


def _base_data():
    return {
        "empleados": [
            {
                "empleado_id": "E001",
                "rut_referencia": "12.345.678-5",
                "codigo_cargo_ref": "CAR001",
            }
        ],
        "contratos": [
            {
                "contrato_id": 1,
                "empleado_id": "E001",
                "numero_contrato": "CT-001",
                "tipo_contrato": "INDEFINIDO",
                "fecha_inicio": date(2025, 1, 1),
                "fecha_termino": None,
                "jornada": "COMPLETA",
                "sueldo_base": Decimal("1000000.00"),
                "cargo_contrato": "Analista",
                "estado": "VIGENTE",
            }
        ],
        "liquidaciones": [
            {
                "liquidacion_id": 101,
                "empleado_id": "E001",
                "contrato_id": 1,
                "periodo": "2025-01",
                "sueldo_base": Decimal("1000000.00"),
                "horas_extras": Decimal("2.00"),
                "sueldo_imponible": Decimal("1100000.00"),
                "sueldo_liquido": Decimal("900000.00"),
                "costo_empresa": Decimal("1200000.00"),
            }
        ],
        "conceptos": [
            {"concepto_id": 1, "tipo": "HABER"},
            {"concepto_id": 2, "tipo": "DESCUENTO"},
            {"concepto_id": 3, "tipo": "APORTE"},
        ],
        "detalles": [
            {"liquidacion_id": 101, "concepto_id": 1, "monto": Decimal("1100000.00")},
            {"liquidacion_id": 101, "concepto_id": 2, "monto": Decimal("200000.00")},
            {"liquidacion_id": 101, "concepto_id": 3, "monto": Decimal("100000.00")},
        ],
    }


def _context():
    return {
        "empleados": {
            "12345678-5": [
                {
                    "empleado_key": 10,
                    "area_key": 20,
                    "cargo_key": 30,
                    "centro_costo_key": 40,
                    "fecha_desde": date(2024, 1, 1),
                    "fecha_hasta": None,
                }
            ]
        },
        "fechas": {date(2025, 1, 1): 20250101},
        "cargos": {"CAR001": 30},
        "contratos": {"CT-001": 50},
    }


def test_build_contract_rows_resuelve_empleado_y_cargo():
    rows, review = build_contract_rows(_base_data(), _context())
    assert len(rows) == 1
    assert review == []
    assert rows[0]["empleado_key"] == 10
    assert rows[0]["cargo_key"] == 30


def test_build_fact_rows_usa_contexto_scd2_y_agrega_detalle():
    rows, rejected, review = build_fact_rows(_base_data(), _context())
    assert rejected == []
    assert review == []
    assert len(rows) == 1
    row = rows[0]
    assert row["empleado_key"] == 10
    assert row["area_key"] == 20
    assert row["cargo_key"] == 30
    assert row["centro_costo_key"] == 40
    assert row["contrato_key"] == 50
    assert row["total_haberes"] == Decimal("1100000.00")
    assert row["total_descuentos"] == Decimal("200000.00")
    assert row["total_aportes"] == Decimal("100000.00")


def test_build_fact_rows_rechaza_fecha_fuera_de_dim_fecha():
    context = _context()
    context["fechas"] = {}
    rows, rejected, review = build_fact_rows(_base_data(), context)
    assert rows == []
    assert review == []
    assert rejected == [{"liquidacion_id": 101, "regla": "FECHA_NO_RESUELTA"}]
