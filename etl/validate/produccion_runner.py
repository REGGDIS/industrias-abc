from __future__ import annotations

import argparse
import json
import uuid
from datetime import datetime, timezone
from pathlib import Path
from time import perf_counter

from etl.validate.produccion_calidad import profile_quality
from etl.validate.reconcile_produccion import (
    fetch_mysql_consumos,
    read_csv_consumos,
)


PROCESO = "produccion_etl"


def _utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def run(output: Path | None = None) -> dict:
    run_id = str(uuid.uuid4())
    started_at = _utc_now()
    started_perf = perf_counter()

    report: dict = {
        "run_id": run_id,
        "proceso": PROCESO,
        "started_at": started_at,
        "finished_at": None,
        "duration_seconds": None,
        "duracion_ms": None,
        "status": "ERROR",
        "stage": None,
        "error": None,
        "procesados": 0,
        "validos": 0,
        "review": 0,
        "errores": 0,
        "warnings": 0,
        "duplicados_exactos": 0,
        "duplicados_clave": 0,
        "controles_error": 0,
        "hallazgos": [],
        "etapas": [],
    }

    try:
        stage_started = perf_counter()
        csv_rows = read_csv_consumos()

        report["etapas"].append(
            {
                "stage": "lectura_csv",
                "status": "OK",
                "duration_ms": round(
                    (perf_counter() - stage_started) * 1000
                ),
                "filas": len(csv_rows),
            }
        )

        stage_started = perf_counter()
        mysql_rows = fetch_mysql_consumos()

        report["etapas"].append(
            {
                "stage": "lectura_mysql",
                "status": "OK",
                "duration_ms": round(
                    (perf_counter() - stage_started) * 1000
                ),
                "filas": len(mysql_rows),
            }
        )

        stage_started = perf_counter()
        summary = profile_quality(
            csv_rows,
            mysql_rows,
        )

        report["etapas"].append(
            {
                "stage": "validacion",
                "status": (
                    "ERROR"
                    if summary.rows_with_error > 0
                    else "OK"
                ),
                "duration_ms": round(
                    (perf_counter() - stage_started) * 1000
                ),
            }
        )

        report["procesados"] = summary.rows_processed
        report["validos"] = summary.valid_rows
        report["review"] = summary.rows_with_warning
        report["errores"] = summary.rows_with_error
        report["warnings"] = summary.rows_with_warning
        report["duplicados_exactos"] = summary.exact_duplicates
        report["duplicados_clave"] = summary.key_duplicates

        report["hallazgos"] = [
            {
                "fila": finding.row_number,
                "business_key": list(finding.business_key),
                "regla": finding.rule,
                "severidad": finding.severity,
                "detalle": finding.detail,
            }
            for finding in summary.findings
        ]

        if summary.rows_with_error > 0:
            report["status"] = "ERROR"
            report["stage"] = "validacion"
            report["controles_error"] = 1
            report["error"] = (
                "Se detectaron registros con errores "
                "en los controles de calidad de Producción."
            )
        else:
            report["status"] = "OK"
            report["stage"] = None
            report["controles_error"] = 0

    except Exception as exc:
        report["status"] = "ERROR"
        report["stage"] = report["stage"] or "ejecucion"
        report["controles_error"] = 1
        report["error"] = (
            f"{type(exc).__name__}: {exc}"
        )

    finally:
        finished_perf = perf_counter()
        report["finished_at"] = _utc_now()
        report["duration_seconds"] = (
            finished_perf - started_perf
        )
        report["duracion_ms"] = round(
            report["duration_seconds"] * 1000
        )

        if output is not None:
            output.parent.mkdir(
                parents=True,
                exist_ok=True,
            )

            output.write_text(
                json.dumps(
                    report,
                    indent=2,
                    ensure_ascii=False,
                    default=str,
                )
                + "\n",
                encoding="utf-8",
            )

    return report


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Runner de cierre ETL Producción"
    )

    parser.add_argument(
        "--output",
        type=Path,
        default=None,
        help="Ruta opcional para guardar evidencia JSON",
    )

    args = parser.parse_args()

    report = run(args.output)

    print(
        json.dumps(
            report,
            indent=2,
            ensure_ascii=False,
            default=str,
        )
    )

    raise SystemExit(
        1 if report["status"] == "ERROR" else 0
    )


if __name__ == "__main__":
    main()
