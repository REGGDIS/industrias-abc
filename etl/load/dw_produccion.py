from __future__ import annotations

import csv
from collections import defaultdict
from dataclasses import dataclass
from datetime import date
from decimal import Decimal
from pathlib import Path
from typing import Any

from etl.config.settings import get_dw_db_config, get_produccion_db_config
from etl.extract.mysql import get_mysql_connection
from etl.extract.postgres import get_postgres_connection


ETL_DIR = Path(__file__).resolve().parents[1]
PROJECT_ROOT = ETL_DIR.parent
STAGING_SQL_DIR = ETL_DIR / "sql" / "staging" / "produccion"
MAPPINGS_DIR = ETL_DIR / "config" / "mappings"
CSV_CONSUMOS_PATH = (
    PROJECT_ROOT
    / "sources"
    / "produccion-mysql-csv"
    / "csv"
    / "consumo_insumos_complementario.csv"
)


@dataclass
class TargetLoadStats:
    inserted: int = 0
    updated: int = 0
    unchanged: int = 0
    review: int = 0

    @property
    def processed(self) -> int:
        return self.inserted + self.updated + self.unchanged


def _read_sql(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def _normalize_code(value: Any) -> str:
    return str(value).strip().upper()


def _as_decimal(value: Any) -> Decimal:
    if isinstance(value, Decimal):
        return value
    return Decimal(str(value))


def _as_date(value: Any) -> date:
    if isinstance(value, date):
        return value
    return date.fromisoformat(str(value))


def smart_date_key(value: date | None) -> int:
    if value is None:
        return 0
    return int(value.strftime("%Y%m%d"))


def extract_mysql_clean(sql_filename: str) -> list[dict[str, Any]]:
    sql = _read_sql(STAGING_SQL_DIR / sql_filename)
    config = get_produccion_db_config()

    with get_mysql_connection(config) as connection:
        with connection.cursor() as cursor:
            cursor.execute(sql)
            return list(cursor.fetchall())


def extract_mysql_raw_counts() -> dict[str, int]:
    config = get_produccion_db_config()
    queries = {
        "productos": "SELECT COUNT(*) AS total FROM productos;",
        "ordenes": "SELECT COUNT(*) AS total FROM ordenes_produccion;",
        "consumos": "SELECT COUNT(*) AS total FROM consumo_insumos;",
    }

    counts: dict[str, int] = {}

    with get_mysql_connection(config) as connection:
        with connection.cursor() as cursor:
            for name, sql in queries.items():
                cursor.execute(sql)
                row = cursor.fetchone()
                counts[name] = int(row["total"])

    return counts


def extract_productos_clean() -> list[dict[str, Any]]:
    return extract_mysql_clean("limpiar_productos.sql")


def extract_ordenes_clean() -> list[dict[str, Any]]:
    return extract_mysql_clean("limpiar_ordenes_produccion.sql")


def extract_consumos_clean() -> list[dict[str, Any]]:
    return extract_mysql_clean("limpiar_consumo_insumos.sql")


def read_csv_consumos(
    path: Path = CSV_CONSUMOS_PATH,
) -> tuple[list[dict[str, Any]], int, int]:
    rows: list[dict[str, Any]] = []
    rejected = 0
    total = 0

    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)

        required = {
            "numero_orden",
            "insumo_codigo_o_referencia",
            "cantidad_planificada",
            "cantidad_consumida",
            "fecha_consumo",
        }

        if set(reader.fieldnames or []) != required:
            missing = required - set(reader.fieldnames or [])
            extra = set(reader.fieldnames or []) - required
            raise RuntimeError(
                "Estructura CSV de Producción inesperada. "
                f"Faltantes={sorted(missing)} extra={sorted(extra)}"
            )

        for raw in reader:
            total += 1

            try:
                numero_orden = _normalize_code(raw["numero_orden"])
                insumo_codigo = _normalize_code(
                    raw["insumo_codigo_o_referencia"]
                )
                cantidad_planificada = _as_decimal(
                    raw["cantidad_planificada"]
                )
                cantidad_consumida = _as_decimal(
                    raw["cantidad_consumida"]
                )
                fecha_consumo = _as_date(raw["fecha_consumo"])

                if not numero_orden or not insumo_codigo:
                    raise ValueError("Código vacío")

                if cantidad_planificada < 0 or cantidad_consumida < 0:
                    raise ValueError("Cantidad negativa")

                rows.append(
                    {
                        "numero_orden": numero_orden,
                        "insumo_codigo_o_referencia": insumo_codigo,
                        "cantidad_planificada": cantidad_planificada,
                        "cantidad_consumida": cantidad_consumida,
                        "fecha_consumo": fecha_consumo,
                    }
                )
            except (TypeError, ValueError, ArithmeticError):
                rejected += 1

    return rows, total, rejected


