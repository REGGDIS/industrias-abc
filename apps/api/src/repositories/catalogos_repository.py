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

def obtener_periodos_asistencia() -> dict:
    sql = """
        SELECT
            MIN(df.fecha) AS fecha_minima,
            MAX(df.fecha) AS fecha_maxima
        FROM dw.fact_asistencia fa
        JOIN dw.dim_fecha df
          ON df.fecha_key = fa.fecha_key;
    """

    with get_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute(sql)
            row = cursor.fetchone()

    fecha_minima = row["fecha_minima"]
    fecha_maxima = row["fecha_maxima"]

    if fecha_minima is None or fecha_maxima is None:
        return {
            "anios": [],
            "meses": [],
            "ultimoPeriodoDisponible": None,
            "fechaMaximaDisponible": None,
        }

    meses_nombres = [
        "Enero",
        "Febrero",
        "Marzo",
        "Abril",
        "Mayo",
        "Junio",
        "Julio",
        "Agosto",
        "Septiembre",
        "Octubre",
        "Noviembre",
        "Diciembre",
    ]

    sql_periodos = """
        SELECT DISTINCT
            df.anio,
            df.mes
        FROM dw.fact_asistencia fa
        JOIN dw.dim_fecha df
          ON df.fecha_key = fa.fecha_key
        ORDER BY df.anio, df.mes;
    """

    with get_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute(sql_periodos)
            periodos = cursor.fetchall()

    anios = sorted({
        int(row["anio"])
        for row in periodos
    })

    meses_disponibles = sorted({
        int(row["mes"])
        for row in periodos
        if int(row["anio"]) == fecha_maxima.year
    })

    meses = [
        {
            "id": mes,
            "label": meses_nombres[mes - 1],
        }
        for mes in meses_disponibles
    ]

    return {
        "anios": anios,
        "meses": meses,
        "ultimoPeriodoDisponible": {
            "anio": fecha_maxima.year,
            "mes": fecha_maxima.month,
        },
        "fechaMaximaDisponible":
            fecha_maxima.isoformat(),
    }

def obtener_periodos_contratos() -> dict:
    sql = """
        SELECT
            MIN(fecha_inicio) AS fecha_minima
        FROM dw.dim_contrato
        WHERE contrato_key > 0;
    """

    with get_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute(sql)
            row = cursor.fetchone()

    fecha_minima = row["fecha_minima"]

    if fecha_minima is None:
        return {
            "anios": [],
            "meses": [],
            "ultimoPeriodoDisponible": None,
            "fechaMaximaDisponible": None,
        }

    from datetime import date

    hoy = date.today()

    anios = list(
        range(
            fecha_minima.year,
            hoy.year + 1,
        )
    )

    nombres_meses = [
        "Enero",
        "Febrero",
        "Marzo",
        "Abril",
        "Mayo",
        "Junio",
        "Julio",
        "Agosto",
        "Septiembre",
        "Octubre",
        "Noviembre",
        "Diciembre",
    ]

    meses = [
        {
            "id": numero,
            "label": nombre,
        }
        for numero, nombre in enumerate(
            nombres_meses,
            start=1,
        )
        if numero <= hoy.month
    ]

    return {
        "anios": anios,
        "meses": meses,
        "ultimoPeriodoDisponible": {
            "anio": hoy.year,
            "mes": hoy.month,
        },
        "fechaMaximaDisponible":
            hoy.isoformat(),
    }
