"""Ejecutar con python -m etl.validate.compras.runner --output <ruta.json>.

ETL Compras 0.5 · Cierre final · Auditoría de ejecución
Proyecto: Business Intelligence - Industrias ABC (Equipo BInnova)
Dominio: Compras · Responsable: Raymond Civil

Corre una ejecución completa del ETL de Compras dejando evidencia técnica:
run_id único, tiempos, estado OK/ERROR, etapa donde falla, métricas reales
(procesados / validos / review / errores) y mensaje de error.

Alineado con el patrón de cierre del equipo (Contabilidad / Asistencia):
runner en etl/validate/<dominio>/, salida JSON a --output, y evidencia
committeada (evidencia_ejecucion.json / evidencia_fallo_controlado.json).

REUTILIZA sin duplicar reglas:
  - 0.4  etl/sql/staging/compras/ejecutar_normalizacion_compras.sql (RAW + normalización + métricas)
  - 0.3  etl/validate/compras/validaciones_calidad_compras.sql (controles de calidad)
  - 0.4  etl/tests/compras/test_normalizacion_compras.sql (pruebas)

Cada etapa se ejecuta con psql -v ON_ERROR_STOP=1: el código de salida real
decide OK/ERROR (un fallo NO se convierte en OK). La contraseña se pasa por
PGPASSWORD (no aparece en la línea de comandos ni en la evidencia). Solo lectura
sobre lo operacional; la salida va a un archivo JSON, nunca a la BD.
"""
import argparse
import json
import os
import subprocess
from datetime import datetime, timezone
from pathlib import Path
from time import monotonic
from uuid import uuid4

from etl.config.settings import get_compras_db_config

ETL = Path(__file__).resolve().parents[2]          # etl/
SQL_STAGING = ETL / "sql" / "staging" / "compras"
SQL_VALIDATE = ETL / "validate" / "compras"
SQL_TESTS = ETL / "tests" / "compras"

PROCESO = "compras_etl"


def _default_stages() -> list[tuple[str, Path]]:
    """Etapas mínimas del cierre, registradas por separado."""
    return [
        ("normalizacion", SQL_STAGING / "ejecutar_normalizacion_compras.sql"),
        ("validaciones_calidad", SQL_VALIDATE / "validaciones_calidad_compras.sql"),
        ("pruebas_normalizacion", SQL_TESTS / "test_normalizacion_compras.sql"),
    ]


def _conn_parts() -> tuple[str, str]:
    """(conninfo SIN password, password). La clave viaja por PGPASSWORD, no en argv."""
    c = get_compras_db_config()
    return f"host={c.host} port={c.port} dbname={c.database} user={c.user}", c.password


def _psql(conninfo: str, password: str, sql_path: Path) -> tuple[int, str, str]:
    env = dict(os.environ)
    if password:
        env["PGPASSWORD"] = password
    proc = subprocess.run(
        ["psql", conninfo, "-v", "ON_ERROR_STOP=1", "-tA", "-F", "|", "-f", str(sql_path)],
        capture_output=True,
        text=True,
        env=env,
    )
    return proc.returncode, proc.stdout, proc.stderr


def _parse_total(stdout: str) -> tuple[int, int, int, int] | None:
    """Lee una fila TOTAL con cuatro métricas numéricas."""
    for line in stdout.splitlines():
        parts = [part.strip() for part in line.split("|")]

        if len(parts) >= 5 and parts[0] == "TOTAL":
            try:
                return (
                    int(parts[1]),
                    int(parts[2]),
                    int(parts[3]),
                    int(parts[4]),
                )
            except ValueError:
                return None

    return None


def _parse_normalizacion(stdout: str) -> dict | None:
    """Métricas 0.4: campos evaluados, no registros transaccionales."""
    total = _parse_total(stdout)

    if total is None:
        return None

    procesados, normalizados, review, errores = total

    return {
        "procesados": procesados,
        "normalizados": normalizados,
        "review": review,
        "errores": errores,
    }


def _parse_calidad(stdout: str) -> dict | None:
    """Métricas 0.3: registros transaccionales evaluados."""
    total = _parse_total(stdout)

    if total is None:
        return None

    procesados, validos, review, errores = total

    return {
        "procesados": procesados,
        "validos": validos,
        "review": review,
        "errores": errores,
    }