def _consumo_match_key(row: dict[str, Any]) -> tuple[Any, ...]:
    return (
        _normalize_code(row["numero_orden"]),
        _as_decimal(row["cantidad_planificada"]),
        _as_decimal(row["cantidad_consumida"]),
        _as_date(row["fecha_consumo"]),
    )


def enrich_consumos_with_csv(
    mysql_rows: list[dict[str, Any]],
    csv_rows: list[dict[str, Any]],
) -> tuple[list[dict[str, Any]], int, int]:
    mysql_by_key: dict[tuple[Any, ...], list[dict[str, Any]]] = defaultdict(list)
    csv_by_key: dict[tuple[Any, ...], list[dict[str, Any]]] = defaultdict(list)

    for row in mysql_rows:
        normalized = dict(row)
        normalized["numero_orden"] = _normalize_code(row["numero_orden"])
        mysql_by_key[_consumo_match_key(normalized)].append(normalized)

    for row in csv_rows:
        csv_by_key[_consumo_match_key(row)].append(row)

    enriched: list[dict[str, Any]] = []
    review_mysql_rows = 0
    review_csv_rows = 0

    all_keys = set(mysql_by_key) | set(csv_by_key)

    for key in all_keys:
        mysql_group = mysql_by_key.get(key, [])
        csv_group = csv_by_key.get(key, [])

        if len(mysql_group) == 1 and len(csv_group) == 1:
            merged = dict(mysql_group[0])
            merged["insumo_codigo_origen"] = csv_group[0][
                "insumo_codigo_o_referencia"
            ]
            merged["csv_match_status"] = "MATCH"
            enriched.append(merged)
            continue

        for mysql_row in mysql_group:
            merged = dict(mysql_row)
            merged["insumo_codigo_origen"] = (
                f"ID_LOCAL:{mysql_row['insumo_id']}"
            )
            merged["csv_match_status"] = (
                "CSV_NO_MATCH" if not csv_group else "CSV_AMBIGUOUS"
            )
            enriched.append(merged)
            review_mysql_rows += 1

        review_csv_rows += len(csv_group)

    enriched.sort(key=lambda row: int(row["consumo_id"]))
    return enriched, review_mysql_rows, review_csv_rows


def _read_mapping_csv(filename: str) -> list[dict[str, str]]:
    path = MAPPINGS_DIR / filename

    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        return [
            {
                key: (value or "").strip()
                for key, value in row.items()
            }
            for row in csv.DictReader(handle)
        ]


def read_center_mapping() -> dict[int, tuple[str, str]]:
    mapping: dict[int, tuple[str, str]] = {}

    for row in _read_mapping_csv("produccion_centros_costo.csv"):
        status = _normalize_code(row.get("estado", ""))

        if status != "APROBADO":
            continue

        local_id_text = row.get("centro_costo_id", "")
        codigo_cc = _normalize_code(row.get("codigo_centro_costo", ""))
        codigo_area = _normalize_code(row.get("codigo_area", ""))

        if not local_id_text or not codigo_cc or not codigo_area:
            raise RuntimeError(
                "Mapping APROBADO de centro de costo incompleto."
            )

        local_id = int(local_id_text)

        if local_id in mapping:
            raise RuntimeError(
                f"centro_costo_id duplicado en mapping: {local_id}"
            )

        mapping[local_id] = (codigo_cc, codigo_area)

    return mapping


