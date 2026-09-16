from __future__ import annotations

from collections import defaultdict
from decimal import Decimal, ROUND_HALF_UP
from pathlib import Path

from psycopg.rows import dict_row

from etl.config.settings import get_compras_db_config, get_dw_db_config
from etl.extract.postgres import get_postgres_connection
from etl.load.dw_rrhh import rut_dv_valido


SQL_DIR = Path(__file__).resolve().parents[1] / "sql" / "load" / "dw" / "compras"
MONEY = Decimal("0.01")


def _money(value) -> Decimal:
    return Decimal(str(value or 0)).quantize(MONEY, rounding=ROUND_HALF_UP)


def normalize_rut(rut: str | None) -> str | None:
    if rut is None:
        return None
    value = str(rut).strip().upper().replace(".", "").replace(" ", "")
    return value or None


def extract_compras_source() -> dict[str, list[dict]]:
    """Lee una fotografía consistente de la fuente operacional de Compras.

    El staging histórico de Compras está implementado como consultas y fixtures,
    no como tablas CLEAN persistentes. Por eso el loader aplica aquí exactamente
    la limpieza segura (TRIM/UPPER) ya documentada por el dominio, mientras la
    validación transaccional oficial se ejecuta antes desde el runner.
    """
    queries = {
        "areas": """
            SELECT area_id, UPPER(TRIM(codigo_area)) AS codigo_area,
                   TRIM(nombre_area) AS nombre_area
            FROM areas ORDER BY area_id
        """,
        "centros_costo": """
            SELECT centro_costo_id, UPPER(TRIM(codigo_centro)) AS codigo_centro,
                   TRIM(nombre_centro) AS nombre_centro, area_id,
                   UPPER(TRIM(estado)) AS estado
            FROM centros_costo ORDER BY centro_costo_id
        """,
        "compradores": """
            SELECT comprador_id, UPPER(TRIM(codigo_comprador)) AS codigo_comprador,
                   TRIM(nombre_comprador) AS nombre_comprador, area_id,
                   UPPER(TRIM(estado)) AS estado
            FROM compradores ORDER BY comprador_id
        """,
        "proveedores": """
            SELECT proveedor_id, TRIM(rut_proveedor) AS rut_proveedor,
                   TRIM(razon_social) AS razon_social,
                   NULLIF(TRIM(nombre_fantasia), '') AS nombre_fantasia,
                   NULLIF(TRIM(categoria), '') AS categoria,
                   NULLIF(TRIM(region), '') AS region,
                   NULLIF(TRIM(comuna), '') AS comuna,
                   UPPER(TRIM(estado)) AS estado
            FROM proveedores ORDER BY proveedor_id
        """,
        "categorias_insumo": """
            SELECT categoria_id, UPPER(TRIM(codigo_categoria)) AS codigo_categoria,
                   TRIM(nombre_categoria) AS nombre_categoria
            FROM categorias_insumo ORDER BY categoria_id
        """,
        "insumos": """
            SELECT insumo_id, UPPER(TRIM(codigo_insumo)) AS codigo_insumo,
                   TRIM(nombre_insumo) AS nombre_insumo, categoria_id,
                   UPPER(TRIM(unidad_medida)) AS unidad_medida,
                   stock_minimo, UPPER(TRIM(estado)) AS estado
            FROM insumos ORDER BY insumo_id
        """,
        "ordenes_compra": """
            SELECT oc_id, UPPER(TRIM(numero_oc)) AS numero_oc, proveedor_id,
                   fecha_emision, fecha_requerida, centro_costo_id, comprador_id,
                   UPPER(TRIM(estado)) AS estado, UPPER(TRIM(moneda)) AS moneda,
                   subtotal, impuesto, total
            FROM ordenes_compra ORDER BY oc_id
        """,
        "detalle_orden_compra": """
            SELECT detalle_id, oc_id, insumo_id, cantidad, precio_unitario,
                   descuento, subtotal
            FROM detalle_orden_compra ORDER BY detalle_id
        """,
        "recepciones": """
            SELECT recepcion_id, oc_id, fecha_recepcion,
                   UPPER(TRIM(estado)) AS estado
            FROM recepciones ORDER BY recepcion_id
        """,
        "detalle_recepcion": """
            SELECT detalle_recepcion_id, recepcion_id, detalle_id,
                   cantidad_recibida, cantidad_rechazada,
                   CASE WHEN estado IS NULL THEN NULL ELSE UPPER(TRIM(estado)) END AS estado
            FROM detalle_recepcion ORDER BY detalle_recepcion_id
        """,
    }

    config = get_compras_db_config()
    data: dict[str, list[dict]] = {}
    with get_postgres_connection(config) as connection:
        with connection.cursor(row_factory=dict_row) as cursor:
            cursor.execute("SET TRANSACTION ISOLATION LEVEL REPEATABLE READ")
            for entity, sql in queries.items():
                cursor.execute(sql)
                data[entity] = [dict(row) for row in cursor.fetchall()]
        connection.rollback()
    return data


