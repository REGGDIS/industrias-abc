from __future__ import annotations

import argparse
import json
from datetime import date, datetime, time, timedelta, timezone
from decimal import Decimal
from pathlib import Path
from time import monotonic
from uuid import uuid4

import pymysql

from etl.config.settings import get_asistencia_db_config
from etl.validate.asistencia.validator import (
    resumen_validacion,
    validate_asistencias,
)


PROJECT_ROOT = Path(__file__).resolve().parents[3]
STAGING_DIR = PROJECT_ROOT / "etl" / "sql" / "staging" / "asistencia"


def _leer_sql(nombre_archivo: str) -> str:
    ruta = STAGING_DIR / nombre_archivo
    return ruta.read_text(encoding="utf-8").strip().rstrip(";")


def _crear_conexion():
    config = get_asistencia_db_config()

    return pymysql.connect(
        host=config.host,
        port=config.port,
        user=config.user,
        password=config.password,
        database=config.database,
        cursorclass=pymysql.cursors.DictCursor,
        autocommit=True,
    )


def obtener_datos(connection_factory=None):
    factory = connection_factory or _crear_conexion
    conexion = factory()
    cursor = conexion.cursor()

    try:
        # -------------------------------------------------------------
        # RAW temporal
        # -------------------------------------------------------------
        cursor.execute(
            """
            CREATE TEMPORARY TABLE stg_asistencia_trabajador_raw
            AS
            SELECT *
            FROM trabajador
            """
        )

        cursor.execute(
            """
            CREATE TEMPORARY TABLE stg_asistencia_turnos_raw
            AS
            SELECT *
            FROM turnos
            """
        )

        cursor.execute(
            """
            CREATE TEMPORARY TABLE stg_asistencia_asistencia_raw
            AS
            SELECT *
            FROM asistencia
            """
        )

        # -------------------------------------------------------------
        # STAGING / CLEAN
        # Se reutilizan los SQL ya aprobados en Asistencia 0.1.
        # -------------------------------------------------------------
        cursor.execute(_leer_sql("trabajador.sql"))
        trabajadores = cursor.fetchall()

        cursor.execute(_leer_sql("turnos.sql"))
        turnos = cursor.fetchall()

        cursor.execute(_leer_sql("asistencia.sql"))
        asistencias = cursor.fetchall()

        return trabajadores, turnos, asistencias

    finally:
        cursor.close()
        conexion.close()


def validar_datos(trabajadores, turnos, asistencias):
    trabajadores_ids = {
        trabajador["trabajador_id"]
        for trabajador in trabajadores
    }

    turnos_ids = {
        turno["turno_id"]
        for turno in turnos
    }

    trabajadores_dict = {
        trabajador["trabajador_id"]: trabajador
        for trabajador in trabajadores
    }

    turnos_dict = {
        turno["turno_id"]: turno
        for turno in turnos
    }

    resultados = validate_asistencias(
        asistencias,
        trabajadores_ids=trabajadores_ids,
        turnos_ids=turnos_ids,
        trabajadores=trabajadores_dict,
        turnos=turnos_dict,
    )

    resumen = resumen_validacion(resultados)

    return resumen, resultados


def _json_value(value):
    if isinstance(value, Decimal):
        return str(value)

    if isinstance(value, (date, datetime, time)):
        return value.isoformat()

    if isinstance(value, timedelta):
        return value.total_seconds()

    raise TypeError(
        f"Tipo no serializable: {type(value).__name__}"
    )


def run(output: str | Path, connection_factory=None) -> dict:
    inicio_monotonic = monotonic()

    report = {
        "run_id": str(uuid4()),
        "started_at": datetime.now(timezone.utc).isoformat(),
        "finished_at": None,
        "duration_seconds": None,
        "status": "ERROR",
        "stage": "configuration",
        "error": None,
        "procesados": 0,
        "validos": 0,
        "errores": 0,
        "warnings": 0,
        "extraidos": {
            "trabajadores": 0,
            "turnos": 0,
            "asistencias": 0,
        },
        "detalle": [],
    }

    try:
        report["stage"] = "extract"

        trabajadores, turnos, asistencias = obtener_datos(
            connection_factory=connection_factory
        )

        report["extraidos"] = {
            "trabajadores": len(trabajadores),
            "turnos": len(turnos),
            "asistencias": len(asistencias),
        }

        report["stage"] = "validate"

        resumen, resultados = validar_datos(
            trabajadores,
            turnos,
            asistencias,
        )

        report.update(
            {
                "procesados": resumen["procesados"],
                "validos": resumen["validos"],
                "errores": resumen["errores"],
                "warnings": resumen["warnings"],
                "detalle": resumen["detalle"],
                "resultados": resultados,
            }
        )

        if report["errores"] > 0:
            raise ValueError(
                "Se detectaron registros de asistencia con errores de calidad."
            )

        report["status"] = "OK"
        report["stage"] = None

    except Exception as exc:
        # Los fallos técnicos no persisten mensajes de conexión,
        # porque podrían contener información sensible.
        if isinstance(exc, ValueError):
            report["error"] = str(exc)
        else:
            report["error"] = (
                f"{type(exc).__name__}: "
                f"fallo en {report['stage']}"
            )

    report["finished_at"] = datetime.now(timezone.utc).isoformat()
    report["duration_seconds"] = monotonic() - inicio_monotonic

    output = Path(output)
    output.parent.mkdir(parents=True, exist_ok=True)

    output.write_text(
        json.dumps(
            report,
            ensure_ascii=False,
            indent=2,
            default=_json_value,
        )
        + "\n",
        encoding="utf-8",
    )

    return report


def ejecutar_validacion():
    trabajadores, turnos, asistencias = obtener_datos()

    resumen, _ = validar_datos(
        trabajadores,
        turnos,
        asistencias,
    )

    print("========================================")
    print("VALIDACIÓN DE ASISTENCIA")
    print("========================================")
    print(f"procesados={resumen['procesados']}")
    print(f"validos={resumen['validos']}")
    print(f"errores={resumen['errores']}")
    print(f"warnings={resumen['warnings']}")
    print()

    print("DETALLE DE OBSERVACIONES")
    print("----------------------------------------")

    if not resumen["detalle"]:
        print("Sin errores ni advertencias.")
    else:
        for detalle in resumen["detalle"]:
            print(
                f"asistencia_id={detalle['asistencia_id']} | "
                f"severidad={detalle['severidad']} | "
                f"reglas={'; '.join(detalle['reglas'])}"
            )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Ejecuta y audita la validación ETL de Asistencia."
    )

    parser.add_argument(
        "--output",
        default=f"logs/asistencia/{uuid4()}.json",
    )

    args = parser.parse_args()

    resultado = run(args.output)

    print(
        f"run_id={resultado['run_id']} "
        f"status={resultado['status']} "
        f"output={args.output}"
    )

    raise SystemExit(
        0 if resultado["status"] == "OK" else 1
    )
