from __future__ import annotations

from collections import defaultdict
from datetime import date
from decimal import Decimal
from pathlib import Path

from etl.config.settings import get_dw_db_config
from etl.extract.postgres import get_postgres_connection
from etl.load.dw_rrhh import rut_dv_valido
from etl.validate.contratos_remuneraciones.validator import fetch_rows, run_validation


SQL_DIR = (
    Path(__file__).resolve().parents[1]
    / "sql"
    / "load"
    / "dw"
    / "contratos_remuneraciones"
)


def _canonical_rut(value: str | None) -> str | None:
    if value is None:
        return None
    cleaned = value.strip().upper().replace(".", "").replace(" ", "")
    if not cleaned:
        return None
    if "-" not in cleaned and len(cleaned) >= 2:
        cleaned = f"{cleaned[:-1]}-{cleaned[-1]}"
    return cleaned


def _period_date(periodo: str) -> date:
    year_text, month_text = periodo.split("-", 1)
    return date(int(year_text), int(month_text), 1)


def extract_validated_source() -> tuple[dict[str, list[dict]], dict]:
    findings = run_validation()
    errors = [f for f in findings if f.severidad == "ERROR"]
    warnings = [f for f in findings if f.severidad == "WARNING"]
    if errors:
        raise ValueError(
            f"Contratos/Remuneraciones fuente no supera calidad: {len(errors)} ERROR."
        )

    data = {
        "empleados": fetch_rows("staging.contratos_remuneraciones_empleado"),
        "contratos": fetch_rows("staging.contratos_remuneraciones_contrato"),
        "liquidaciones": fetch_rows("staging.contratos_remuneraciones_liquidacion"),
        "conceptos": fetch_rows("staging.contratos_remuneraciones_concepto_pago"),
        "detalles": fetch_rows("staging.contratos_remuneraciones_detalle_liquidacion"),
    }
    return data, {
        "procesados": sum(len(rows) for rows in data.values()),
        "errores": 0,
        "warnings": len(warnings),
    }


def _load_dw_context(cursor) -> dict:
    cursor.execute(
        """
        SELECT empleado_key, rut_normalizado, area_key, cargo_key,
               centro_costo_key, fecha_desde, fecha_hasta
        FROM dw.dim_empleado
        WHERE empleado_key <> 0
        ORDER BY rut_normalizado, fecha_desde
        """
    )
    empleados = defaultdict(list)
    for row in cursor.fetchall():
        empleados[row[1]].append(
            {
                "empleado_key": row[0],
                "area_key": row[2],
                "cargo_key": row[3],
                "centro_costo_key": row[4],
                "fecha_desde": row[5],
                "fecha_hasta": row[6],
            }
        )

    cursor.execute("SELECT fecha, fecha_key FROM dw.dim_fecha")
    fechas = dict(cursor.fetchall())

    cursor.execute("SELECT codigo_cargo, cargo_key FROM dw.dim_cargo")
    cargos = dict(cursor.fetchall())

    cursor.execute("SELECT numero_contrato, contrato_key FROM dw.dim_contrato")
    contratos = dict(cursor.fetchall())

    return {
        "empleados": empleados,
        "fechas": fechas,
        "cargos": cargos,
        "contratos": contratos,
    }


def _resolve_employee(versions: list[dict], event_date: date) -> dict | None:
    matches = [
        row for row in versions
        if row["fecha_desde"] <= event_date
        and (row["fecha_hasta"] is None or event_date < row["fecha_hasta"])
    ]
    if len(matches) != 1:
        return None
    return matches[0]


