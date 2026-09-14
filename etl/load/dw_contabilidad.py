from __future__ import annotations

from decimal import Decimal, ROUND_HALF_UP
from pathlib import Path

from psycopg.rows import dict_row

from etl.config.settings import get_contabilidad_db_config, get_dw_db_config
from etl.config.staging import get_staging_table_names
from etl.extract.postgres import get_postgres_connection
from etl.validate.contabilidad.runner import ENTITIES, prepare, validate


SQL_DIR = (
    Path(__file__).resolve().parents[1]
    / "sql"
    / "load"
    / "dw"
    / "contabilidad"
)

MONEY_QUANT = Decimal("0.01")


def _money(value) -> Decimal:
    return Decimal(str(value or 0)).quantize(MONEY_QUANT, rounding=ROUND_HALF_UP)


def extract_validated_contabilidad() -> tuple[dict[str, list[dict]], dict]:
    """Reutiliza el ETL operacional de Contabilidad ya validado.

    RAW y CLEAN se materializan como tablas TEMP dentro de una transacción de
    solo lectura lógica. Las reglas de calidad son exactamente las del cierre
    operacional; no se duplican en el loader del DW.
    """
    config = get_contabilidad_db_config()

    with get_postgres_connection(config) as connection:
        with connection.cursor(row_factory=dict_row) as cursor:
            cursor.execute("SET TRANSACTION ISOLATION LEVEL REPEATABLE READ")
            prepare(cursor, "raw")
            prepare(cursor, "clean")

            validation = validate(cursor)
            if validation["controles_error"] > 0:
                raise ValueError(
                    "Contabilidad fuente no supera los controles de calidad vigentes."
                )

            data: dict[str, list[dict]] = {}
            for entity in ENTITIES:
                table = get_staging_table_names("contabilidad", entity).clean
                cursor.execute(f"SELECT * FROM {table}")
                data[entity] = [dict(row) for row in cursor.fetchall()]

        connection.rollback()

    return data, validation


def build_dim_cuenta_rows(cuentas: list[dict]) -> list[dict]:
    codigo_por_id = {
        row["cuenta_id"]: row["codigo_cuenta"]
        for row in cuentas
    }

    result = []
    for row in cuentas:
        padre_id = row.get("cuenta_padre_id")
        codigo_padre = codigo_por_id.get(padre_id) if padre_id is not None else None

        if padre_id is not None and codigo_padre is None:
            raise ValueError(
                f"Cuenta padre local no resuelta para {row['codigo_cuenta']}: {padre_id}"
            )

        result.append(
            {
                "codigo_cuenta": row["codigo_cuenta"],
                "nombre_cuenta": row["nombre_cuenta"],
                "tipo_cuenta": row["tipo_cuenta"],
                "grupo": row["grupo"],
                "nivel": row["nivel"],
                "codigo_cuenta_padre": codigo_padre,
                "estado": row["estado"],
            }
        )

    return result


def _load_dim_cuenta(cursor, rows: list[dict]) -> dict:
    sql = (SQL_DIR / "cargar_dim_cuenta_contable.sql").read_text(encoding="utf-8")

    cursor.execute(
        """
        SELECT
            codigo_cuenta,
            nombre_cuenta,
            tipo_cuenta,
            grupo,
            nivel,
            codigo_cuenta_padre,
            estado
        FROM dw.dim_cuenta_contable
        WHERE cuenta_key <> 0
        """
    )
    existing = {
        row[0]: tuple(row[1:])
        for row in cursor.fetchall()
    }

    inserted = updated = unchanged = 0

    for row in rows:
        current = existing.get(row["codigo_cuenta"])
        desired = (
            row["nombre_cuenta"],
            row["tipo_cuenta"],
            row["grupo"],
            row["nivel"],
            row["codigo_cuenta_padre"],
            row["estado"],
        )

        if current is None:
            inserted += 1
        elif current == desired:
            unchanged += 1
            continue
        else:
            updated += 1

        cursor.execute(sql, row)

    return {
        "inserted": inserted,
        "updated": updated,
        "unchanged": unchanged,
    }


def _dimension_maps(cursor) -> dict:
    cursor.execute("SELECT fecha, fecha_key FROM dw.dim_fecha")
    fechas = dict(cursor.fetchall())

    cursor.execute("SELECT codigo_cuenta, cuenta_key FROM dw.dim_cuenta_contable")
    cuentas = dict(cursor.fetchall())

    cursor.execute("SELECT codigo_area, area_key FROM dw.dim_area")
    areas = dict(cursor.fetchall())

    cursor.execute(
        "SELECT codigo_centro_costo, centro_costo_key FROM dw.dim_centro_costo"
    )
    centros = dict(cursor.fetchall())

    return {
        "fechas": fechas,
        "cuentas": cuentas,
        "areas": areas,
        "centros": centros,
    }


