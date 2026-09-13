from datetime import date
from decimal import Decimal

from etl.load.dw_produccion import (
    STAGING_SQL_DIR,
    enrich_consumos_with_csv,
    prepare_fact_consumo,
    prepare_fact_produccion,
    smart_date_key,
)


def test_smart_date_key_uses_zero_for_missing_date():
    assert smart_date_key(None) == 0
    assert smart_date_key(date(2026, 8, 1)) == 20260801


def test_enrich_consumo_with_unique_csv_match():
    mysql_rows = [
        {
            "consumo_id": 1,
            "orden_produccion_id": 1,
            "numero_orden": "OP-2026-0001",
            "insumo_id": 1001,
            "cantidad_planificada": Decimal("100.00"),
            "cantidad_consumida": Decimal("110.00"),
            "fecha_consumo": date(2026, 8, 1),
        }
    ]
    csv_rows = [
        {
            "numero_orden": "OP-2026-0001",
            "insumo_codigo_o_referencia": "INS-1001",
            "cantidad_planificada": Decimal("100.00"),
            "cantidad_consumida": Decimal("110.00"),
            "fecha_consumo": date(2026, 8, 1),
        }
    ]

    enriched, mysql_review, csv_review = enrich_consumos_with_csv(
        mysql_rows,
        csv_rows,
    )

    assert enriched[0]["insumo_codigo_origen"] == "INS-1001"
    assert enriched[0]["csv_match_status"] == "MATCH"
    assert mysql_review == 0
    assert csv_review == 0


def test_enrich_consumo_without_csv_keeps_local_traceability():
    mysql_rows = [
        {
            "consumo_id": 5,
            "orden_produccion_id": 4,
            "numero_orden": "OP-2026-0004",
            "insumo_id": 1005,
            "cantidad_planificada": Decimal("200.00"),
            "cantidad_consumida": Decimal("198.00"),
            "fecha_consumo": date(2026, 8, 9),
        }
    ]

    enriched, mysql_review, csv_review = enrich_consumos_with_csv(
        mysql_rows,
        [],
    )

    assert enriched[0]["insumo_codigo_origen"] == "ID_LOCAL:1005"
    assert enriched[0]["csv_match_status"] == "CSV_NO_MATCH"
    assert mysql_review == 1
    assert csv_review == 0


def test_staging_consumo_allows_overconsumption():
    sql = (
        STAGING_SQL_DIR / "limpiar_consumo_insumos.sql"
    ).read_text(encoding="utf-8").lower()

    assert "cantidad_consumida <= ci.cantidad_planificada" not in sql
    assert "ci.cantidad_consumida >= 0" in sql


def test_prepare_fact_produccion_uses_zero_for_open_order_and_unmapped_cc():
    rows = [
        {
            "numero_orden": "OP-1",
            "producto_id": 1,
            "fecha_inicio": date(2026, 8, 1),
            "fecha_termino": None,
            "cantidad_planificada": Decimal("100"),
            "cantidad_producida": Decimal("50"),
            "cantidad_rechazada": Decimal("0"),
            "estado": "EN_PROCESO",
            "centro_costo_id": 101,
        }
    ]
    contracts = {
        "productos": {"PROD-001": 10},
        "centros": {"CC005": 5},
        "areas": {"A05": 5},
        "insumos": {},
        "fechas": {0, 20260801},
    }

    prepared, review = prepare_fact_produccion(
        rows,
        {1: "PROD-001"},
        contracts,
        center_mapping={},
    )

    assert prepared[0]["producto_key"] == 10
    assert prepared[0]["fecha_termino_key"] == 0
    assert prepared[0]["centro_costo_key"] == 0
    assert prepared[0]["area_key"] == 0
    assert review == 1


def test_prepare_fact_consumo_keeps_overconsumption_and_unknown_insumo():
    rows = [
        {
            "consumo_id": 10,
            "numero_orden": "OP-1",
            "insumo_codigo_origen": "INS-1001",
            "csv_match_status": "MATCH",
            "cantidad_planificada": Decimal("100"),
            "cantidad_consumida": Decimal("110"),
            "fecha_consumo": date(2026, 8, 1),
        }
    ]
    orders = {
        "OP-1": {
            "producto_key": 10,
            "centro_costo_key": 0,
            "area_key": 0,
        }
    }
    contracts = {
        "insumos": {},
        "fechas": {0, 20260801},
    }

    prepared, review = prepare_fact_consumo(
        rows,
        orders,
        contracts,
        insumo_mapping={},
    )

    assert prepared[0]["cantidad_planificada"] == Decimal("100")
    assert prepared[0]["cantidad_consumida"] == Decimal("110")
    assert prepared[0]["insumo_key"] == 0
    assert prepared[0]["insumo_codigo_origen"] == "INS-1001"
    assert review == 1
