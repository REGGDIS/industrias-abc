from __future__ import annotations

import tempfile
from pathlib import Path
from uuid import uuid4

from etl.audit.logger import finish_execution, start_execution
from etl.load.dw_compras import run_dw_compras
from etl.validate.compras.runner import SQL_VALIDATE, run as run_source_validation


SOURCE = "COMPRAS"
PROCESS = "ETL_DW_COMPRAS"


def _validate_source() -> dict:
    output = Path(tempfile.gettempdir()) / f"compras_dw_{uuid4()}.json"
    try:
        report = run_source_validation(
            output,
            stages=[
                (
                    "validaciones_calidad",
                    SQL_VALIDATE / "validaciones_calidad_compras.sql",
                )
            ],
        )
    finally:
        output.unlink(missing_ok=True)

    if report["status"] != "OK" or report["errores"] > 0:
        raise ValueError(
            "Compras fuente no supera los controles de calidad transaccional vigentes."
        )
    return report


def run() -> dict:
    execution_id = start_execution(SOURCE, PROCESS)
    try:
        source_validation = _validate_source()
        result = run_dw_compras()

        records_read = sum(result["source"].values())
        source_review = int(source_validation.get("review", 0))
        loader_review = len(result["review"])
        records_rejected = len(result["rejected"])
        records_review = source_review + loader_review
        records_valid = max(0, records_read - records_rejected - records_review)

        metrics = [
            result["dim_proveedor"],
            result["dim_insumo"],
            result["fact_compras"],
        ]
        records_inserted = sum(m["inserted"] for m in metrics)
        records_updated = sum(m["updated"] for m in metrics)
        records_unchanged = sum(m["unchanged"] for m in metrics)

        status = "PARTIAL" if records_rejected or records_review else "SUCCESS"
        message = (
            "ETL Compras -> DW ejecutado. "
            f"SOURCE_REVIEW={source_review} "
            f"DW_REVIEW={loader_review} REJECTED={records_rejected}."
        )

        finish_execution(
            execution_id,
            records_read,
            records_valid,
            records_rejected,
            status,
            message,
            records_inserted=records_inserted,
            records_updated=records_updated,
            records_unchanged=records_unchanged,
            records_review=records_review,
        )

        return {
            "execution_id": execution_id,
            "status": status,
            "records_read": records_read,
            "records_valid": records_valid,
            "records_rejected": records_rejected,
            "records_review": records_review,
            "records_inserted": records_inserted,
            "records_updated": records_updated,
            "records_unchanged": records_unchanged,
            "source": result["source"],
            "source_validation": {
                "procesados": source_validation["procesados"],
                "validos": source_validation["validos"],
                "review": source_validation["review"],
                "errores": source_validation["errores"],
            },
            "dim_proveedor": result["dim_proveedor"],
            "dim_insumo": result["dim_insumo"],
            "fact_compras": result["fact_compras"],
            "prepared_facts": result["prepared_facts"],
            "rejected": result["rejected"],
            "review": result["review"],
        }
    except Exception as exc:
        finish_execution(
            execution_id,
            0,
            0,
            0,
            "ERROR",
            f"ETL Compras -> DW falló: {type(exc).__name__}: {exc}",
        )
        raise


if __name__ == "__main__":
    print(run())
