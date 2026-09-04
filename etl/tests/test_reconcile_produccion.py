from datetime import date
from decimal import Decimal

import pytest

from etl.validate.produccion import (
    CsvConsumoProduccion,
    validate_csv_consumo,
)
from etl.validate.reconcile_produccion import (
    CSV_PATH,
    parse_date,
    read_csv_consumos,
)


def test_read_csv_consumos_real():
    rows = read_csv_consumos(CSV_PATH)

    assert len(rows) == 6

    first = rows[0]

    assert first.numero_orden == "OP-2026-0001"
    assert first.insumo_codigo_o_referencia == "INS-1001"
    assert first.cantidad_planificada == Decimal("500.00")
    assert first.cantidad_consumida == Decimal("495.00")
    assert first.fecha_consumo == date(2026, 8, 1)


def test_read_csv_rejects_missing_required_column(tmp_path):
    path = tmp_path / "consumos.csv"

    path.write_text(
        "numero_orden,insumo_codigo_o_referencia,"
        "cantidad_planificada,fecha_consumo\n"
        "OP-1,INS-1001,10,2026-08-01\n",
        encoding="utf-8",
    )

    with pytest.raises(
        ValueError,
        match="Faltan columnas requeridas",
    ):
        read_csv_consumos(path)


def test_read_csv_rejects_invalid_date(tmp_path):
    path = tmp_path / "consumos.csv"

    path.write_text(
        "numero_orden,insumo_codigo_o_referencia,"
        "cantidad_planificada,cantidad_consumida,fecha_consumo\n"
        "OP-1,INS-1001,10,9,fecha-invalida\n",
        encoding="utf-8",
    )

    with pytest.raises(
        ValueError,
        match="Error en CSV línea 2",
    ):
        read_csv_consumos(path)


def test_read_csv_rejects_invalid_decimal(tmp_path):
    path = tmp_path / "consumos.csv"

    path.write_text(
        "numero_orden,insumo_codigo_o_referencia,"
        "cantidad_planificada,cantidad_consumida,fecha_consumo\n"
        "OP-1,INS-1001,no-numero,9,2026-08-01\n",
        encoding="utf-8",
    )

    with pytest.raises(
        ValueError,
        match="Error en CSV línea 2",
    ):
        read_csv_consumos(path)


def test_validate_csv_detects_negative_quantities():
    row = CsvConsumoProduccion(
        numero_orden="OP-2026-0001",
        insumo_codigo_o_referencia="INS-1001",
        cantidad_planificada=Decimal("-1"),
        cantidad_consumida=Decimal("-2"),
        fecha_consumo=date(2026, 8, 1),
    )

    errors = validate_csv_consumo(row)

    assert "cantidad_planificada negativa" in errors
    assert "cantidad_consumida negativa" in errors


def test_validate_csv_detects_invalid_identifiers():
    row = CsvConsumoProduccion(
        numero_orden=" ",
        insumo_codigo_o_referencia="CODIGO-MALO",
        cantidad_planificada=Decimal("10"),
        cantidad_consumida=Decimal("9"),
        fecha_consumo=date(2026, 8, 1),
    )

    errors = validate_csv_consumo(row)

    assert "numero_orden vacío o inválido" in errors
    assert "insumo_codigo_o_referencia inválido" in errors


def test_parse_date_iso():
    assert parse_date("2026-08-18") == date(2026, 8, 18)


def test_validate_csv_detects_consumed_greater_than_planned():
    row = CsvConsumoProduccion(
        numero_orden="OP-2026-0001",
        insumo_codigo_o_referencia="INS-1001",
        cantidad_planificada=Decimal("100"),
        cantidad_consumida=Decimal("150"),
        fecha_consumo=date(2026, 8, 1),
    )

    errors = validate_csv_consumo(row)

    assert (
        "cantidad_consumida mayor que cantidad_planificada"
        in errors
    )