def read_insumo_mapping() -> dict[str, str]:
    mapping: dict[str, str] = {}

    for row in _read_mapping_csv("produccion_insumos.csv"):
        status = _normalize_code(row.get("estado", ""))

        if status != "APROBADO":
            continue

        source_code = _normalize_code(
            row.get("insumo_codigo_origen", "")
        )
        target_code = _normalize_code(
            row.get("codigo_insumo_dw", "")
        )

        if not source_code or not target_code:
            raise RuntimeError(
                "Mapping APROBADO de insumo incompleto."
            )

        if source_code in mapping:
            raise RuntimeError(
                f"Referencia de insumo duplicada en mapping: {source_code}"
            )

        mapping[source_code] = target_code

    return mapping


def _fetch_dimension_contracts(connection) -> dict[str, Any]:
    with connection.cursor() as cursor:
        cursor.execute(
            """
            SELECT producto_key, codigo_producto
            FROM dw.dim_producto;
            """
        )
        productos = {
            row[1]: int(row[0])
            for row in cursor.fetchall()
        }

        cursor.execute(
            """
            SELECT centro_costo_key, codigo_centro_costo
            FROM dw.dim_centro_costo;
            """
        )
        centros = {
            row[1]: int(row[0])
            for row in cursor.fetchall()
        }

        cursor.execute(
            """
            SELECT area_key, codigo_area
            FROM dw.dim_area;
            """
        )
        areas = {
            row[1]: int(row[0])
            for row in cursor.fetchall()
        }

        cursor.execute(
            """
            SELECT insumo_key, codigo_insumo
            FROM dw.dim_insumo;
            """
        )
        insumos = {
            row[1]: int(row[0])
            for row in cursor.fetchall()
        }

        cursor.execute("SELECT fecha_key FROM dw.dim_fecha;")
        fechas = {
            int(row[0])
            for row in cursor.fetchall()
        }

    return {
        "productos": productos,
        "centros": centros,
        "areas": areas,
        "insumos": insumos,
        "fechas": fechas,
    }


def load_dim_producto(
    connection,
    rows: list[dict[str, Any]],
) -> TargetLoadStats:
    stats = TargetLoadStats()

    select_sql = """
        SELECT
            producto_key,
            nombre_producto,
            categoria,
            unidad_medida
        FROM dw.dim_producto
        WHERE codigo_producto = %s;
    """

    insert_sql = """
        INSERT INTO dw.dim_producto (
            codigo_producto,
            nombre_producto,
            categoria,
            unidad_medida
        )
        VALUES (%s, %s, %s, %s);
    """

    update_sql = """
        UPDATE dw.dim_producto
        SET
            nombre_producto = %s,
            categoria = %s
        WHERE codigo_producto = %s;
    """

    with connection.cursor() as cursor:
        for row in rows:
            codigo = _normalize_code(row["codigo_producto"])
            nombre = str(row["nombre_producto"]).strip()
            categoria = str(row["categoria"]).strip()
            unidad = _normalize_code(row["unidad_medida"])

            cursor.execute(select_sql, (codigo,))
            current = cursor.fetchone()

            if current is None:
                cursor.execute(
                    insert_sql,
                    (codigo, nombre, categoria, unidad),
                )
                stats.inserted += 1
                continue

            _, old_nombre, old_categoria, old_unidad = current

            if _normalize_code(old_unidad) != unidad:
                stats.review += 1
                continue

            if old_nombre == nombre and old_categoria == categoria:
                stats.unchanged += 1
                continue

            cursor.execute(
                update_sql,
                (nombre, categoria, codigo),
            )
            stats.updated += 1

    return stats


