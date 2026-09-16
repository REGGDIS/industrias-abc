from decimal import Decimal

from etl.load.dw_compras import (
    _prorated_tax_by_detail,
    build_dim_insumo_rows,
    build_dim_proveedor_rows,
    build_fact_rows,
    normalize_rut,
)


def _base_data():
    return {
        "areas": [{"area_id": 4, "codigo_area": "A04"}],
        "centros_costo": [
            {"centro_costo_id": 4, "codigo_centro": "CC004", "area_id": 4}
        ],
        "compradores": [
            {"comprador_id": 1, "codigo_comprador": "COMP01"}
        ],
        "proveedores": [
            {"proveedor_id": 1, "rut_proveedor": "76.000.137-6"}
        ],
        "categorias_insumo": [
            {"categoria_id": 1, "codigo_categoria": "CAT01", "nombre_categoria": "Materias primas"}
        ],
        "insumos": [
            {
                "insumo_id": 1,
                "codigo_insumo": "INS001",
                "nombre_insumo": "Acero",
                "categoria_id": 1,
                "unidad_medida": "KG",
                "stock_minimo": Decimal("10.00"),
                "estado": "ACTIVO",
            }
        ],
        "ordenes_compra": [
            {
                "oc_id": 1,
                "numero_oc": "OC-1",
                "proveedor_id": 1,
                "fecha_emision": __import__("datetime").date(2026, 1, 1),
                "fecha_requerida": __import__("datetime").date(2026, 1, 15),
                "centro_costo_id": 4,
                "comprador_id": 1,
                "estado": "EMITIDA",
                "moneda": "CLP",
                "subtotal": Decimal("100.00"),
                "impuesto": Decimal("19.00"),
                "total": Decimal("119.00"),
            }
        ],
        "detalle_orden_compra": [
            {
                "detalle_id": 1,
                "oc_id": 1,
                "insumo_id": 1,
                "cantidad": Decimal("2.00"),
                "precio_unitario": Decimal("50.00"),
                "descuento": Decimal("0.00"),
                "subtotal": Decimal("100.00"),
            }
        ],
        "recepciones": [{"recepcion_id": 1, "oc_id": 1}],
        "detalle_recepcion": [
            {
                "detalle_recepcion_id": 1,
                "recepcion_id": 1,
                "detalle_id": 1,
                "cantidad_recibida": Decimal("1.50"),
                "cantidad_rechazada": Decimal("0.50"),
            }
        ],
    }


def _maps():
    from datetime import date

    return {
        "fechas": {date(2026, 1, 1): 20260101, date(2026, 1, 15): 20260115},
        "proveedores": {"76000137-6": 10},
        "insumos": {"INS001": 20},
        "centros": {"CC004": 30},
        "areas": {"A04": 40},
    }


def test_normalize_rut_elimina_puntos_y_conserva_dv():
    assert normalize_rut(" 76.000.137-6 ") == "76000137-6"


def test_build_dim_proveedor_valida_dv_y_normaliza():
    rows, rejected = build_dim_proveedor_rows([
        {
            "proveedor_id": 1,
            "rut_proveedor": "76.000.137-6",
            "razon_social": "Proveedor",
            "nombre_fantasia": None,
            "categoria": "Acero",
            "region": "Biobío",
            "comuna": "Los Ángeles",
            "estado": "ACTIVO",
        }
    ])
    assert rejected == []
    assert rows[0]["rut_proveedor_normalizado"] == "76000137-6"


def test_build_dim_proveedor_rechaza_dv_invalido():
    rows, rejected = build_dim_proveedor_rows([
        {
            "proveedor_id": 1,
            "rut_proveedor": "76000137-0",
            "razon_social": "Proveedor",
            "nombre_fantasia": None,
            "categoria": None,
            "region": None,
            "comuna": None,
            "estado": "ACTIVO",
        }
    ])
    assert rows == []
    assert rejected[0]["regla"] == "RUT_PROVEEDOR_INVALIDO"


def test_build_dim_insumo_aplana_categoria():
    data = _base_data()
    rows = build_dim_insumo_rows(data["insumos"], data["categorias_insumo"])
    assert rows[0]["codigo_categoria"] == "CAT01"
    assert rows[0]["nombre_categoria"] == "Materias primas"


def test_prorrateo_impuesto_conserva_total_cabecera():
    data = _base_data()
    data["ordenes_compra"][0]["subtotal"] = Decimal("300.00")
    data["ordenes_compra"][0]["impuesto"] = Decimal("57.00")
    data["detalle_orden_compra"] = [
        {"detalle_id": 1, "oc_id": 1, "subtotal": Decimal("100.00")},
        {"detalle_id": 2, "oc_id": 1, "subtotal": Decimal("200.00")},
    ]
    taxes, review = _prorated_tax_by_detail(data)
    assert review == []
    assert taxes[1] + taxes[2] == Decimal("57.00")
    assert taxes[1] == Decimal("19.00")
    assert taxes[2] == Decimal("38.00")


def test_fact_resuelve_dimensiones_y_recepciones():
    rows, rejected, review = build_fact_rows(_base_data(), _maps())
    assert rejected == []
    assert review == []
    row = rows[0]
    assert row["proveedor_key"] == 10
    assert row["insumo_key"] == 20
    assert row["centro_costo_key"] == 30
    assert row["area_key"] == 40
    assert row["cantidad_recibida"] == Decimal("1.50")
    assert row["cantidad_rechazada"] == Decimal("0.50")
    assert row["impuesto"] == Decimal("19.00")
    assert row["total"] == Decimal("119.00")


def test_fact_fecha_requerida_nula_usa_miembro_desconocido():
    data = _base_data()
    data["ordenes_compra"][0]["fecha_requerida"] = None
    rows, rejected, review = build_fact_rows(data, _maps())
    assert rejected == []
    assert review == []
    assert rows[0]["fecha_requerida_key"] == 0


def test_fact_proveedor_no_resuelto_pasa_a_review_con_key_cero():
    maps = _maps()
    maps["proveedores"] = {}
    rows, rejected, review = build_fact_rows(_base_data(), maps)
    assert rejected == []
    assert rows[0]["proveedor_key"] == 0
    assert "PROVEEDOR_NO_RESUELTO" in review[0]["reglas"]


def test_fact_insumo_no_resuelto_se_rechaza_para_proteger_grano():
    maps = _maps()
    maps["insumos"] = {}
    rows, rejected, _ = build_fact_rows(_base_data(), maps)
    assert rows == []
    assert rejected[0]["regla"] == "INSUMO_NO_RESUELTO"


def test_subtotal_cabecera_distinto_genera_review():
    data = _base_data()
    data["ordenes_compra"][0]["subtotal"] = Decimal("110.00")
    _, review = _prorated_tax_by_detail(data)
    assert review[0]["regla"] == "SUBTOTAL_CABECERA_DIFIERE_DE_LINEAS"
