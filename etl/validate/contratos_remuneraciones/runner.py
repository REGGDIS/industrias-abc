from __future__ import annotations

import argparse
import json
import sys
import time
import uuid
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from .validator import (
    Finding,
    fetch_rows,
    run_validation,
)


PROCESO = "contratos_remuneraciones_etl"

VISTAS = {
    "empleado": "staging.contratos_remuneraciones_empleado",
    "contrato": "staging.contratos_remuneraciones_contrato",
    "liquidacion": "staging.contratos_remuneraciones_liquidacion",
    "concepto_pago": "staging.contratos_remuneraciones_concepto_pago",
    "detalle_liquidacion": "staging.contratos_remuneraciones_detalle_liquidacion",
}


def _utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def _contar_entidades() -> dict[str, int]:
    return {
        nombre: len(fetch_rows(vista))
        for nombre, vista in VISTAS.items()
    }


def _resumen_findings(findings: list[Finding]) -> dict[str, int]:
    errores = sum(1 for f in findings if f.severidad == "ERROR")
    warnings = sum(1 for f in findings if f.severidad == "WARNING")

    return {
        "hallazgos": len(findings),
        "errores": errores,
        "warnings": warnings,
    }


def _serializar_findings(findings: list[Finding]) -> list[dict[str, Any]]:
    return [
        {
            "entidad": f.entidad,
            "identificador": f.identificador,
            "regla": f.regla,
            "severidad": f.severidad,
            "detalle": f.detalle,
        }
        for f in findings
    ]


def run(output: Path | None = None) -> dict[str, Any]:
    started_monotonic = time.perf_counter()
    started_at = _utc_now()
    run_id = str(uuid.uuid4())

    report: dict[str, Any] = {
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
        "controles_error": 0,
        "entidades": {},
        "hallazgos": [],
        "etapas": [],
    }

    try:
        # --------------------------------------------------------------
        # Etapa 1: conteos reales desde STAGING
        # --------------------------------------------------------------
        stage_start = time.perf_counter()
        entidades = _contar_entidades()
        stage_ms = int((time.perf_counter() - stage_start) * 1000)

        report["entidades"] = entidades
        report["procesados"] = sum(entidades.values())
        report["etapas"].append({
            "nombre": "lectura_staging",
            "resultado": "OK",
            "duracion_ms": stage_ms,
        })

        # --------------------------------------------------------------
        # Etapa 2: validación completa
        # --------------------------------------------------------------
        stage_start = time.perf_counter()
        findings = run_validation()
        stage_ms = int((time.perf_counter() - stage_start) * 1000)

        resumen = _resumen_findings(findings)

        report["hallazgos"] = _serializar_findings(findings)
        report["errores"] = resumen["errores"]
        report["warnings"] = resumen["warnings"]
        report["review"] = resumen["warnings"]
        report["validos"] = report["procesados"] - resumen["errores"]

        if resumen["errores"] > 0:
            report["status"] = "ERROR"
            report["stage"] = "validacion"
            report["controles_error"] = 1
            report["error"] = (
                "Se detectaron registros con errores en los controles "
                "de calidad de Contratos y Remuneraciones."
            )
            report["etapas"].append({
                "nombre": "validacion",
                "resultado": "ERROR",
                "duracion_ms": stage_ms,
            })
        else:
            report["status"] = "OK"
            report["stage"] = None
            report["controles_error"] = 0
            report["etapas"].append({
                "nombre": "validacion",
                "resultado": "OK",
                "duracion_ms": stage_ms,
            })

    except Exception as exc:
        report["status"] = "ERROR"
        report["controles_error"] = 1

        if report["stage"] is None:
            report["stage"] = "ejecucion"

        report["error"] = f"{type(exc).__name__}: {exc}"

        report["etapas"].append({
            "nombre": report["stage"],
            "resultado": "ERROR",
            "duracion_ms": 0,
        })

    finally:
        duration = time.perf_counter() - started_monotonic

        report["finished_at"] = _utc_now()
        report["duration_seconds"] = duration
        report["duracion_ms"] = int(duration * 1000)

        if output is not None:
            output.parent.mkdir(parents=True, exist_ok=True)
            output.write_text(
                json.dumps(
                    report,
                    ensure_ascii=False,
                    indent=2,
                    default=str,
                )
                + "\n",
                encoding="utf-8",
            )

    return report


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Runner de cierre ETL Contratos y Remuneraciones."
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=None,
        help="Ruta opcional donde persistir el JSON de auditoría.",
    )

    args = parser.parse_args()
    report = run(args.output)

    print(json.dumps(
        report,
        ensure_ascii=False,
        indent=2,
        default=str,
    ))

    return 0 if report["status"] == "OK" else 1


if __name__ == "__main__":
    sys.exit(main())
