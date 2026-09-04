from __future__ import annotations

from dataclasses import dataclass
from datetime import date
from decimal import Decimal, InvalidOperation


@dataclass(frozen=True)
class CsvConsumoProduccion:
    numero_orden: str
    insumo_codigo_o_referencia: str
    cantidad_planificada: Decimal
    cantidad_consumida: Decimal
    fecha_consumo: date


@dataclass(frozen=True)
class ConsumoMysqlProduccion:
    orden_produccion_id: int
    numero_orden: str
    insumo_id: int
    cantidad_planificada: Decimal
    cantidad_consumida: Decimal
    fecha_consumo: date


@dataclass(frozen=True)
class ReconciliationResult:
    csv_row: CsvConsumoProduccion
    mysql_row: ConsumoMysqlProduccion | None
    status: str
    detail: str


def normalize_order_number(value: str | None) -> str | None:
    if value is None:
        return None

    normalized = value.strip().upper()

    if not normalized:
        return None

    return normalized


def normalize_insumo_reference(value: str | None) -> int | None:
    if value is None:
        return None

    normalized = value.strip().upper()

    if not normalized:
        return None

    if normalized.startswith("INS-"):
        normalized = normalized[4:]

    if not normalized.isdigit():
        return None

    return int(normalized)


def parse_decimal(value: str | int | float | Decimal) -> Decimal:
    try:
        return Decimal(str(value).strip())
    except (InvalidOperation, ValueError, AttributeError) as exc:
        raise ValueError(f"Valor decimal inválido: {value!r}") from exc


def validate_csv_consumo(row: CsvConsumoProduccion) -> list[str]:
    errors: list[str] = []

    if normalize_order_number(row.numero_orden) is None:
        errors.append("numero_orden vacío o inválido")

    if normalize_insumo_reference(row.insumo_codigo_o_referencia) is None:
        errors.append("insumo_codigo_o_referencia inválido")

    if row.cantidad_planificada < 0:
        errors.append("cantidad_planificada negativa")

    if row.cantidad_consumida < 0:
        errors.append("cantidad_consumida negativa")

    return errors


def reconcile_consumos(
    csv_rows: list[CsvConsumoProduccion],
    mysql_rows: list[ConsumoMysqlProduccion],
) -> list[ReconciliationResult]:
    index: dict[tuple[str, int], list[ConsumoMysqlProduccion]] = {}

    for mysql_row in mysql_rows:
        key = (
            normalize_order_number(mysql_row.numero_orden),
            mysql_row.insumo_id,
        )

        index.setdefault(key, []).append(mysql_row)

    results: list[ReconciliationResult] = []

    for csv_row in csv_rows:
        errors = validate_csv_consumo(csv_row)

        if errors:
            results.append(
                ReconciliationResult(
                    csv_row=csv_row,
                    mysql_row=None,
                    status="REVIEW",
                    detail="; ".join(errors),
                )
            )
            continue

        numero_orden = normalize_order_number(csv_row.numero_orden)
        insumo_id = normalize_insumo_reference(
            csv_row.insumo_codigo_o_referencia
        )

        matches = index.get(
            (numero_orden, insumo_id),
            [],
        )

        if len(matches) == 0:
            results.append(
                ReconciliationResult(
                    csv_row=csv_row,
                    mysql_row=None,
                    status="NO_MATCH",
                    detail="No existe consumo equivalente en MySQL",
                )
            )
            continue

        if len(matches) > 1:
            results.append(
                ReconciliationResult(
                    csv_row=csv_row,
                    mysql_row=None,
                    status="REVIEW",
                    detail="Más de un consumo MySQL coincide con orden e insumo",
                )
            )
            continue

        mysql_row = matches[0]

        differences: list[str] = []

        if csv_row.cantidad_planificada != mysql_row.cantidad_planificada:
            differences.append("cantidad_planificada")

        if csv_row.cantidad_consumida != mysql_row.cantidad_consumida:
            differences.append("cantidad_consumida")

        if csv_row.fecha_consumo != mysql_row.fecha_consumo:
            differences.append("fecha_consumo")

        if differences:
            results.append(
                ReconciliationResult(
                    csv_row=csv_row,
                    mysql_row=mysql_row,
                    status="REVIEW",
                    detail=(
                        "Diferencias en: "
                        + ", ".join(differences)
                    ),
                )
            )
            continue

        results.append(
            ReconciliationResult(
                csv_row=csv_row,
                mysql_row=mysql_row,
                status="MATCH",
                detail="Coincidencia completa",
            )
        )

    return results
