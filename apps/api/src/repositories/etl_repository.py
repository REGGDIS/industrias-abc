from __future__ import annotations

from src.core.audit_database import (
    get_audit_connection,
)


PROCESOS_DW = (
    "ETL_DW_ASISTENCIA",
    "ETL_DW_COMPRAS",
    "ETL_DW_CONTABILIDAD",
    "ETL_DW_CONTRATOS_REMUNERACIONES",
    "ETL_DW_PRODUCCION",
    "ETL_DW_RRHH",
)


def _serialize_execution(row):
    finished_at = row["finished_at"]
    started_at = row["started_at"]

    duration = None

    if (
        finished_at is not None
        and started_at is not None
    ):
        duration = round(
            (
                finished_at
                - started_at
            ).total_seconds(),
            3,
        )

    return {
        "executionId":
            int(row["execution_id"]),
        "source":
            row["source"],
        "process":
            row["process"],
        "startedAt":
            started_at,
        "finishedAt":
            finished_at,
        "duracionSegundos":
            duration,
        "recordsRead":
            int(row["records_read"] or 0),
        "recordsValid":
            int(row["records_valid"] or 0),
        "recordsInserted":
            int(row["records_inserted"] or 0),
        "recordsUpdated":
            int(row["records_updated"] or 0),
        "recordsUnchanged":
            int(row["records_unchanged"] or 0),
        "recordsRejected":
            int(row["records_rejected"] or 0),
        "recordsReview":
            int(row["records_review"] or 0),
        "status":
            row["status"],
        "message":
            row["message"],
    }


def obtener_resumen_etl():
    placeholders = ", ".join(
        ["%s"] * len(PROCESOS_DW)
    )

    with get_audit_connection() as connection:
        with connection.cursor() as cursor:

            cursor.execute(
                f"""
                SELECT DISTINCT ON (process)
                    execution_id,
                    source,
                    process,
                    started_at,
                    finished_at,
                    records_read,
                    records_valid,
                    records_inserted,
                    records_updated,
                    records_unchanged,
                    records_rejected,
                    records_review,
                    status,
                    message
                FROM etl_execution_log
                WHERE process IN (
                    {placeholders}
                )
                ORDER BY
                    process,
                    started_at DESC,
                    execution_id DESC;
                """,
                PROCESOS_DW,
            )

            latest_rows = cursor.fetchall()

            cursor.execute(
                f"""
                SELECT
                    execution_id,
                    source,
                    process,
                    started_at,
                    finished_at,
                    records_read,
                    records_valid,
                    records_inserted,
                    records_updated,
                    records_unchanged,
                    records_rejected,
                    records_review,
                    status,
                    message
                FROM etl_execution_log
                WHERE process IN (
                    {placeholders}
                )
                ORDER BY
                    started_at DESC,
                    execution_id DESC
                LIMIT 30;
                """,
                PROCESOS_DW,
            )

            history_rows = cursor.fetchall()

    latest = [
        _serialize_execution(row)
        for row in latest_rows
    ]

    latest.sort(
        key=lambda item:
            item["startedAt"],
        reverse=True,
    )

    history = [
        _serialize_execution(row)
        for row in history_rows
    ]

    success = sum(
        1
        for row in latest
        if row["status"] == "SUCCESS"
    )

    partial = sum(
        1
        for row in latest
        if row["status"] == "PARTIAL"
    )

    error = sum(
        1
        for row in latest
        if row["status"] == "ERROR"
    )

    running = sum(
        1
        for row in latest
        if row["status"] == "RUNNING"
    )

    registros_leidos = sum(
        row["recordsRead"]
        for row in latest
    )

    rechazados = sum(
        row["recordsRejected"]
        for row in latest
    )

    review = sum(
        row["recordsReview"]
        for row in latest
    )

    ultima_ejecucion = (
        max(
            (
                row["startedAt"]
                for row in latest
            ),
            default=None,
        )
    )

    return {
        "kpis": {
            "procesosMonitoreados":
                len(latest),
            "success":
                success,
            "partial":
                partial,
            "error":
                error,
            "running":
                running,
            "registrosLeidos":
                registros_leidos,
            "registrosRechazados":
                rechazados,
            "registrosReview":
                review,
            "ultimaEjecucion":
                ultima_ejecucion,
        },
        "ultimasEjecuciones":
            latest,
        "historial":
            history,
        "advertencias": [
            (
                "El panel considera únicamente "
                "los seis procesos ETL que cargan "
                "el Data Warehouse."
            ),
            (
                "Los registros de prueba de "
                "auditoría y los procesos históricos "
                "ETL_RRHH_EMPLEADOS no se incluyen "
                "en los KPI operacionales."
            ),
            (
                "Las métricas insertados, actualizados "
                "y sin cambios pueden involucrar "
                "dimensiones y hechos con distinta "
                "granularidad; no se suman ni se "
                "comparan directamente con los registros leídos."
            ),
        ],
    }
