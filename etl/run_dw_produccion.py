from etl.audit.logger import finish_execution, start_execution
from etl.load.dw_produccion import run_dw_produccion_load


def run_dw_produccion_etl() -> dict:
    execution_id = start_execution(
        source="PRODUCCION",
        process="ETL_DW_PRODUCCION",
    )

    summary: dict = {
        "records_read": 0,
        "records_valid": 0,
        "records_rejected": 0,
        "records_inserted": 0,
        "records_updated": 0,
        "records_unchanged": 0,
        "records_review": 0,
    }

    try:
        summary = run_dw_produccion_load()

        status = (
            "PARTIAL"
            if summary["records_rejected"] > 0
            or summary["records_review"] > 0
            else "SUCCESS"
        )

        message = (
            "ETL Producción -> DW ejecutado. "
            f"REVIEW={summary['records_review']} "
            f"REJECTED={summary['records_rejected']}."
        )

        finish_execution(
            execution_id=execution_id,
            records_read=summary["records_read"],
            records_valid=summary["records_valid"],
            records_rejected=summary["records_rejected"],
            records_inserted=summary["records_inserted"],
            records_updated=summary["records_updated"],
            records_unchanged=summary["records_unchanged"],
            records_review=summary["records_review"],
            status=status,
            message=message,
        )

        return {
            "execution_id": execution_id,
            "status": status,
            **summary,
        }

    except Exception as error:
        finish_execution(
            execution_id=execution_id,
            records_read=summary.get("records_read", 0),
            records_valid=summary.get("records_valid", 0),
            records_rejected=summary.get("records_rejected", 0),
            records_inserted=summary.get("records_inserted", 0),
            records_updated=summary.get("records_updated", 0),
            records_unchanged=summary.get("records_unchanged", 0),
            records_review=summary.get("records_review", 0),
            status="ERROR",
            message=str(error),
        )
        raise


if __name__ == "__main__":
    print(run_dw_produccion_etl())
