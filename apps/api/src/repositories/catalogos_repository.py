from __future__ import annotations

from src.core.database import get_connection


def obtener_areas() -> list[dict]:
    sql = """
        SELECT
            area_key AS id,
            codigo_area AS codigo,
            nombre_area AS label
        FROM dw.dim_area
        WHERE area_key <> 0
        ORDER BY nombre_area;
    """

    with get_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute(sql)
            return cursor.fetchall()


def obtener_cargos() -> list[dict]:
    sql = """
        SELECT
            cargo_key AS id,
            codigo_cargo AS codigo,
            nombre_cargo AS label
        FROM dw.dim_cargo
        WHERE cargo_key <> 0
        ORDER BY nombre_cargo;
    """

    with get_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute(sql)
            return cursor.fetchall()


def obtener_periodos_rrhh() -> dict:
    sql = """
        SELECT
            MIN(fecha_ingreso) AS fecha_minima,
            MAX(fecha_desde) AS fecha_maxima
        FROM dw.dim_empleado
        WHERE empleado_key <> 0;
    """

    with get_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute(sql)
            row = cursor.fetchone()

    fecha_minima = row["fecha_minima"]
    fecha_maxima = row["fecha_maxima"]

    anios = list(
        range(
            fecha_minima.year,
            fecha_maxima.year + 1,
        )
    )

    meses = [
        {"id": 1, "label": "Enero"},
        {"id": 2, "label": "Febrero"},
        {"id": 3, "label": "Marzo"},
        {"id": 4, "label": "Abril"},
        {"id": 5, "label": "Mayo"},
        {"id": 6, "label": "Junio"},
        {"id": 7, "label": "Julio"},
        {"id": 8, "label": "Agosto"},
        {"id": 9, "label": "Septiembre"},
        {"id": 10, "label": "Octubre"},
        {"id": 11, "label": "Noviembre"},
        {"id": 12, "label": "Diciembre"},
    ]

    return {
        "anios": anios,
        "meses": meses,
        "ultimoPeriodoDisponible": {
            "anio": fecha_maxima.year,
            "mes": fecha_maxima.month,
        },
        "fechaMaximaDisponible": fecha_maxima.isoformat(),
    }
