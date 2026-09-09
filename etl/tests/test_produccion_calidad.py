from datetime import date
from decimal import Decimal

from etl.validate.produccion import (
    ConsumoMysqlProduccion,
    CsvConsumoProduccion,
)
from etl.validate.produccion_calidad import (
    ERROR,
    WARNING,
    profile_quality,
)


def make_row(
    numero_orden: str = "OP-001",
    insumo: str = "INS-101",
    cantidad_planificada: str = "10",
    cantidad_consumida: str = "5",
    fecha: date = date(2026, 1, 10),
) -> CsvConsumoProduccion:
    return CsvConsumoProduccion(
        numero_orden=numero_orden,
        insumo_codigo_o_referencia=insumo,
        cantidad_planificada=Decimal(cantidad_planificada),
        cantidad_consumida=Decimal(cantidad_consumida),
        fecha_consumo=fecha,
    )


def make_mysql_row(
    orden_produccion_id: int = 1,
    numero_orden: str = "OP-001",
    insumo_id: int = 101,
    cantidad_planificada: str = "10",
    cantidad_consumida: str = "5",
    fecha_consumo: date = date(2026, 1, 10),
) -> ConsumoMysqlProduccion:
    return ConsumoMysqlProduccion(
        orden_produccion_id=orden_produccion_id,
        numero_orden=numero_orden,
        insumo_id=insumo_id,
        cantidad_planificada=Decimal(cantidad_planificada),
        cantidad_consumida=Decimal(cantidad_consumida),
        fecha_consumo=fecha_consumo,
    )


def test_detecta_duplicado_exacto_como_error():
    row = make_row()

    summary = profile_quality([row, row])

    assert summary.rows_processed == 2
    assert summary.exact_duplicates == 1
    assert summary.key_duplicates == 1
    assert summary.rows_with_error == 1

    finding = next(
        finding
        for finding in summary.findings
        if finding.rule == "DUPLICADO_EXACTO_CSV"
    )

    assert finding.severity == ERROR
    assert finding.row_number == 3


def test_detecta_duplicado_por_clave_de_negocio_como_error():
    first = make_row(cantidad_consumida="5")
    second = make_row(cantidad_consumida="7")

    summary = profile_quality([first, second])

    assert summary.rows_processed == 2
    assert summary.exact_duplicates == 0
    assert summary.key_duplicates == 1
    assert summary.rows_with_error == 1

    finding = next(
        finding
        for finding in summary.findings
        if finding.rule == "DUPLICADO_POR_CLAVE"
    )

    assert finding.severity == ERROR
    assert finding.row_number == 3


def test_detecta_consumo_mayor_que_planificado_como_error():
    row = make_row(
        cantidad_planificada="10",
        cantidad_consumida="12",
    )

    summary = profile_quality([row])

    assert summary.rows_processed == 1
    assert summary.rows_with_error == 1

    finding = next(
        finding
        for finding in summary.findings
        if finding.rule == "VALIDACION_CSV"
    )

    assert finding.severity == ERROR
    assert "cantidad_consumida mayor que cantidad_planificada" in finding.detail


def test_fila_sin_match_se_clasifica_como_warning():
    row = make_row()

    mysql_rows: list[ConsumoMysqlProduccion] = []

    summary = profile_quality(
        [row],
        mysql_rows,
    )

    finding = next(
        finding
        for finding in summary.findings
        if finding.rule == "NO_MATCH"
    )

    assert finding.severity == WARNING
    assert finding.row_number == 2
    assert "No existe" in finding.detail

    assert summary.rows_processed == 1
    assert summary.rows_with_warning == 1
    assert summary.rows_with_error == 0
    assert summary.valid_rows == 0


def test_fila_con_match_no_genera_warning():
    row = make_row()

    mysql_rows = [
        make_mysql_row(),
    ]

    summary = profile_quality(
        [row],
        mysql_rows,
    )

    assert summary.rows_processed == 1
    assert summary.rows_with_warning == 0
    assert summary.rows_with_error == 0
    assert summary.valid_rows == 1

    assert not any(
        finding.rule == "NO_MATCH"
        for finding in summary.findings
    )


def test_resumen_reconcilia_con_filas_procesadas():
    rows = [
        make_row(),
        make_row(
            numero_orden="OP-002",
            insumo="INS-102",
        ),
    ]

    summary = profile_quality(rows)

    assert summary.rows_processed == 2
    assert (
        summary.valid_rows
        + summary.rows_with_error
        + summary.rows_with_warning
        == summary.rows_processed
    )


def test_cada_hallazgo_tiene_regla_severidad_y_detalle():
    row = make_row(
        cantidad_planificada="10",
        cantidad_consumida="12",
    )

    summary = profile_quality([row])

    assert summary.findings

    for finding in summary.findings:
        assert finding.rule
        assert finding.severity
        assert finding.detail


def test_review_de_reconciliacion_se_clasifica_como_warning():
    row = make_row()

    mysql_rows = [
        make_mysql_row(
            cantidad_consumida="7",
        ),
    ]

    summary = profile_quality(
        [row],
        mysql_rows,
    )

    finding = next(
        finding
        for finding in summary.findings
        if finding.rule == "RECONCILIACION_REVIEW"
    )

    assert finding.severity == WARNING
    assert summary.rows_processed == 1
    assert summary.rows_with_warning == 1
    assert summary.rows_with_error == 0
    assert summary.valid_rows == 0


def test_error_tiene_prioridad_sobre_warning_en_resumen():
    row = make_row(
        cantidad_planificada="10",
        cantidad_consumida="12",
    )

    mysql_rows: list[ConsumoMysqlProduccion] = []

    summary = profile_quality(
        [row],
        mysql_rows,
    )

    assert summary.rows_processed == 1
    assert summary.rows_with_error == 1
    assert summary.rows_with_warning == 0
    assert summary.valid_rows == 0

    assert (
        summary.valid_rows
        + summary.rows_with_error
        + summary.rows_with_warning
        == summary.rows_processed
    )