def run(output, stages=None, psql_fn=None) -> dict:
    """Ejecuta el cierre, arma el reporte y lo escribe en `output` (JSON)."""
    started = monotonic()
    stages = stages if stages is not None else _default_stages()
    psql_fn = psql_fn or _psql

    report = {
        "run_id": str(uuid4()),
        "proceso": PROCESO,
        "started_at": datetime.now(timezone.utc).isoformat(),
        "status": "ERROR",
        "stage": "configuration",
        "error": None,
        "procesados": 0,
        "validos": 0,
        "review": 0,
        "errores": 0,
        "controles_error": 0,
        "normalizacion": None,
        "calidad": None,
        "etapas": [],
    }

    try:
        conninfo, password = _conn_parts()
        failed = False
        for nombre, path in stages:
            report["stage"] = nombre
            t0 = monotonic()

            if not path.exists():
                report["etapas"].append({"nombre": nombre, "resultado": "ERROR", "duracion_ms": 0})
                report["error"] = f"Etapa '{nombre}': no se encontró el script SQL"
                failed = True
                break

            rc, out, err = psql_fn(conninfo, password, path)
            dur_ms = int((monotonic() - t0) * 1000)

            if rc != 0:
                report["etapas"].append(
                    {
                        "nombre": nombre,
                        "resultado": "ERROR",
                        "duracion_ms": dur_ms,
                    }
                )
                # Error técnico de psql/SQL. Se recorta y no se incluyen credenciales.
                report["error"] = (
                    f"Etapa '{nombre}' (exit {rc}): "
                    f"{(err.strip() or out.strip())[:800]}"
                )
                failed = True
                break

            if nombre == "normalizacion":
                metricas = _parse_normalizacion(out)

                if metricas is None:
                    report["etapas"].append(
                        {
                            "nombre": nombre,
                            "resultado": "ERROR",
                            "duracion_ms": dur_ms,
                        }
                    )
                    report["error"] = (
                        "No fue posible interpretar las métricas "
                        "de normalización 0.4."
                    )
                    failed = True
                    break

                report["normalizacion"] = metricas

            elif nombre == "validaciones_calidad":
                metricas = _parse_calidad(out)

                if metricas is None:
                    report["etapas"].append(
                        {
                            "nombre": nombre,
                            "resultado": "ERROR",
                            "duracion_ms": dur_ms,
                        }
                    )
                    report["error"] = (
                        "No fue posible interpretar las métricas "
                        "de calidad 0.3."
                    )
                    failed = True
                    break

                report["calidad"] = metricas

                # Las métricas superiores representan calidad transaccional,
                # no cantidad de campos normalizados.
                report.update(metricas)

                if metricas["errores"] > 0:
                    report["controles_error"] = 1
                    report["etapas"].append(
                        {
                            "nombre": nombre,
                            "resultado": "ERROR",
                            "duracion_ms": dur_ms,
                        }
                    )
                    report["error"] = (
                        "Se detectaron registros con errores "
                        "en los controles de calidad de Compras."
                    )
                    failed = True
                    break

            report["etapas"].append(
                {
                    "nombre": nombre,
                    "resultado": "OK",
                    "duracion_ms": dur_ms,
                }
            )

        if not failed:
            report["status"] = "OK"
            report["stage"] = None
    except Exception as exc:
        # Errores inesperados (p. ej. conexión): NO registrar posibles credenciales.
        report["error"] = f"{type(exc).__name__}: fallo en {report['stage']}"

    report["finished_at"] = datetime.now(timezone.utc).isoformat()
    duracion = monotonic() - started
    report["duration_seconds"] = duracion
    report["duracion_ms"] = int(duracion * 1000)  # requerido por el encargo de Compras

    output = Path(output)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return report


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Cierre/auditoría de ejecución del ETL de Compras.")
    parser.add_argument("--output", default=f"logs/compras/{uuid4()}.json")
    args = parser.parse_args()
    result = run(args.output)
    print(f"run_id={result['run_id']} status={result['status']} output={args.output}")
    raise SystemExit(0 if result["status"] == "OK" else 1)
