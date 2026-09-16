from __future__ import annotations

from etl.audit.logger import finish_execution, start_execution
from etl.load.dw_contratos_remuneraciones import run_dw_contratos_remuneraciones


SOURCE = "CONTRATOS_REMUNERACIONES"
PROCESS = "ETL_DW_CONTRATOS_REMUNERACIONES"


def run() -> dict:
    execution_id = start_execution(SOURCE, PROCESS)
    try:
        result = run_dw_contratos_remuneraciones()
        records_read = sum(result["source"].values())
        records_valid = records_read
        records_rejected = len(result["rejected"])
        records_review = len(result["review"])
        records_inserted = (
            result["dim_contrato"]["inserted"]
            + result["fact_remuneraciones"]["inserted"]
        )
        records_updated = (
            result["dim_contrato"]["updated"]
            + result["fact_remuneraciones"]["updated"]
        )
        records_unchanged = (
            result["dim_contrato"]["unchanged"]
            + result["fact_remuneraciones"]["unchanged"]
        )

        status = "PARTIAL" if records_rejected or records_review else "SUCCESS"
        message = (
            "ETL Contratos/Remuneraciones -> DW ejecutado. "
            f"SOURCE_WARNINGS={result['source_validation']['warnings']} "
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
            message=f"{type(exc).__name__}: ETL Contratos/Remuneraciones -> DW falló.",
        )
        raise


if __name__ == "__main__":
    print(run())
