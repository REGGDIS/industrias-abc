"""Ejecutar con python -m etl.validate.contabilidad.runner --output <ruta.json>."""
import argparse
import json
from datetime import date, datetime, timezone
from decimal import Decimal
from pathlib import Path
from time import monotonic
from uuid import uuid4

from psycopg.rows import dict_row

from etl.config.settings import get_contabilidad_db_config
from etl.config.staging import get_staging_table_names
from etl.extract.postgres import get_postgres_connection

ETL = Path(__file__).resolve().parents[2]
ENTITIES = {
    "areas": "area_id",
    "centros_costo": "centro_costo_id",
    "cuentas_contables": "cuenta_id",
    "movimientos_contables": "movimiento_id",
}


def read_sql(folder, entity):
    return (ETL / "sql" / folder / "contabilidad" / f"{entity}.sql").read_text(
        encoding="utf-8"
    ).strip().rstrip(";")


def prepare(cursor, stage):
    """Tablas TEMP solamente; las consultas 0.1 son la única transformación."""
    for entity in ENTITIES:
        names = get_staging_table_names("contabilidad", entity)
        name = getattr(names, stage)
        folder = "extract" if stage == "raw" else "staging"
        cursor.execute(f"CREATE TEMP TABLE {name} ON COMMIT DROP AS\n{read_sql(folder, entity)}")


def controls():
    # Formato local controlado: encabezado JSON seguido de una consulta SQL.
    content = Path(__file__).with_name("controles.sql").read_text(encoding="utf-8")
    for block in content.split("-- @control ")[1:]:
        header, sql = block.split("\n", 1)
        yield json.loads(header), sql.strip()


def validate(cursor):
    records = {}
    for entity, pk in ENTITIES.items():
        names = get_staging_table_names("contabilidad", entity)
        cursor.execute(f"SELECT * FROM {names.clean}")
        records[entity] = [dict(row, reglas=[]) for row in cursor.fetchall()]
    evidence = []
    for rule, sql in controls():
        cursor.execute(sql)
        rows = cursor.fetchall()
        mode = rule.get("mode", "empty")
        if mode == "counts":
            failed = any(row["diferencia"] != 0 for row in rows)
        elif mode == "sums":
            failed = any(row[k] not in (None, 0) for row in rows for k in ("diff_debe", "diff_haber"))
        elif mode == "balance":
            failed = any(row["cuadratura_staging"] not in (None, 0) for row in rows)
        else:
            failed = bool(rows)
        evidence.append({**rule, "status": "ERROR" if failed else "OK", "rows": rows})
        if failed and "entity" in rule:
            key = rule["key"]
            values = {row[key] for row in rows}
            for row in records[rule["entity"]]:
                if row[key] in values:
                    row["reglas"].append(rule["name"])
    detail = []
    for entity, rows in records.items():
        for row in rows:
            detail.append({"entidad": entity, "id": row[ENTITIES[entity]],
                           "estado": "ERROR" if row["reglas"] else "VALID",
                           "reglas": row["reglas"]})
    errors = sum(row["estado"] == "ERROR" for row in detail)
    controles_error = sum(control["status"] == "ERROR" for control in evidence)
    return {
        "procesados": len(detail),
        "validos": len(detail) - errors,
        "review": 0,
        "errores": errors,
        "controles_error": controles_error,
        "registros": detail,
        "controles": evidence,
    }


def normalization_trace(cursor):
    trace = []
    for entity, pk in ENTITIES.items():
        names = get_staging_table_names("contabilidad", entity)
        cursor.execute(f"SELECT * FROM {names.raw}")
        raw = {row[pk]: row for row in cursor.fetchall()}
        cursor.execute(f"SELECT * FROM {names.clean}")
        for row in cursor.fetchall():
            for field, value in row.items():
                if raw[row[pk]][field] != value:
                    trace.append({"entidad": entity, "id": row[pk], "campo": field,
                                  "original": raw[row[pk]][field], "normalizado": value})
    return trace


def json_value(value):
    if isinstance(value, Decimal):
        return str(value)  # Nunca float: conserva exactamente los decimales.
    if isinstance(value, (date, datetime)):
        return value.isoformat()
    raise TypeError(f"Tipo no serializable: {type(value).__name__}")


def run(output, connection_factory=None):
    started = monotonic()
    report = {"run_id": str(uuid4()), "started_at": datetime.now(timezone.utc).isoformat(),
              "status": "ERROR", "stage": "configuration", "error": None,
              "procesados": 0, "validos": 0, "review": 0, "errores": 0,
              "controles_error": 0}
    try:
        factory = connection_factory or (lambda: get_postgres_connection(get_contabilidad_db_config()))
        with factory() as connection:
            with connection.cursor(row_factory=dict_row) as cursor:
                cursor.execute("SET TRANSACTION ISOLATION LEVEL REPEATABLE READ")
                report["stage"] = "extract"
                prepare(cursor, "raw")
                report["extraidos"] = {}
                for entity in ENTITIES:
                    names = get_staging_table_names("contabilidad", entity)
                    cursor.execute(f"SELECT COUNT(*) AS cantidad FROM {names.raw}")
                    report["extraidos"][entity] = cursor.fetchone()["cantidad"]
                report["procesados"] = sum(report["extraidos"].values())
                report["stage"] = "normalize"
                prepare(cursor, "clean")
                report["normalizacion"] = normalization_trace(cursor)
                report["stage"] = "validate"
                report.update(validate(cursor))
                if report["controles_error"] > 0:
                    raise ValueError("Fallaron controles de calidad; consultar controles y registros.")
                report["status"] = "OK"
                report["stage"] = None
            connection.rollback()  # Ningún objeto ni cambio persistente en PostgreSQL.
    except Exception as exc:
        # No persistir mensajes de conexión que puedan contener credenciales.
        report["error"] = (str(exc) if isinstance(exc, ValueError) else
                           f"{type(exc).__name__}: fallo en {report['stage']}")
    report["finished_at"] = datetime.now(timezone.utc).isoformat()
    report["duration_seconds"] = monotonic() - started
    output = Path(output)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(report, ensure_ascii=False, indent=2, default=json_value) + "\n", encoding="utf-8")
    return report


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", default=f"logs/contabilidad/{uuid4()}.json")
    args = parser.parse_args()
    result = run(args.output)
    print(f"run_id={result['run_id']} status={result['status']} output={args.output}")
    raise SystemExit(0 if result["status"] == "OK" else 1)