def build_dim_proveedor_rows(proveedores: list[dict]) -> tuple[list[dict], list[dict]]:
    rows: list[dict] = []
    rejected: list[dict] = []
    seen: set[str] = set()

    for source in proveedores:
        rut = normalize_rut(source.get("rut_proveedor"))
        if rut is None or not rut_dv_valido(rut):
            rejected.append({
                "entidad": "proveedor",
                "proveedor_id": source.get("proveedor_id"),
                "regla": "RUT_PROVEEDOR_INVALIDO",
                "rut": source.get("rut_proveedor"),
            })
            continue
        if rut in seen:
            rejected.append({
                "entidad": "proveedor",
                "proveedor_id": source.get("proveedor_id"),
                "regla": "RUT_PROVEEDOR_DUPLICADO_NORMALIZADO",
                "rut": rut,
            })
            continue
        seen.add(rut)
        rows.append({
            "rut_proveedor_normalizado": rut,
            "razon_social": source["razon_social"],
            "nombre_fantasia": source.get("nombre_fantasia"),
            "categoria": source.get("categoria"),
            "region": source.get("region"),
            "comuna": source.get("comuna"),
            "estado": source.get("estado"),
            "codigo_proveedor_ref": None,
        })
    return rows, rejected


def build_dim_insumo_rows(insumos: list[dict], categorias: list[dict]) -> list[dict]:
    categorias_por_id = {r["categoria_id"]: r for r in categorias}
    result = []
    for source in insumos:
        categoria = categorias_por_id.get(source["categoria_id"])
        if categoria is None:
            raise ValueError(
                f"Categoría local no resuelta para insumo {source['codigo_insumo']}"
            )
        result.append({
            "codigo_insumo": source["codigo_insumo"],
            "nombre_insumo": source["nombre_insumo"],
            "codigo_categoria": categoria["codigo_categoria"],
            "nombre_categoria": categoria["nombre_categoria"],
            "unidad_medida": source["unidad_medida"],
            "stock_minimo": source["stock_minimo"],
            "estado": source["estado"],
        })
    return result


def _load_dim_proveedor(cursor, rows: list[dict]) -> dict:
    sql = (SQL_DIR / "cargar_dim_proveedor.sql").read_text(encoding="utf-8")
    cursor.execute("""
        SELECT rut_proveedor_normalizado, razon_social, nombre_fantasia,
               categoria, region, comuna, estado, codigo_proveedor_ref
        FROM dw.dim_proveedor WHERE proveedor_key <> 0
    """)
    existing = {r[0]: tuple(r[1:]) for r in cursor.fetchall()}
    inserted = updated = unchanged = 0
    for row in rows:
        current = existing.get(row["rut_proveedor_normalizado"])
        desired = (
            row["razon_social"], row["nombre_fantasia"], row["categoria"],
            row["region"], row["comuna"], row["estado"],
            row["codigo_proveedor_ref"],
        )
        if current is None:
            inserted += 1
        elif current == desired:
            unchanged += 1
            continue
        else:
            updated += 1
        cursor.execute(sql, row)
    return {"inserted": inserted, "updated": updated, "unchanged": unchanged}