def build_contract_rows(data: dict[str, list[dict]], context: dict) -> tuple[list[dict], list[dict]]:
    empleados_fuente = {row["empleado_id"]: row for row in data["empleados"]}
    prepared = []
    review = []

    for row in data["contratos"]:
        emp_source = empleados_fuente.get(row["empleado_id"])
        rut = _canonical_rut(emp_source.get("rut_referencia") if emp_source else None)
        reasons = []

        if not rut_dv_valido(rut):
            employee = None
            reasons.append("RUT_NO_VALIDO_DV")
        else:
            employee = _resolve_employee(context["empleados"].get(rut, []), row["fecha_inicio"])
            if employee is None:
                reasons.append("EMPLEADO_SCD2_NO_RESUELTO")

        codigo_cargo = emp_source.get("codigo_cargo_ref") if emp_source else None
        cargo_key = context["cargos"].get(codigo_cargo, 0)
        if cargo_key == 0:
            reasons.append("CARGO_NO_RESUELTO")

        if reasons:
            review.append({
                "entidad": "Contrato",
                "contrato_id": row["contrato_id"],
                "numero_contrato": row["numero_contrato"],
                "reglas": reasons,
                "rut": rut,
                "codigo_cargo": codigo_cargo,
            })

        prepared.append({
            "numero_contrato": row["numero_contrato"],
            "empleado_key": employee["empleado_key"] if employee else 0,
            "cargo_key": cargo_key,
            "tipo_contrato": row["tipo_contrato"],
            "fecha_inicio": row["fecha_inicio"],
            "fecha_termino": row["fecha_termino"],
            "jornada": row["jornada"],
            "sueldo_base_contractual": row["sueldo_base"],
            "cargo_contrato": row["cargo_contrato"],
            "estado_contrato": row["estado"],
        })

    return prepared, review


def _classify_and_load_contracts(cursor, rows: list[dict]) -> dict:
    sql = (SQL_DIR / "cargar_dim_contrato.sql").read_text(encoding="utf-8")
    cursor.execute(
        """
        SELECT numero_contrato, empleado_key, cargo_key, tipo_contrato,
               fecha_inicio, fecha_termino, jornada, sueldo_base_contractual,
               cargo_contrato, estado_contrato
        FROM dw.dim_contrato
        WHERE contrato_key <> 0
        """
    )
    existing = {row[0]: tuple(row[1:]) for row in cursor.fetchall()}
    inserted = updated = unchanged = 0
    for row in rows:
        desired = (
            row["empleado_key"], row["cargo_key"], row["tipo_contrato"],
            row["fecha_inicio"], row["fecha_termino"], row["jornada"],
            row["sueldo_base_contractual"], row["cargo_contrato"], row["estado_contrato"],
        )
        current = existing.get(row["numero_contrato"])
        if current is None:
            inserted += 1
        elif current == desired:
            unchanged += 1
            continue
        else:
            updated += 1
        cursor.execute(sql, row)
    return {"inserted": inserted, "updated": updated, "unchanged": unchanged}


def build_fact_rows(data: dict[str, list[dict]], context: dict) -> tuple[list[dict], list[dict], list[dict]]:
    empleados_fuente = {row["empleado_id"]: row for row in data["empleados"]}
    contratos_fuente = {row["contrato_id"]: row for row in data["contratos"]}
    conceptos = {row["concepto_id"]: row for row in data["conceptos"]}

    totals = defaultdict(
        lambda: {
            "HABER": Decimal("0"),
            "DESCUENTO": Decimal("0"),
            "APORTE": Decimal("0"),
            "HORAS_EXTRA": Decimal("0"),
        }
    )
    for detail in data["detalles"]:
        concepto = conceptos.get(detail["concepto_id"])
        if concepto is None:
            continue

        monto = Decimal(str(detail["monto"]))
        totals[detail["liquidacion_id"]][concepto["tipo"]] += monto

        if concepto["codigo"] == "HORAS_EXTRA":
            totals[detail["liquidacion_id"]]["HORAS_EXTRA"] += monto

    prepared = []
    rejected = []
    review = []

    for row in data["liquidaciones"]:
        event_date = _period_date(row["periodo"])
        fecha_key = context["fechas"].get(event_date)
        if fecha_key is None:
            rejected.append({"liquidacion_id": row["liquidacion_id"], "regla": "FECHA_NO_RESUELTA"})
            continue

        emp_source = empleados_fuente.get(row["empleado_id"])
        rut = _canonical_rut(emp_source.get("rut_referencia") if emp_source else None)
        reasons = []
        if not rut_dv_valido(rut):
            employee = None
            reasons.append("RUT_NO_VALIDO_DV")
        else:
            employee = _resolve_employee(context["empleados"].get(rut, []), event_date)
            if employee is None:
                reasons.append("EMPLEADO_SCD2_NO_RESUELTO")

        contrato_source = contratos_fuente.get(row["contrato_id"])
        numero_contrato = contrato_source.get("numero_contrato") if contrato_source else None
        contrato_key = context["contratos"].get(numero_contrato, 0)
        if contrato_key == 0:
            reasons.append("CONTRATO_NO_RESUELTO")

        if employee is None or contrato_key == 0:
            review.append({
                "entidad": "Liquidacion",
                "liquidacion_id": row["liquidacion_id"],
                "periodo": row["periodo"],
                "reglas": reasons,
                "rut": rut,
                "numero_contrato": numero_contrato,
            })
            continue

        agg = totals[row["liquidacion_id"]]
        prepared.append({
            "fecha_key": fecha_key,
            "empleado_key": employee["empleado_key"],
            "area_key": employee["area_key"],
            "cargo_key": employee["cargo_key"],
            "centro_costo_key": employee["centro_costo_key"],
            "contrato_key": contrato_key,
            "periodo": row["periodo"],
            "sueldo_base": row["sueldo_base"],
            "horas_extras": row["horas_extras"],
            "costo_horas_extra": agg["HORAS_EXTRA"],
            "sueldo_imponible": row["sueldo_imponible"],
            "sueldo_liquido": row["sueldo_liquido"],
            "costo_empresa": row["costo_empresa"],
            "total_haberes": agg["HABER"],
            "total_descuentos": agg["DESCUENTO"],
            "total_aportes": agg["APORTE"],
            "cantidad_registros": 1,
        })

    return prepared, rejected, review


