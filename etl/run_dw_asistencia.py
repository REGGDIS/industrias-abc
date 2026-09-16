from __future__ import annotations

from etl.audit.logger import finish_execution, start_execution
from etl.load.dw_asistencia import run_dw_asistencia_load


SOURCE = "ASISTENCIA"
PROCESS = "ETL_DW_ASISTENCIA"


def main() -> dict:
    execution_id = start_execution(SOURCE, PROCESS)

    try:
        result = run_dw_asistencia_load()
        status = (
            "PARTIAL"
            if result["records_rejected"] > 0 or result["records_review"] > 0
            else "SUCCESS"
        )

        finish_execution(
            execution_id=execution_id,
            records_read=result["records_read"],
            records_valid=result["records_valid"],
            records_rejected=result["records_rejected"],
            records_inserted=result["records_inserted"],
            records_updated=result["records_updated"],
            records_unchanged=result["records_unchanged"],
            records_review=result["records_review"],
            status=status,
            message=(
                "ETL Asistencia -> DW ejecutado. "
                f"REVIEW={result['records_review']} "
                f"REJECTED={result['records_rejected']}."
            ),
        )

        return {"execution_id": execution_id, "status": status, **result}
    except Exception as exc:
        finish_execution(
            execution_id=execution_id,
            records_read=0,
            records_valid=0,
            records_rejected=0,
            status="ERROR",
            message=f"ETL Asistencia -> DW falló: {type(exc).__name__}",
        )
        raise


if __name__ == "__main__":
    print(main())
