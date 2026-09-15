from __future__ import annotations

from calendar import monthrange
from datetime import date

from src.core.database import get_connection


def _row_to_dict(cursor, row):
    if isinstance(row, dict):
        return dict(row)

    columns = [
        column.name
        for column in cursor.description
    ]

    return dict(zip(columns, row))


def _fetch_all(cursor):
    rows = cursor.fetchall()

    if not rows:
        return []

    if isinstance(rows[0], dict):
        return [dict(row) for row in rows]

    columns = [
        column.name
        for column in cursor.description
    ]

    return [
        dict(zip(columns, row))
        for row in rows
    ]


def obtener_fecha_maxima_asistencia(
    anio: int | None = None,
) -> date | None:
    with get_connection() as connection:
        with connection.cursor() as cursor:
            params: list[object] = []

            where = ""

            if anio is not None:
                where = "WHERE df.anio = %s"
                params.append(anio)

            cursor.execute(
                f"""
                SELECT MAX(df.fecha) AS fecha_maxima
                FROM dw.fact_asistencia fa
                JOIN dw.dim_fecha df
                  ON df.fecha_key = fa.fecha_key
                {where};
                """,
                params,
            )

            row = cursor.fetchone()

    if not row:
        return None

    return row["fecha_maxima"]


def resolver_periodo_asistencia(
    *,
    anio: int,
    mes: int | None,
) -> tuple[date, date]:
    if mes is not None:
        ultimo_dia = monthrange(anio, mes)[1]

        fecha_desde = date(anio, mes, 1)
        fecha_hasta = date(anio, mes, ultimo_dia)

        return fecha_desde, fecha_hasta

    fecha_maxima = obtener_fecha_maxima_asistencia(anio)

    if fecha_maxima is None:
        raise ValueError(
            f"No existen datos de asistencia para el año {anio}."
        )

    return (
        date(
            fecha_maxima.year,
            fecha_maxima.month,
            1,
        ),
        fecha_maxima,
    )


def _crear_filtros(
    *,
    fecha_desde: date,
    fecha_hasta: date,
    area_id: int | None,
    trabajador_id: str | None,
    alias_fact: str = "fa",
    alias_fecha: str = "df",
    alias_empleado: str = "de",
):
    condiciones = [
        f"{alias_fecha}.fecha >= %s",
        f"{alias_fecha}.fecha <= %s",
    ]

    params: list[object] = [
        fecha_desde,
        fecha_hasta,
    ]

    if area_id is not None:
        condiciones.append(
            f"{alias_fact}.area_key = %s"
        )
        params.append(area_id)

    if trabajador_id is not None:
        condiciones.append(
            f"{alias_empleado}.rut_normalizado = %s"
        )
        params.append(trabajador_id)

    return condiciones, params


def obtener_total_trabajadores_periodo(
    *,
    fecha_corte: date,
    area_id: int | None = None,
    trabajador_id: str | None = None,
) -> int:
    condiciones = [
        "de.empleado_key > 0",
        "de.fecha_desde <= %s",
        "(de.fecha_hasta IS NULL OR %s < de.fecha_hasta)",
    ]

    params: list[object] = [
        fecha_corte,
        fecha_corte,
    ]

    if area_id is not None:
        condiciones.append("de.area_key = %s")
        params.append(area_id)

    if trabajador_id is not None:
        condiciones.append("de.rut_normalizado = %s")
        params.append(trabajador_id)

    where_sql = " AND ".join(condiciones)

    with get_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                f"""
                SELECT
                    COUNT(DISTINCT de.rut_normalizado)
                        AS total
                FROM dw.dim_empleado de
                WHERE {where_sql};
                """,
                params,
            )

            row = cursor.fetchone()

    if isinstance(row, dict):
        return int(row["total"] or 0)

    return int(row[0] or 0)