def _load_dim_insumo(cursor, rows: list[dict]) -> tuple[dict, list[dict]]:
    sql = (SQL_DIR / "cargar_dim_insumo.sql").read_text(encoding="utf-8")
    cursor.execute("""
        SELECT codigo_insumo, nombre_insumo, codigo_categoria, nombre_categoria,
               unidad_medida, stock_minimo, estado
        FROM dw.dim_insumo WHERE insumo_key <> 0
    """)
    existing = {r[0]: tuple(r[1:]) for r in cursor.fetchall()}
    inserted = updated = unchanged = 0
    review: list[dict] = []
    for row in rows:
        current = existing.get(row["codigo_insumo"])
        desired = (
            row["nombre_insumo"], row["codigo_categoria"],
            row["nombre_categoria"], row["unidad_medida"],
            row["stock_minimo"], row["estado"],
        )
        if current is None:
            inserted += 1
        elif current == desired:
            unchanged += 1
            continue
        elif current[3] != row["unidad_medida"]:
            unchanged += 1
            review.append({
                "entidad": "insumo",
                "codigo_insumo": row["codigo_insumo"],
                "regla": "CAMBIO_UNIDAD_MEDIDA",
                "unidad_actual": current[3],
                "unidad_fuente": row["unidad_medida"],
            })
            continue
        else:
            updated += 1
        cursor.execute(sql, row)
    return {"inserted": inserted, "updated": updated, "unchanged": unchanged}, review


def _dimension_maps(cursor) -> dict:
    cursor.execute("SELECT fecha, fecha_key FROM dw.dim_fecha")
    fechas = dict(cursor.fetchall())
    cursor.execute("SELECT rut_proveedor_normalizado, proveedor_key FROM dw.dim_proveedor")
    proveedores = dict(cursor.fetchall())
    cursor.execute("SELECT codigo_insumo, insumo_key FROM dw.dim_insumo")
    insumos = dict(cursor.fetchall())
    cursor.execute("SELECT codigo_centro_costo, centro_costo_key FROM dw.dim_centro_costo")
    centros = dict(cursor.fetchall())
    cursor.execute("SELECT codigo_area, area_key FROM dw.dim_area")
    areas = dict(cursor.fetchall())
    return {
        "fechas": fechas,
        "proveedores": proveedores,
        "insumos": insumos,
        "centros": centros,
        "areas": areas,
    }


def _prorated_tax_by_detail(data: dict[str, list[dict]]) -> tuple[dict[int, Decimal], list[dict]]:
    orders = {r["oc_id"]: r for r in data["ordenes_compra"]}
    details_by_order: dict[int, list[dict]] = defaultdict(list)
    for detail in data["detalle_orden_compra"]:
        details_by_order[detail["oc_id"]].append(detail)

    result: dict[int, Decimal] = {}
    review: list[dict] = []
    for oc_id, details in details_by_order.items():
        order = orders.get(oc_id)
        if order is None:
            continue
        header_subtotal = _money(order["subtotal"])
        header_tax = _money(order["impuesto"])
        detail_sum = sum((_money(d["subtotal"]) for d in details), Decimal("0.00"))
        if detail_sum != header_subtotal:
            review.append({
                "entidad": "orden_compra",
                "numero_oc": order["numero_oc"],
                "regla": "SUBTOTAL_CABECERA_DIFIERE_DE_LINEAS",
                "subtotal_cabecera": str(header_subtotal),
                "subtotal_lineas": str(detail_sum),
            })
        if header_subtotal == 0:
            if header_tax != 0:
                review.append({
                    "entidad": "orden_compra",
                    "numero_oc": order["numero_oc"],
                    "regla": "IMPUESTO_NO_PRORRATEABLE",
                })
            for detail in details:
                result[detail["detalle_id"]] = Decimal("0.00")
            continue

        allocated = Decimal("0.00")
        for index, detail in enumerate(details):
            if index == len(details) - 1:
                tax = header_tax - allocated
            else:
                tax = (
                    header_tax * _money(detail["subtotal"]) / header_subtotal
                ).quantize(MONEY, rounding=ROUND_HALF_UP)
                allocated += tax
            result[detail["detalle_id"]] = tax
    return result, review


