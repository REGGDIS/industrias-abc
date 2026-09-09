from __future__ import annotations

from dataclasses import dataclass
from datetime import date

from etl.validate.produccion import (
    ConsumoMysqlProduccion,
    CsvConsumoProduccion,
    normalize_insumo_reference,
    normalize_order_number,
    reconcile_consumos,
    validate_csv_consumo,
)


INFO = "INFO"
WARNING = "WARNING"
ERROR = "ERROR"


@dataclass(frozen=True)
class QualityFinding:
    row_number: int
    business_key: tuple[str | None, int | None, date]
    rule: str
    severity: str
    detail: str


@dataclass(frozen=True)
class QualitySummary:
    rows_processed: int
    valid_rows: int
    exact_duplicates: int
    key_duplicates: int
    rows_with_error: int
    rows_with_warning: int
    findings: tuple[QualityFinding, ...]


def build_business_key(
    row: CsvConsumoProduccion,
) -> tuple[str | None, int | None, date]:
    return (
        normalize_order_number(row.numero_orden),
        normalize_insumo_reference(row.insumo_codigo_o_referencia),
        row.fecha_consumo,
    )


def detect_exact_duplicates(
    rows: list[CsvConsumoProduccion],
) -> list[QualityFinding]:
    findings: list[QualityFinding] = []
    seen: dict[CsvConsumoProduccion, int] = {}

    for row_number, row in enumerate(rows, start=2):
        first_row = seen.get(row)

        if first_row is not None:
            findings.append(
                QualityFinding(
                    row_number=row_number,
                    business_key=build_business_key(row),
                    rule="DUPLICADO_EXACTO_CSV",
                    severity=ERROR,
                    detail=(
                        "Fila duplicada exactamente respecto "
                        f"a la fila {first_row}"
                    ),
                )
            )
        else:
            seen[row] = row_number

    return findings


def detect_key_duplicates(
    rows: list[CsvConsumoProduccion],
) -> list[QualityFinding]:
    findings: list[QualityFinding] = []
    seen: dict[tuple[str | None, int | None, date], int] = {}

    for row_number, row in enumerate(rows, start=2):
        key = build_business_key(row)
        first_row = seen.get(key)

        if first_row is not None:
            findings.append(
                QualityFinding(
                    row_number=row_number,
                    business_key=key,
                    rule="DUPLICADO_POR_CLAVE",
                    severity=ERROR,
                    detail=(
                        "Repetición de "
                        "numero_orden + insumo_codigo_o_referencia "
                        f"+ fecha_consumo respecto a la fila {first_row}"
                    ),
                )
            )
        else:
            seen[key] = row_number

    return findings


def profile_quality(
    rows: list[CsvConsumoProduccion],
    mysql_rows: list[ConsumoMysqlProduccion] | None = None,
) -> QualitySummary:
    exact_duplicates = detect_exact_duplicates(rows)
    key_duplicates = detect_key_duplicates(rows)

    findings: list[QualityFinding] = []
    findings.extend(exact_duplicates)
    findings.extend(key_duplicates)

    rows_with_error: set[int] = {
        finding.row_number
        for finding in findings
        if finding.severity == ERROR
    }

    rows_with_warning: set[int] = {
        finding.row_number
        for finding in findings
        if finding.severity == WARNING
    }

    for row_number, row in enumerate(rows, start=2):
        errors = validate_csv_consumo(row)

        if errors:
            finding = QualityFinding(
                row_number=row_number,
                business_key=build_business_key(row),
                rule="VALIDACION_CSV",
                severity=ERROR,
                detail="; ".join(errors),
            )

            findings.append(finding)
            rows_with_error.add(row_number)

    if mysql_rows is not None:
        reconciliation_results = reconcile_consumos(
            rows,
            mysql_rows,
        )

        for row_number, result in enumerate(
            reconciliation_results,
            start=2,
        ):
            # Si la fila ya tiene un ERROR de calidad,
            # ese estado tiene prioridad sobre cualquier WARNING.
            if row_number in rows_with_error:
                continue

            if result.status == "NO_MATCH":
                finding = QualityFinding(
                    row_number=row_number,
                    business_key=build_business_key(result.csv_row),
                    rule="NO_MATCH",
                    severity=WARNING,
                    detail=result.detail,
                )

                findings.append(finding)
                rows_with_warning.add(row_number)

            elif result.status == "REVIEW":
                finding = QualityFinding(
                    row_number=row_number,
                    business_key=build_business_key(result.csv_row),
                    rule="RECONCILIACION_REVIEW",
                    severity=WARNING,
                    detail=result.detail,
                )

                findings.append(finding)
                rows_with_warning.add(row_number)

    # Las categorías del resumen deben ser mutuamente excluyentes.
    rows_with_warning.difference_update(rows_with_error)

    rows_invalid_or_review = rows_with_error | rows_with_warning

    valid_rows = len(rows) - len(rows_invalid_or_review)

    if valid_rows < 0:
        raise ValueError(
            "El resumen de profiling no puede tener "
            "filas válidas negativas"
        )

    summary = QualitySummary(
        rows_processed=len(rows),
        valid_rows=valid_rows,
        exact_duplicates=len(exact_duplicates),
        key_duplicates=len(key_duplicates),
        rows_with_error=len(rows_with_error),
        rows_with_warning=len(rows_with_warning),
        findings=tuple(findings),
    )

    if (
        summary.valid_rows
        + summary.rows_with_error
        + summary.rows_with_warning
        != summary.rows_processed
    ):
        raise ValueError(
            "El resumen de profiling debe reconciliar "
            "con el total de filas procesadas"
        )

    return summary
