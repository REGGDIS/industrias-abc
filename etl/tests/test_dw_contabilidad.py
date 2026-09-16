from datetime import date
from decimal import Decimal

from etl.load.dw_contabilidad import (
    _money,
    build_dim_cuenta_rows,
    build_fact_rows,
)


def sample_data():
    return {
        "areas": [
            {"area_id": 1, "codigo_area": "A01", "nombre_area": "Administración"},
        ],
        "centros_costo": [
            {
                "centro_costo_id": 10,
                "codigo": "CC001",
                "nombre": "Administración General",
                "area_id": 1,
                "responsable": None,
                "estado": "ACTIVO",
            }
        ],
        "cuentas_contables": [
            {
                "cuenta_id": 1,
                "codigo_cuenta": "5",
                "nombre_cuenta": "COSTOS Y GASTOS",
                "tipo_cuenta": "GASTOS",
                "grupo": "GASTOS OPERACIONALES",
                "nivel": 1,
                "cuenta_padre_id": None,
                "estado": "ACTIVA",
            },
            {
                "cuenta_id": 2,
                "codigo_cuenta": "5.2",
                "nombre_cuenta": "GASTOS DE ADMINISTRACIÓN",
                "tipo_cuenta": "GASTOS",
                "grupo": "GASTOS",
                "nivel": 2,
                "cuenta_padre_id": 1,
                "estado": "ACTIVA",
            },
        ],
        "movimientos_contables": [
            {
                "movimiento_id": 100,
                "fecha": date(2025, 1, 30),
                "cuenta_id": 2,
                "centro_costo_id": 10,
                "documento_tipo": "FACTURA",
                "documento_numero": "FAC-1",
                "descripcion": "Servicio administrativo",
                "debe": Decimal("100.00"),
                "haber": Decimal("0.00"),
                "moneda": "CLP",
                "tipo_cambio": Decimal("1.0000"),
            }
        ],
    }


def sample_maps():
    return {
        "fechas": {date(2025, 1, 30): 20250130},
        "cuentas": {"5.2": 12},
        "areas": {"A01": 1},
        "centros": {"CC001": 1},
    }


def test_money_conserva_dos_decimales():
    assert _money("10.125") == Decimal("10.13")


def test_dim_cuenta_reemplaza_id_padre_por_business_key():
    rows = build_dim_cuenta_rows(sample_data()["cuentas_contables"])
    assert rows[0]["codigo_cuenta_padre"] is None
    assert rows[1]["codigo_cuenta_padre"] == "5"


def test_dim_cuenta_no_expone_ids_locales():
    rows = build_dim_cuenta_rows(sample_data()["cuentas_contables"])
    assert "cuenta_id" not in rows[1]
    assert "cuenta_padre_id" not in rows[1]


def test_fact_resuelve_claves_conformadas():
    rows, rejected, review = build_fact_rows(sample_data(), sample_maps())
    assert rejected == []
    assert review == []
    fact = rows[0]
    assert fact["fecha_key"] == 20250130
    assert fact["cuenta_key"] == 12
    assert fact["area_key"] == 1
    assert fact["centro_costo_key"] == 1


def test_fact_calcula_saldo_deudor():
    rows, _, _ = build_fact_rows(sample_data(), sample_maps())
    fact = rows[0]
    assert fact["debe"] == Decimal("100.00")
    assert fact["haber"] == Decimal("0.00")
    assert fact["saldo"] == Decimal("100.00")


def test_fact_calcula_saldo_acreedor():
    data = sample_data()
    data["movimientos_contables"][0]["debe"] = Decimal("0.00")
    data["movimientos_contables"][0]["haber"] = Decimal("100.00")
    rows, _, _ = build_fact_rows(data, sample_maps())
    assert rows[0]["saldo"] == Decimal("-100.00")


def test_fact_convierte_moneda_con_tipo_cambio():
    data = sample_data()
    movimiento = data["movimientos_contables"][0]
    movimiento["moneda"] = "USD"
    movimiento["debe"] = Decimal("10.00")
    movimiento["tipo_cambio"] = Decimal("950.5000")
    rows, _, _ = build_fact_rows(data, sample_maps())
    assert rows[0]["debe_origen"] == Decimal("10.00")
    assert rows[0]["debe"] == Decimal("9505.00")


def test_fecha_no_resuelta_rechaza_movimiento():
    maps = sample_maps()
    maps["fechas"] = {}
    rows, rejected, review = build_fact_rows(sample_data(), maps)
    assert rows == []
    assert review == []
    assert rejected[0]["regla"] == "FECHA_NO_RESUELTA"


def test_dimension_no_resuelta_usa_miembro_cero_y_review():
    maps = sample_maps()
    maps["centros"] = {}
    rows, rejected, review = build_fact_rows(sample_data(), maps)
    assert rejected == []
    assert rows[0]["centro_costo_key"] == 0
    assert review[0]["reglas"] == ["CENTRO_COSTO_NO_RESUELTO"]


def test_grano_fact_conserva_movimiento_id_solo_como_trazabilidad():
    rows, _, _ = build_fact_rows(sample_data(), sample_maps())
    fact = rows[0]
    assert fact["movimiento_id_origen"] == 100
    assert "cuenta_id" not in fact
    assert "centro_costo_id" not in fact
