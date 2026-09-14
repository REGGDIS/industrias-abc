from __future__ import annotations

from etl.audit.logger import finish_execution, start_execution
from etl.load.dw_contabilidad import run_dw_contabilidad


SOURCE = "CONTABILIDAD"
PROCESS = "ETL_DW_CONTABILIDAD"


def run() -> dict:
    execution_id = start_execution(SOURCE, PROCESS)

    try:
        result = run_dw_contabilidad()

        records_read = sum(result["source"].values())
        records_valid = result["source_validation"]["validos"]
        records_rejected = len(result["rejected"])
        records_review = len(result["review"])

        records_inserted = (
            result["dim_cuenta_contable"]["inserted"]
            + result["fact_contabilidad"]["inserted"]
        )
        records_updated = (
            result["dim_cuenta_contable"]["updated"]
            + result["fact_contabilidad"]["updated"]
        )
        records_unchanged = (
            result["dim_cuenta_contable"]["unchanged"]
            + result["fact_contabilidad"]["unchanged"]
        )

        status = "PARTIAL" if records_rejected or records_review else "SUCCESS"
        message = (
            "ETL Contabilidad -> DW ejecutado. "
            f"REVIEW={records_review} REJECTED={records_rejected}."
        )

        finish_execution(
            execution_id,
            records_read=records_read,
            records_valid=records_valid,
            records_rejected=records_rejected,
            status=status,
            message=message,
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
            **result,
        }

    except Exception as exc:
        finish_execution(
            execution_id,
            records_read=0,
            records_valid=0,
            records_rejected=0,
            status="ERROR",
            message=f"{type(exc).__name__}: ETL Contabilidad -> DW falló.",
        )
        raise


if __name__ == "__main__":
    print(run())