def build_fact_rows(data: dict[str, list[dict]], maps: dict) -> tuple[list[dict], list[dict], list[dict]]:
    orders = {r["oc_id"]: r for r in data["ordenes_compra"]}
    providers = {r["proveedor_id"]: r for r in data["proveedores"]}
    insumos = {r["insumo_id"]: r for r in data["insumos"]}
    centers = {r["centro_costo_id"]: r for r in data["centros_costo"]}
    areas = {r["area_id"]: r for r in data["areas"]}
    buyers = {r["comprador_id"]: r for r in data["compradores"]}

    received: dict[int, tuple[Decimal, Decimal]] = defaultdict(
        lambda: (Decimal("0.00"), Decimal("0.00"))
    )
    for row in data["detalle_recepcion"]:
        current_received, current_rejected = received[row["detalle_id"]]
        received[row["detalle_id"]] = (
            current_received + _money(row["cantidad_recibida"]),
            current_rejected + _money(row["cantidad_rechazada"]),
        )

    tax_by_detail, review = _prorated_tax_by_detail(data)
    prepared: list[dict] = []
    rejected: list[dict] = []

    for detail in data["detalle_orden_compra"]:
        order = orders.get(detail["oc_id"])
        insumo = insumos.get(detail["insumo_id"])
        if order is None or insumo is None:
            rejected.append({
                "detalle_id": detail["detalle_id"],
                "regla": "RELACION_LOCAL_NO_RESUELTA",
            })
            continue

        fecha_emision_key = maps["fechas"].get(order["fecha_emision"])
        if fecha_emision_key is None:
            rejected.append({
                "detalle_id": detail["detalle_id"],
                "numero_oc": order["numero_oc"],
                "regla": "FECHA_EMISION_NO_RESUELTA",
            })
            continue

        if order["fecha_requerida"] is None:
            fecha_requerida_key = 0
        else:
            fecha_requerida_key = maps["fechas"].get(order["fecha_requerida"])
            if fecha_requerida_key is None:
                rejected.append({
                    "detalle_id": detail["detalle_id"],
                    "numero_oc": order["numero_oc"],
                    "regla": "FECHA_REQUERIDA_NO_RESUELTA",
                })
                continue

        provider = providers.get(order["proveedor_id"])
        provider_rut = normalize_rut(provider.get("rut_proveedor")) if provider else None
        provider_key = maps["proveedores"].get(provider_rut, 0)

        insumo_key = maps["insumos"].get(insumo["codigo_insumo"], 0)
        if insumo_key == 0:
            rejected.append({
                "detalle_id": detail["detalle_id"],
                "numero_oc": order["numero_oc"],
                "regla": "INSUMO_NO_RESUELTO",
                "codigo_insumo": insumo["codigo_insumo"],
            })
            continue

        center = centers.get(order["centro_costo_id"])
        center_code = center["codigo_centro"] if center else None
        centro_key = maps["centros"].get(center_code, 0)
        area = areas.get(center["area_id"]) if center else None
        area_code = area["codigo_area"] if area else None
        area_key = maps["areas"].get(area_code, 0)

        reasons = []
        if provider_key == 0:
            reasons.append("PROVEEDOR_NO_RESUELTO")
        if centro_key == 0:
            reasons.append("CENTRO_COSTO_NO_RESUELTO")
        if area_key == 0:
            reasons.append("AREA_NO_RESUELTA")
        if reasons:
            review.append({
                "detalle_id": detail["detalle_id"],
                "numero_oc": order["numero_oc"],
                "reglas": reasons,
            })

        buyer = buyers.get(order["comprador_id"])
        rec, rej = received[detail["detalle_id"]]
        subtotal = _money(detail["subtotal"])
        tax = tax_by_detail.get(detail["detalle_id"], Decimal("0.00"))
        prepared.append({
            "fecha_emision_key": fecha_emision_key,
            "fecha_requerida_key": fecha_requerida_key,
            "proveedor_key": provider_key,
            "insumo_key": insumo_key,
            "centro_costo_key": centro_key,
            "area_key": area_key,
            "numero_oc": order["numero_oc"],
            "codigo_comprador": buyer["codigo_comprador"] if buyer else None,
            "estado_oc": order["estado"],
            "moneda_origen": order["moneda"],
            "cantidad": _money(detail["cantidad"]),
            "precio_unitario": _money(detail["precio_unitario"]),
            "descuento": _money(detail["descuento"]),
            "subtotal": subtotal,
            "impuesto": tax,
            "total": subtotal + tax,
            "cantidad_recibida": rec,
            "cantidad_rechazada": rej,
            "cantidad_lineas": 1,
        })
    return prepared, rejected, review