def _classify_and_load_facts(cursor, rows: list[dict]) -> dict:
    sql = (SQL_DIR / "cargar_fact_remuneraciones.sql").read_text(encoding="utf-8")
    cursor.execute(
        """
        SELECT empleado_key, periodo, fecha_key, area_key, cargo_key,
               centro_costo_key, contrato_key, sueldo_base, horas_extras,
               costo_horas_extra, sueldo_imponible, sueldo_liquido, costo_empresa,
               total_haberes, total_descuentos, total_aportes, cantidad_registros
        FROM dw.fact_remuneraciones
        """
    )
    existing = {(row[0], row[1]): tuple(row[2:]) for row in cursor.fetchall()}
    inserted = updated = unchanged = 0
    for row in rows:
        key = (row["empleado_key"], row["periodo"])
        desired = (
            row["fecha_key"], row["area_key"], row["cargo_key"], row["centro_costo_key"],
            row["contrato_key"], row["sueldo_base"], row["horas_extras"],
            row["costo_horas_extra"], row["sueldo_imponible"], row["sueldo_liquido"], row["costo_empresa"],
            row["total_haberes"], row["total_descuentos"], row["total_aportes"],
            row["cantidad_registros"],
        )
        current = existing.get(key)
        if current is None:
            inserted += 1
        elif current == desired:
            unchanged += 1
            continue
        else:
            updated += 1
        cursor.execute(sql, row)
    return {"inserted": inserted, "updated": updated, "unchanged": unchanged}


def run_dw_contratos_remuneraciones() -> dict:
    data, validation = extract_validated_source()
    config = get_dw_db_config()
    with get_postgres_connection(config) as connection:
        try:
            with connection.cursor() as cursor:
                context = _load_dw_context(cursor)
                contract_rows, contract_review = build_contract_rows(data, context)
                contract_metrics = _classify_and_load_contracts(cursor, contract_rows)

                context = _load_dw_context(cursor)
                fact_rows, rejected, fact_review = build_fact_rows(data, context)
                fact_metrics = _classify_and_load_facts(cursor, fact_rows)
            connection.commit()
        except Exception:
            connection.rollback()
            raise

    return {
        "source": {name: len(rows) for name, rows in data.items()},
        "source_validation": validation,
        "dim_contrato": contract_metrics,
        "fact_remuneraciones": fact_metrics,
        "prepared_facts": len(fact_rows),
        "rejected": rejected,
        "review": contract_review + fact_review,
    }