def obtener_resumen_asistencia(
    *,
    anio: int,
    mes: int | None = None,
    area_id: int | None = None,
    trabajador_id: str | None = None,
) -> dict:
    fecha_desde, fecha_hasta = (
        resolver_periodo_asistencia(
            anio=anio,
            mes=mes,
        )
    )

    condiciones, params = _crear_filtros(
        fecha_desde=fecha_desde,
        fecha_hasta=fecha_hasta,
        area_id=area_id,
        trabajador_id=trabajador_id,
    )

    where_sql = " AND ".join(condiciones)

    with get_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                f"""
                SELECT
                    COUNT(*) AS registros,
                    COUNT(DISTINCT fa.empleado_key)
                        AS trabajadores,
                    COALESCE(
                        SUM(fa.horas_trabajadas),
                        0
                    ) AS horas_trabajadas,
                    COALESCE(
                        SUM(fa.horas_normales),
                        0
                    ) AS horas_normales,
                    COALESCE(
                        SUM(fa.horas_extras),
                        0
                    ) AS horas_extras,
                    COALESCE(
                        SUM(fa.minutos_atraso),
                        0
                    ) AS minutos_atraso,
                    COALESCE(
                        SUM(fa.dias_trabajados),
                        0
                    ) AS dias_trabajados,
                    COALESCE(
                        SUM(fa.dias_ausentes),
                        0
                    ) AS dias_ausentes,
                    MIN(df.fecha) AS fecha_minima_datos,
                    MAX(df.fecha) AS fecha_maxima_datos
                FROM dw.fact_asistencia fa
                JOIN dw.dim_fecha df
                  ON df.fecha_key = fa.fecha_key
                JOIN dw.dim_empleado de
                  ON de.empleado_key = fa.empleado_key
                WHERE {where_sql};
                """,
                params,
            )

            metricas = _row_to_dict(
                cursor,
                cursor.fetchone(),
            )

            cursor.execute(
                f"""
                SELECT
                    da.nombre_area AS label,
                    COALESCE(
                        SUM(fa.horas_extras),
                        0
                    ) AS value
                FROM dw.fact_asistencia fa
                JOIN dw.dim_fecha df
                  ON df.fecha_key = fa.fecha_key
                JOIN dw.dim_empleado de
                  ON de.empleado_key = fa.empleado_key
                JOIN dw.dim_area da
                  ON da.area_key = fa.area_key
                WHERE {where_sql}
                GROUP BY
                    da.area_key,
                    da.nombre_area
                ORDER BY value DESC,
                         da.nombre_area;
                """,
                params,
            )

            horas_extras_por_area = _fetch_all(cursor)

            cursor.execute(
                f"""
                SELECT
                    da.nombre_area AS label,
                    COALESCE(
                        SUM(fa.minutos_atraso),
                        0
                    ) AS value
                FROM dw.fact_asistencia fa
                JOIN dw.dim_fecha df
                  ON df.fecha_key = fa.fecha_key
                JOIN dw.dim_empleado de
                  ON de.empleado_key = fa.empleado_key
                JOIN dw.dim_area da
                  ON da.area_key = fa.area_key
                WHERE {where_sql}
                GROUP BY
                    da.area_key,
                    da.nombre_area
                ORDER BY value DESC,
                         da.nombre_area;
                """,
                params,
            )

            atrasos_por_area = _fetch_all(cursor)

            cursor.execute(
                f"""
                SELECT
                    df.anio,
                    df.mes AS mes,
                    MIN(df.nombre_mes) AS nombre_mes,
                    COALESCE(
                        SUM(fa.horas_extras),
                        0
                    ) AS value
                FROM dw.fact_asistencia fa
                JOIN dw.dim_fecha df
                  ON df.fecha_key = fa.fecha_key
                JOIN dw.dim_empleado de
                  ON de.empleado_key = fa.empleado_key
                WHERE {where_sql}
                GROUP BY
                    df.anio,
                    df.mes
                ORDER BY
                    df.anio,
                    df.mes;
                """,
                params,
            )

            evolucion_raw = _fetch_all(cursor)

    registros = int(metricas["registros"] or 0)

    total_trabajadores_periodo = (
        obtener_total_trabajadores_periodo(
            fecha_corte=fecha_hasta,
            area_id=area_id,
            trabajador_id=trabajador_id,
        )
    )

    trabajadores_con_asistencia = int(
        metricas["trabajadores"] or 0
    )

    porcentaje_cobertura = (
        round(
            trabajadores_con_asistencia
            / total_trabajadores_periodo
            * 100,
            2,
        )
        if total_trabajadores_periodo > 0
        else None
    )

    dias_trabajados = int(
        metricas["dias_trabajados"] or 0
    )
    dias_ausentes = int(
        metricas["dias_ausentes"] or 0
    )

    jornadas_observadas = (
        dias_trabajados + dias_ausentes
    )

    ausentismo = (
        round(
            dias_ausentes
            / jornadas_observadas
            * 100,
            2,
        )
        if jornadas_observadas > 0
        else None
    )

    evolucion_horas_extras = [
        {
            "anio": int(row["anio"]),
            "mes": int(row["mes"]),
            "label": (
                f"{str(row['nombre_mes'])[:3]} "
                f"{row['anio']}"
            ),
            "value": float(row["value"] or 0),
        }
        for row in evolucion_raw
    ]

    return {
        "periodo": {
            "anio": fecha_hasta.year,
            "mes": fecha_hasta.month,
            "fechaDesde": fecha_desde.isoformat(),
            "fechaHasta": fecha_hasta.isoformat(),
        },
        "filtrosAplicados": {
            "areaId": area_id,
            "trabajadorId": trabajador_id,
        },
        "kpis": {
            "horasTrabajadas": float(
                metricas["horas_trabajadas"] or 0
            ),
            "horasNormales": float(
                metricas["horas_normales"] or 0
            ),
            "horasExtras": float(
                metricas["horas_extras"] or 0
            ),
            "minutosAtraso": int(
                metricas["minutos_atraso"] or 0
            ),
            "diasAusentes": dias_ausentes,
            "ausentismo": ausentismo,
        },
        "horasExtrasPorArea": [
            {
                "label": row["label"],
                "value": float(row["value"] or 0),
            }
            for row in horas_extras_por_area
        ],
        "atrasosPorArea": [
            {
                "label": row["label"],
                "value": int(row["value"] or 0),
            }
            for row in atrasos_por_area
        ],
        "evolucionHorasExtras":
            evolucion_horas_extras,
        "calidadDatos": {
            "datosDisponibles": registros > 0,
            "registros": registros,
            "trabajadoresConAsistencia":
                trabajadores_con_asistencia,
            "totalTrabajadoresPeriodo":
                total_trabajadores_periodo,
            "porcentajeCobertura":
                porcentaje_cobertura,
            "coberturaParcial": (
                trabajadores_con_asistencia
                < total_trabajadores_periodo
            ),
            "fechaDesdeDatos": (
                metricas[
                    "fecha_minima_datos"
                ].isoformat()
                if metricas["fecha_minima_datos"]
                else None
            ),
            "fechaHastaDatos": (
                metricas[
                    "fecha_maxima_datos"
                ].isoformat()
                if metricas["fecha_maxima_datos"]
                else None
            ),
            "diasTrabajados": dias_trabajados,
            "diasAusentes": dias_ausentes,
            "jornadasObservadas":
                jornadas_observadas,
        },
    }


