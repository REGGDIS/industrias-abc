from __future__ import annotations

import argparse
import json
import uuid
from datetime import datetime, timezone
from pathlib import Path
from time import perf_counter

from etl.config.settings import get_rrhh_db_config
from etl.extract.postgres import get_postgres_connection
from etl.run_rrhh import run_rrhh_etl


PROCESO = "rrhh_etl"

ENTITIES = {
    "empleados": {
        "raw": "stg_rrhh_empleados_raw",
        "clean": "stg_rrhh_empleados_clean",
        "result_key": "records_read",
    },
    "areas": {
        "raw": "stg_rrhh_areas_raw",
        "clean": "stg_rrhh_areas_clean",
        "result_key": "areas",
    },
    "cargos": {
        "raw": "stg_rrhh_cargos_raw",
        "clean": "stg_rrhh_cargos_clean",
        "result_key": "cargos",
    },
    "centros_costo": {
        "raw": "stg_rrhh_centros_costo_raw",
        "clean": "stg_rrhh_centros_costo_clean",
        "result_key": "centros_costo",
    },
}


def _utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def _fetch_staging_counts() -> dict[str, dict[str, int]]:
    config = get_rrhh_db_config()

    counts: dict[str, dict[str, int]] = {}

    with get_postgres_connection(config) as connection:
        with connection.cursor() as cursor:
            for entity, tables in ENTITIES.items():
                cursor.execute(
                    f"SELECT COUNT(*) FROM {tables['raw']};"
                )
                raw_count = cursor.fetchone()[0]

                cursor.execute(
                    f"SELECT COUNT(*) FROM {tables['clean']};"
                )
                clean_count = cursor.fetchone()[0]

                counts[entity] = {
                    "raw": raw_count,
                    "clean": clean_count,
                }

    return counts


def run(output: Path | None = None) -> dict:
    run_id = str(uuid.uuid4())
    started_at = _utc_now()
    started_perf = perf_counter()
    current_stage = "etl_rrhh"

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
        "errores": 0,
        "warnings": 0,
        "controles_error": 0,
        "execution_id_origen": None,
        "entidades": {},
        "etapas": [],
    }

    try:
        stage_started = perf_counter()

        result = run_rrhh_etl()

        report["etapas"].append(
            {
                "stage": "etl_rrhh",
                "status": "OK",
                "duration_ms": round(
                    (perf_counter() - stage_started) * 1000
                ),
            }
        )

        report["execution_id_origen"] = result["execution_id"]
        report["procesados"] = result["records_read"]
        report["validos"] = result["records_valid"]
        report["errores"] = result["records_rejected"]

        current_stage = "verificacion_staging"
        stage_started = perf_counter()

        staging_counts = _fetch_staging_counts()

        controles_error = 0

        for entity, tables in ENTITIES.items():
            expected = result[tables["result_key"]]
            raw_count = staging_counts[entity]["raw"]
            clean_count = staging_counts[entity]["clean"]

            raw_ok = raw_count == expected
            clean_ok = clean_count == expected

            if not raw_ok:
                controles_error += 1

            if not clean_ok:
                controles_error += 1

            report["entidades"][entity] = {
                "extraidos": expected,
                "raw": raw_count,
                "clean": clean_count,
                "raw_ok": raw_ok,
                "clean_ok": clean_ok,
            }

        report["controles_error"] = controles_error

        report["etapas"].append(
            {
                "stage": "verificacion_staging",
                "status": "OK" if controles_error == 0 else "ERROR",
                "duration_ms": round(
                    (perf_counter() - stage_started) * 1000
                ),
            }
        )

        if controles_error > 0:
            report["status"] = "ERROR"
            report["stage"] = "verificacion_staging"
            report["error"] = (
                "Los conteos RAW/CLEAN no coinciden "
                "con los registros extraidos."
            )
        elif result["status"] != "SUCCESS":
            report["status"] = "ERROR"
            report["stage"] = "etl_rrhh"
            report["controles_error"] += 1
            report["error"] = (
                "El ETL RRHH no finalizo con estado SUCCESS."
            )
        else:
            report["status"] = "OK"
            report["stage"] = None
            report["error"] = None

    except Exception as exc:
        report["status"] = "ERROR"
        report["stage"] = current_stage
        report["controles_error"] = max(
            report["controles_error"],
            1,
        )

        # No persistir el mensaje original de la excepción:
        # podría contener datos técnicos o sensibles.
        report["error"] = (
            f"{type(exc).__name__}: "
            f"fallo durante {current_stage}"
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
        description="Runner de cierre ETL RRHH"
    )

    parser.add_argument(
        "--output",
        type=Path,
        default=None,
        help="Ruta opcional para evidencia JSON",
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
