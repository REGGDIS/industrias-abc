from datetime import date
from decimal import Decimal

from etl.validate.produccion import (
    ConsumoMysqlProduccion,
    CsvConsumoProduccion,
    normalize_insumo_reference,
    reconcile_consumos,
)


def test_normalize_insumo_reference():
    assert normalize_insumo_reference("INS-1001") == 1001
    assert normalize_insumo_reference(" ins-1006 ") == 1006
    assert normalize_insumo_reference("1003") == 1003
    assert normalize_insumo_reference("") is None
    assert normalize_insumo_reference("ABC") is None


def test_reconcile_consumo_match():
    csv_rows = [
        CsvConsumoProduccion(
            numero_orden="OP-2026-0001",
            insumo_codigo_o_referencia="INS-1001",
            cantidad_planificada=Decimal("500.00"),
            cantidad_consumida=Decimal("495.00"),
            fecha_consumo=date(2026, 8, 1),
        )
    ]

    mysql_rows = [
        ConsumoMysqlProduccion(
            orden_produccion_id=1,
            numero_orden="OP-2026-0001",
            insumo_id=1001,
            cantidad_planificada=Decimal("500.00"),
            cantidad_consumida=Decimal("495.00"),
            fecha_consumo=date(2026, 8, 1),
        )
    ]

    results = reconcile_consumos(csv_rows, mysql_rows)

    assert len(results) == 1
    assert results[0].status == "MATCH"


def test_reconcile_consumo_no_match():
    csv_rows = [
        CsvConsumoProduccion(
            numero_orden="OP-2026-9999",
            insumo_codigo_o_referencia="INS-9999",
            cantidad_planificada=Decimal("10.00"),
            cantidad_consumida=Decimal("9.00"),
            fecha_consumo=date(2026, 8, 1),
        )
    ]

    results = reconcile_consumos(
        csv_rows,
        [],
    )

    assert len(results) == 1
    assert results[0].status == "NO_MATCH"


def test_reconcile_consumo_difference_requires_review():
    csv_rows = [
        CsvConsumoProduccion(
            numero_orden="OP-2026-0001",
            insumo_codigo_o_referencia="INS-1001",
            cantidad_planificada=Decimal("500.00"),
            cantidad_consumida=Decimal("490.00"),
            fecha_consumo=date(2026, 8, 1),
        )
    ]

    mysql_rows = [
        ConsumoMysqlProduccion(
            orden_produccion_id=1,
            numero_orden="OP-2026-0001",
            insumo_id=1001,
            cantidad_planificada=Decimal("500.00"),
            cantidad_consumida=Decimal("495.00"),
            fecha_consumo=date(2026, 8, 1),
        )
    ]

    results = reconcile_consumos(
        csv_rows,
        mysql_rows,
    )

    assert len(results) == 1
    assert results[0].status == "REVIEW"
    assert "cantidad_consumida" in results[0].detail