def prepare_fact_produccion(
    rows: list[dict[str, Any]],
    productos_by_id: dict[int, str],
    contracts: dict[str, Any],
    center_mapping: dict[int, tuple[str, str]],
) -> tuple[list[dict[str, Any]], int]:
    prepared: list[dict[str, Any]] = []
    review_rows = 0

    for row in rows:
        needs_review = False

        producto_code = productos_by_id.get(int(row["producto_id"]))
        producto_key = contracts["productos"].get(producto_code or "", 0)

        if producto_key == 0:
            needs_review = True

        local_cc = int(row["centro_costo_id"])
        mapping = center_mapping.get(local_cc)

        if mapping is None:
            centro_key = 0
            area_key = 0
            needs_review = True
        else:
            codigo_cc, codigo_area = mapping
            centro_key = contracts["centros"].get(codigo_cc, 0)
            area_key = contracts["areas"].get(codigo_area, 0)

            if centro_key == 0 or area_key == 0:
                needs_review = True

        fecha_inicio = _as_date(row["fecha_inicio"])
        fecha_inicio_key = smart_date_key(fecha_inicio)

        if fecha_inicio_key not in contracts["fechas"]:
            fecha_inicio_key = 0
            needs_review = True

        fecha_termino = row["fecha_termino"]
        fecha_termino_key = smart_date_key(
            _as_date(fecha_termino) if fecha_termino is not None else None
        )

        if (
            fecha_termino_key != 0
            and fecha_termino_key not in contracts["fechas"]
        ):
            fecha_termino_key = 0
            needs_review = True

        prepared.append(
            {
                "fecha_inicio_key": fecha_inicio_key,
                "fecha_termino_key": fecha_termino_key,
                "producto_key": producto_key,
                "centro_costo_key": centro_key,
                "area_key": area_key,
                "numero_orden": _normalize_code(row["numero_orden"]),
                "cantidad_planificada": _as_decimal(
                    row["cantidad_planificada"]
                ),
                "cantidad_producida": _as_decimal(
                    row["cantidad_producida"]
                ),
                "cantidad_rechazada": _as_decimal(
                    row["cantidad_rechazada"]
                ),
                "estado": _normalize_code(row["estado"]),
            }
        )

        if needs_review:
            review_rows += 1

    return prepared, review_rows


def _fact_produccion_tuple(row: dict[str, Any]) -> tuple[Any, ...]:
    return (
        row["fecha_inicio_key"],
        row["fecha_termino_key"],
        row["producto_key"],
        row["centro_costo_key"],
        row["area_key"],
        row["cantidad_planificada"],
        row["cantidad_producida"],
        row["cantidad_rechazada"],
        row["estado"],
    )


def load_fact_produccion(
    connection,
    rows: list[dict[str, Any]],
) -> TargetLoadStats:
    stats = TargetLoadStats()

    select_sql = """
        SELECT
            fecha_inicio_key,
            fecha_termino_key,
            producto_key,
            centro_costo_key,
            area_key,
            cantidad_planificada,
            cantidad_producida,
            cantidad_rechazada,
            estado
        FROM dw.fact_produccion
        WHERE numero_orden = %s;
    """

    insert_sql = """
        INSERT INTO dw.fact_produccion (
            fecha_inicio_key,
            fecha_termino_key,
            producto_key,
            centro_costo_key,
            area_key,
            numero_orden,
            cantidad_planificada,
            cantidad_producida,
            cantidad_rechazada,
            estado
        )
        VALUES (
            %(fecha_inicio_key)s,
            %(fecha_termino_key)s,
            %(producto_key)s,
            %(centro_costo_key)s,
            %(area_key)s,
            %(numero_orden)s,
            %(cantidad_planificada)s,
            %(cantidad_producida)s,
            %(cantidad_rechazada)s,
            %(estado)s
        );
    """

    update_sql = """
        UPDATE dw.fact_produccion
        SET
            fecha_inicio_key = %(fecha_inicio_key)s,
            fecha_termino_key = %(fecha_termino_key)s,
            producto_key = %(producto_key)s,
            centro_costo_key = %(centro_costo_key)s,
            area_key = %(area_key)s,
            cantidad_planificada = %(cantidad_planificada)s,
            cantidad_producida = %(cantidad_producida)s,
            cantidad_rechazada = %(cantidad_rechazada)s,
            estado = %(estado)s
        WHERE numero_orden = %(numero_orden)s;
    """

    with connection.cursor() as cursor:
        for row in rows:
            cursor.execute(select_sql, (row["numero_orden"],))
            current = cursor.fetchone()

            if current is None:
                cursor.execute(insert_sql, row)
                stats.inserted += 1
                continue

            if tuple(current) == _fact_produccion_tuple(row):
                stats.unchanged += 1
                continue

            cursor.execute(update_sql, row)
            stats.updated += 1

    return stats