def obtener_detalle_asistencia(
    *,
    anio: int,
    mes: int | None = None,
    area_id: int | None = None,
    trabajador_id: str | None = None,
    page: int = 1,
    page_size: int = 20,
) -> dict:
    fecha_desde, fecha_hasta = (
        resolver_periodo_asistencia(
            anio=anio,
            mes=mes,
        )
    )

    condiciones, params = _crear_filtros(
        fecha_desde=fecha_desde,
        fecha_hasta=fecha_hasta,
        area_id=area_id,
        trabajador_id=trabajador_id,
    )

    where_sql = " AND ".join(condiciones)

    offset = (page - 1) * page_size

    with get_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                f"""
                SELECT COUNT(*)
                FROM dw.fact_asistencia fa
                JOIN dw.dim_fecha df
                  ON df.fecha_key = fa.fecha_key
                JOIN dw.dim_empleado de
                  ON de.empleado_key = fa.empleado_key
                WHERE {where_sql};
                """,
                params,
            )
            total_row = cursor.fetchone()

            total = int(
                total_row["count"]
                if isinstance(total_row, dict)
                else total_row[0]
            )

            cursor.execute(
                f"""
                SELECT
                    fa.asistencia_fact_key,
                    de.rut_normalizado,
                    CONCAT_WS(
                        ' ',
                        de.nombres,
                        de.apellido_paterno,
                        de.apellido_materno
                    ) AS trabajador,
                    df.fecha,
                    da.nombre_area,
                    dt.nombre_turno,
                    fa.hora_entrada,
                    fa.hora_salida,
                    fa.horas_trabajadas,
                    fa.horas_normales,
                    fa.horas_extras,
                    fa.minutos_atraso,
                    fa.estado_asistencia
                FROM dw.fact_asistencia fa
                JOIN dw.dim_fecha df
                  ON df.fecha_key = fa.fecha_key
                JOIN dw.dim_empleado de
                  ON de.empleado_key = fa.empleado_key
                JOIN dw.dim_area da
                  ON da.area_key = fa.area_key
                JOIN dw.dim_turno dt
                  ON dt.turno_key = fa.turno_key
                WHERE {where_sql}
                ORDER BY
                    df.fecha DESC,
                    trabajador,
                    fa.asistencia_fact_key
                LIMIT %s
                OFFSET %s;
                """,
                [
                    *params,
                    page_size,
                    offset,
                ],
            )

            rows = _fetch_all(cursor)

    items = [
        {
            "asistenciaId":
                int(row["asistencia_fact_key"]),
            "trabajadorId":
                row["rut_normalizado"],
            "empleado": row["trabajador"],
            "fecha": row["fecha"].isoformat(),
            "area": row["nombre_area"],
            "turno": row["nombre_turno"],
            "horaEntrada": (
                row["hora_entrada"].isoformat()
                if row["hora_entrada"]
                else None
            ),
            "horaSalida": (
                row["hora_salida"].isoformat()
                if row["hora_salida"]
                else None
            ),
            "horasTrabajadas":
                float(row["horas_trabajadas"]),
            "horasNormales":
                float(row["horas_normales"]),
            "horasExtras":
                float(row["horas_extras"]),
            "minutosAtraso":
                int(row["minutos_atraso"]),
            "estado":
                row["estado_asistencia"],
        }
        for row in rows
    ]

    total_pages = (
        (total + page_size - 1) // page_size
        if total > 0
        else 0
    )

    return {
        "periodo": {
            "anio": fecha_hasta.year,
            "mes": fecha_hasta.month,
            "fechaDesde": fecha_desde.isoformat(),
            "fechaHasta": fecha_hasta.isoformat(),
        },
        "filtrosAplicados": {
            "areaId": area_id,
            "trabajadorId": trabajador_id,
        },
        "items": items,
        "page": page,
        "pageSize": page_size,
        "total": total,
        "totalPages": total_pages,
    }


def obtener_trabajadores_asistencia(
    *,
    anio: int,
    mes: int | None = None,
    area_id: int | None = None,
) -> dict:
    fecha_desde, fecha_hasta = (
        resolver_periodo_asistencia(
            anio=anio,
            mes=mes,
        )
    )

    condiciones, params = _crear_filtros(
        fecha_desde=fecha_desde,
        fecha_hasta=fecha_hasta,
        area_id=area_id,
        trabajador_id=None,
    )

    where_sql = " AND ".join(condiciones)

    with get_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                f"""
                SELECT DISTINCT
                    de.rut_normalizado AS id,
                    CONCAT_WS(
                        ' ',
                        de.nombres,
                        de.apellido_paterno,
                        de.apellido_materno
                    ) AS label
                FROM dw.fact_asistencia fa
                JOIN dw.dim_fecha df
                  ON df.fecha_key = fa.fecha_key
                JOIN dw.dim_empleado de
                  ON de.empleado_key = fa.empleado_key
                WHERE {where_sql}
                ORDER BY label;
                """,
                params,
            )

            items = _fetch_all(cursor)

    return {
        "items": items,
        "periodo": {
            "anio": fecha_hasta.year,
            "mes": fecha_hasta.month,
        },
    }