def _load_fact(cursor, rows: list[dict]) -> dict:
    sql = (SQL_DIR / "cargar_fact_compras.sql").read_text(encoding="utf-8")
    cursor.execute("""
        SELECT numero_oc, insumo_key, fecha_emision_key, fecha_requerida_key,
               proveedor_key, centro_costo_key, area_key, codigo_comprador,
               estado_oc, moneda_origen, cantidad, precio_unitario, descuento,
               subtotal, impuesto, total, cantidad_recibida, cantidad_rechazada,
               cantidad_lineas
        FROM dw.fact_compras
    """)
    existing = {(r[0], r[1]): tuple(r[2:]) for r in cursor.fetchall()}
    inserted = updated = unchanged = 0
    for row in rows:
        key = (row["numero_oc"], row["insumo_key"])
        desired = (
            row["fecha_emision_key"], row["fecha_requerida_key"],
            row["proveedor_key"], row["centro_costo_key"], row["area_key"],
            row["codigo_comprador"], row["estado_oc"], row["moneda_origen"],
            row["cantidad"], row["precio_unitario"], row["descuento"],
            row["subtotal"], row["impuesto"], row["total"],
            row["cantidad_recibida"], row["cantidad_rechazada"], 1,
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


def run_dw_compras() -> dict:
    data = extract_compras_source()
    provider_rows, provider_rejected = build_dim_proveedor_rows(data["proveedores"])
    insumo_rows = build_dim_insumo_rows(data["insumos"], data["categorias_insumo"])

    config = get_dw_db_config()
    with get_postgres_connection(config) as connection:
        try:
            with connection.cursor() as cursor:
                provider_metrics = _load_dim_proveedor(cursor, provider_rows)
                insumo_metrics, insumo_review = _load_dim_insumo(cursor, insumo_rows)
                maps = _dimension_maps(cursor)
                fact_rows, fact_rejected, fact_review = build_fact_rows(data, maps)
                fact_metrics = _load_fact(cursor, fact_rows)
            connection.commit()
        except Exception:
            connection.rollback()
            raise

    return {
        "source": {entity: len(rows) for entity, rows in data.items()},
        "dim_proveedor": provider_metrics,
        "dim_insumo": insumo_metrics,
        "fact_compras": fact_metrics,
        "prepared_facts": len(fact_rows),
        "rejected": provider_rejected + fact_rejected,
        "review": insumo_review + fact_review,
    }