def prepare_fact_consumo(
    rows: list[dict[str, Any]],
    ordenes_by_numero: dict[str, dict[str, Any]],
    contracts: dict[str, Any],
    insumo_mapping: dict[str, str],
) -> tuple[list[dict[str, Any]], int]:
    prepared: list[dict[str, Any]] = []
    review_rows = 0

    for row in rows:
        needs_review = row.get("csv_match_status") != "MATCH"
        numero_orden = _normalize_code(row["numero_orden"])
        order = ordenes_by_numero.get(numero_orden)

        if order is None:
            product_key = 0
            centro_key = 0
            area_key = 0
            needs_review = True
        else:
            product_key = int(order["producto_key"])
            centro_key = int(order["centro_costo_key"])
            area_key = int(order["area_key"])

        fecha_key = smart_date_key(_as_date(row["fecha_consumo"]))

        if fecha_key not in contracts["fechas"]:
            fecha_key = 0
            needs_review = True

        source_insumo = _normalize_code(row["insumo_codigo_origen"])
        target_insumo = insumo_mapping.get(source_insumo)
        insumo_key = contracts["insumos"].get(target_insumo or "", 0)

        if insumo_key == 0:
            needs_review = True

        prepared.append(
            {
                "fecha_consumo_key": fecha_key,
                "producto_key": product_key,
                "insumo_key": insumo_key,
                "centro_costo_key": centro_key,
                "area_key": area_key,
                "numero_orden": numero_orden,
                "consumo_id": int(row["consumo_id"]),
                "insumo_codigo_origen": source_insumo,
                "cantidad_planificada": _as_decimal(
                    row["cantidad_planificada"]
                ),
                "cantidad_consumida": _as_decimal(
                    row["cantidad_consumida"]
                ),
            }
        )

        if needs_review:
            review_rows += 1

    return prepared, review_rows


def _fact_consumo_tuple(row: dict[str, Any]) -> tuple[Any, ...]:
    return (
        row["fecha_consumo_key"],
        row["producto_key"],
        row["insumo_key"],
        row["centro_costo_key"],
        row["area_key"],
        row["numero_orden"],
        row["insumo_codigo_origen"],
        row["cantidad_planificada"],
        row["cantidad_consumida"],
    )


def load_fact_consumo(
    connection,
    rows: list[dict[str, Any]],
) -> TargetLoadStats:
    stats = TargetLoadStats()

    select_sql = """
        SELECT
            fecha_consumo_key,
            producto_key,
            insumo_key,
            centro_costo_key,
            area_key,
            numero_orden,
            insumo_codigo_origen,
            cantidad_planificada,
            cantidad_consumida
        FROM dw.fact_consumo_insumo
        WHERE consumo_id = %s;
    """

    insert_sql = """
        INSERT INTO dw.fact_consumo_insumo (
            fecha_consumo_key,
            producto_key,
            insumo_key,
            centro_costo_key,
            area_key,
            numero_orden,
            consumo_id,
            insumo_codigo_origen,
            cantidad_planificada,
            cantidad_consumida
        )
        VALUES (
            %(fecha_consumo_key)s,
            %(producto_key)s,
            %(insumo_key)s,
            %(centro_costo_key)s,
            %(area_key)s,
            %(numero_orden)s,
            %(consumo_id)s,
            %(insumo_codigo_origen)s,
            %(cantidad_planificada)s,
            %(cantidad_consumida)s
        );
    """

    update_sql = """
        UPDATE dw.fact_consumo_insumo
        SET
            fecha_consumo_key = %(fecha_consumo_key)s,
            producto_key = %(producto_key)s,
            insumo_key = %(insumo_key)s,
            centro_costo_key = %(centro_costo_key)s,
            area_key = %(area_key)s,
            numero_orden = %(numero_orden)s,
            insumo_codigo_origen = %(insumo_codigo_origen)s,
            cantidad_planificada = %(cantidad_planificada)s,
            cantidad_consumida = %(cantidad_consumida)s
        WHERE consumo_id = %(consumo_id)s;
    """

    with connection.cursor() as cursor:
        for row in rows:
            cursor.execute(select_sql, (row["consumo_id"],))
            current = cursor.fetchone()

            if current is None:
                cursor.execute(insert_sql, row)
                stats.inserted += 1
                continue

            if tuple(current) == _fact_consumo_tuple(row):
                stats.unchanged += 1
                continue

            cursor.execute(update_sql, row)
            stats.updated += 1

    return stats