def build_fact_rows(data: dict[str, list[dict]], maps: dict) -> tuple[list[dict], list[dict], list[dict]]:
    cuentas_por_id = {
        row["cuenta_id"]: row["codigo_cuenta"]
        for row in data["cuentas_contables"]
    }
    areas_por_id = {
        row["area_id"]: row["codigo_area"]
        for row in data["areas"]
    }
    centros_por_id = {
        row["centro_costo_id"]: row
        for row in data["centros_costo"]
    }

    prepared: list[dict] = []
    rejected: list[dict] = []
    review: list[dict] = []

    for row in data["movimientos_contables"]:
        movimiento_id = row["movimiento_id"]
        fecha_key = maps["fechas"].get(row["fecha"])

        if fecha_key is None:
            rejected.append(
                {
                    "movimiento_id": movimiento_id,
                    "regla": "FECHA_NO_RESUELTA",
                }
            )
            continue

        codigo_cuenta = cuentas_por_id.get(row["cuenta_id"])
        cuenta_key = maps["cuentas"].get(codigo_cuenta, 0)

        centro = centros_por_id.get(row["centro_costo_id"])
        codigo_centro = centro["codigo"] if centro else None
        centro_costo_key = maps["centros"].get(codigo_centro, 0)

        codigo_area = None
        if centro is not None:
            codigo_area = areas_por_id.get(centro["area_id"])
        area_key = maps["areas"].get(codigo_area, 0)

        reasons = []
        if cuenta_key == 0:
            reasons.append("CUENTA_NO_RESUELTA")
        if centro_costo_key == 0:
            reasons.append("CENTRO_COSTO_NO_RESUELTO")
        if area_key == 0:
            reasons.append("AREA_NO_RESUELTA")

        if reasons:
            review.append(
                {
                    "movimiento_id": movimiento_id,
                    "reglas": reasons,
                    "codigo_cuenta": codigo_cuenta,
                    "codigo_centro_costo": codigo_centro,
                    "codigo_area": codigo_area,
                }
            )

        debe_origen = _money(row["debe"])
        haber_origen = _money(row["haber"])
        tipo_cambio = Decimal(str(row["tipo_cambio"]))

        debe = (debe_origen * tipo_cambio).quantize(MONEY_QUANT, rounding=ROUND_HALF_UP)
        haber = (haber_origen * tipo_cambio).quantize(MONEY_QUANT, rounding=ROUND_HALF_UP)

        prepared.append(
            {
                "movimiento_id_origen": movimiento_id,
                "fecha_key": fecha_key,
                "cuenta_key": cuenta_key,
                "area_key": area_key,
                "centro_costo_key": centro_costo_key,
                "documento_tipo": row["documento_tipo"],
                "documento_numero": row["documento_numero"],
                "descripcion": row["descripcion"],
                "moneda_origen": row["moneda"],
                "tipo_cambio": tipo_cambio,
                "debe_origen": debe_origen,
                "haber_origen": haber_origen,
                "debe": debe,
                "haber": haber,
                "saldo": debe - haber,
                "cantidad_registros": 1,
            }
        )

    return prepared, rejected, review


def _load_fact(cursor, rows: list[dict]) -> dict:
    sql = (SQL_DIR / "cargar_fact_contabilidad.sql").read_text(encoding="utf-8")

    cursor.execute(
        """
        SELECT
            movimiento_id_origen,
            fecha_key,
            cuenta_key,
            area_key,
            centro_costo_key,
            documento_tipo,
            documento_numero,
            descripcion,
            moneda_origen,
            tipo_cambio,
            debe_origen,
            haber_origen,
            debe,
            haber,
            saldo,
            cantidad_registros
        FROM dw.fact_contabilidad
        """
    )
    existing = {
        row[0]: tuple(row[1:])
        for row in cursor.fetchall()
    }

    inserted = updated = unchanged = 0

    for row in rows:
        current = existing.get(row["movimiento_id_origen"])
        desired = (
            row["fecha_key"],
            row["cuenta_key"],
            row["area_key"],
            row["centro_costo_key"],
            row["documento_tipo"],
            row["documento_numero"],
            row["descripcion"],
            row["moneda_origen"],
            row["tipo_cambio"],
            row["debe_origen"],
            row["haber_origen"],
            row["debe"],
            row["haber"],
            row["saldo"],
            row["cantidad_registros"],
        )

        if current is None:
            inserted += 1
        elif current == desired:
            unchanged += 1
            continue
        else:
            updated += 1

        cursor.execute(sql, row)

    return {
        "inserted": inserted,
        "updated": updated,
        "unchanged": unchanged,
    }


def run_dw_contabilidad() -> dict:
    data, validation = extract_validated_contabilidad()
    dim_rows = build_dim_cuenta_rows(data["cuentas_contables"])

    config = get_dw_db_config()
    with get_postgres_connection(config) as connection:
        try:
            with connection.cursor() as cursor:
                dim_metrics = _load_dim_cuenta(cursor, dim_rows)
                maps = _dimension_maps(cursor)
                fact_rows, rejected, review = build_fact_rows(data, maps)
                fact_metrics = _load_fact(cursor, fact_rows)

            connection.commit()
        except Exception:
            connection.rollback()
            raise

    source_counts = {
        entity: len(data[entity])
        for entity in ENTITIES
    }

    return {
        "source": source_counts,
        "source_validation": {
            "procesados": validation["procesados"],
            "validos": validation["validos"],
            "errores": validation["errores"],
            "review": validation["review"],
        },
        "dim_cuenta_contable": dim_metrics,
        "fact_contabilidad": fact_metrics,
        "prepared": len(fact_rows),
        "rejected": rejected,
        "review": review,
    }