def run_dw_produccion_load() -> dict[str, Any]:
    raw_counts = extract_mysql_raw_counts()
    productos = extract_productos_clean()
    ordenes = extract_ordenes_clean()
    consumos_mysql = extract_consumos_clean()
    consumos_csv, csv_total, csv_rejected = read_csv_consumos()

    consumos_enriched, csv_review_mysql, csv_review_rows = (
        enrich_consumos_with_csv(consumos_mysql, consumos_csv)
    )

    productos_by_id = {
        int(row["producto_id"]): _normalize_code(row["codigo_producto"])
        for row in productos
    }

    center_mapping = read_center_mapping()
    insumo_mapping = read_insumo_mapping()

    dw_config = get_dw_db_config()

    with get_postgres_connection(dw_config) as connection:
        dim_stats = load_dim_producto(connection, productos)
        contracts = _fetch_dimension_contracts(connection)

        prepared_orders, order_review = prepare_fact_produccion(
            ordenes,
            productos_by_id,
            contracts,
            center_mapping,
        )
        fact_prod_stats = load_fact_produccion(
            connection,
            prepared_orders,
        )

        orders_by_numero = {
            row["numero_orden"]: row
            for row in prepared_orders
        }

        prepared_consumos, consumo_review = prepare_fact_consumo(
            consumos_enriched,
            orders_by_numero,
            contracts,
            insumo_mapping,
        )
        fact_consumo_stats = load_fact_consumo(
            connection,
            prepared_consumos,
        )

        connection.commit()

    mysql_rejected = (
        raw_counts["productos"] - len(productos)
        + raw_counts["ordenes"] - len(ordenes)
        + raw_counts["consumos"] - len(consumos_mysql)
    )

    records_read = (
        raw_counts["productos"]
        + raw_counts["ordenes"]
        + raw_counts["consumos"]
        + csv_total
    )
    records_valid = (
        len(productos)
        + len(ordenes)
        + len(consumos_mysql)
        + len(consumos_csv)
    )
    records_rejected = mysql_rejected + csv_rejected

    records_inserted = (
        dim_stats.inserted
        + fact_prod_stats.inserted
        + fact_consumo_stats.inserted
    )
    records_updated = (
        dim_stats.updated
        + fact_prod_stats.updated
        + fact_consumo_stats.updated
    )
    records_unchanged = (
        dim_stats.unchanged
        + fact_prod_stats.unchanged
        + fact_consumo_stats.unchanged
    )
    records_review = (
        dim_stats.review
        + order_review
        + consumo_review
        + csv_review_rows
    )

    return {
        "records_read": records_read,
        "records_valid": records_valid,
        "records_rejected": records_rejected,
        "records_inserted": records_inserted,
        "records_updated": records_updated,
        "records_unchanged": records_unchanged,
        "records_review": records_review,
        "source": {
            "productos_raw": raw_counts["productos"],
            "ordenes_raw": raw_counts["ordenes"],
            "consumos_mysql_raw": raw_counts["consumos"],
            "consumos_csv_raw": csv_total,
            "csv_mysql_rows_review": csv_review_mysql,
        },
        "dim_producto": dim_stats.__dict__,
        "fact_produccion": fact_prod_stats.__dict__,
        "fact_consumo_insumo": fact_consumo_stats.__dict__,
    }
