from __future__ import annotations

from src.core.database import get_connection


MESES = [
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


def resolver_periodo_remuneraciones(
    anio: int,
    mes: int | None = None,
) -> tuple[int, int]:
    with get_connection() as connection:
        with connection.cursor() as cursor:
            if mes is not None:
                cursor.execute(
                    """
                    SELECT 1
                    FROM dw.fact_remuneraciones
                    WHERE periodo = %s
                    LIMIT 1;
                    """,
                    [f"{anio:04d}-{mes:02d}"],
                )

                if cursor.fetchone() is None:
                    raise ValueError(
                        "No existen remuneraciones "
                        "para el período solicitado."
                    )

                return anio, mes

            cursor.execute(
                """
                SELECT
                    MAX(periodo) AS periodo
                FROM dw.fact_remuneraciones
                WHERE LEFT(periodo, 4)::int = %s;
                """,
                [anio],
            )

            row = cursor.fetchone()

    periodo = row["periodo"]

    if periodo is None:
        raise ValueError(
            "No existen remuneraciones "
            "para el año solicitado."
        )

    anio_resuelto, mes_resuelto = (
        int(value)
        for value in periodo.strip().split("-")
    )

    return anio_resuelto, mes_resuelto


def _crear_filtros(
    *,
    anio: int,
    mes: int,
    area_id: int | None = None,
    trabajador_id: str | None = None,
) -> tuple[str, list[object]]:
    condiciones = [
        "fr.periodo = %s",
    ]

    params: list[object] = [
        f"{anio:04d}-{mes:02d}",
    ]

    if area_id is not None:
        condiciones.append(
            "fr.area_key = %s"
        )
        params.append(area_id)

    if trabajador_id is not None:
        condiciones.append(
            "de.rut_normalizado = %s"
        )
        params.append(trabajador_id)

    return " AND ".join(condiciones), params


def _obtener_total_trabajadores_rrhh(
    *,
    area_id: int | None = None,
) -> int:
    condiciones = [
        "de.empleado_key > 0",
        "de.es_actual = true",
    ]

    params: list[object] = []

    if area_id is not None:
        condiciones.append(
            "de.area_key = %s"
        )
        params.append(area_id)

    with get_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                f"""
                SELECT COUNT(*) AS total
                FROM dw.dim_empleado de
                WHERE {' AND '.join(condiciones)};
                """,
                params,
            )
            row = cursor.fetchone()

    return int(row["total"] or 0)


def obtener_resumen_remuneraciones(
    *,
    anio: int,
    mes: int | None = None,
    area_id: int | None = None,
    trabajador_id: str | None = None,
) -> dict:
    anio_resuelto, mes_resuelto = (
        resolver_periodo_remuneraciones(
            anio,
            mes,
        )
    )

    where_sql, params = _crear_filtros(
        anio=anio_resuelto,
        mes=mes_resuelto,
        area_id=area_id,
        trabajador_id=trabajador_id,
    )

    with get_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                f"""
                SELECT
                    COUNT(*) AS registros,
                    COUNT(
                        DISTINCT de.rut_normalizado
                    ) AS trabajadores,

                    COALESCE(
                        SUM(fr.total_haberes),
                        0
                    ) AS total_haberes,

                    COALESCE(
                        AVG(fr.sueldo_liquido),
                        0
                    ) AS remuneracion_promedio,

                    COALESCE(
                        SUM(fr.horas_extras),
                        0
                    ) AS horas_extras,

                    COALESCE(
                        SUM(fr.sueldo_liquido),
                        0
                    ) AS sueldo_liquido,

                    COALESCE(
                        SUM(fr.total_descuentos),
                        0
                    ) AS descuentos,

                    COALESCE(
                        SUM(fr.costo_empresa),
                        0
                    ) AS costo_empresa
                FROM dw.fact_remuneraciones fr
                JOIN dw.dim_empleado de
                  ON de.empleado_key = fr.empleado_key
                WHERE {where_sql};
                """,
                params,
            )

            metricas = dict(cursor.fetchone())

            cursor.execute(
                f"""
                SELECT
                    da.nombre_area AS label,
                    SUM(fr.costo_empresa) AS value
                FROM dw.fact_remuneraciones fr
                JOIN dw.dim_empleado de
                  ON de.empleado_key = fr.empleado_key
                LEFT JOIN dw.dim_area da
                  ON da.area_key = fr.area_key
                WHERE {where_sql}
                GROUP BY
                    fr.area_key,
                    da.nombre_area
                ORDER BY value DESC;
                """,
                params,
            )

            costo_por_area = [
                {
                    "label": row["label"],
                    "value": float(
                        row["value"] or 0
                    ),
                }
                for row in cursor.fetchall()
            ]

            cursor.execute(
                f"""
                SELECT
                    da.nombre_area AS label,
                    SUM(fr.horas_extras) AS value
                FROM dw.fact_remuneraciones fr
                JOIN dw.dim_empleado de
                  ON de.empleado_key = fr.empleado_key
                LEFT JOIN dw.dim_area da
                  ON da.area_key = fr.area_key
                WHERE {where_sql}
                GROUP BY
                    fr.area_key,
                    da.nombre_area
                ORDER BY value DESC;
                """,
                params,
            )

            horas_por_area = [
                {
                    "label": row["label"],
                    "value": float(
                        row["value"] or 0
                    ),
                }
                for row in cursor.fetchall()
            ]

            condiciones_evolucion = [
                "LEFT(fr.periodo, 4)::int = %s",
            ]

            params_evolucion: list[object] = [
                anio_resuelto,
            ]

            if area_id is not None:
                condiciones_evolucion.append(
                    "fr.area_key = %s"
                )
                params_evolucion.append(area_id)

            if trabajador_id is not None:
                condiciones_evolucion.append(
                    "de.rut_normalizado = %s"
                )
                params_evolucion.append(
                    trabajador_id
                )

            cursor.execute(
                f"""
                SELECT
                    RIGHT(fr.periodo, 2)::int
                        AS mes,
                    SUM(fr.costo_empresa) AS value
                FROM dw.fact_remuneraciones fr
                JOIN dw.dim_empleado de
                  ON de.empleado_key = fr.empleado_key
                WHERE {
                    ' AND '.join(
                        condiciones_evolucion
                    )
                }
                GROUP BY fr.periodo
                ORDER BY fr.periodo;
                """,
                params_evolucion,
            )

            evolucion_rows = [
                dict(row)
                for row in cursor.fetchall()
            ]

    trabajadores_con_remuneracion = int(
        metricas["trabajadores"] or 0
    )

    total_trabajadores_rrhh = (
        _obtener_total_trabajadores_rrhh(
            area_id=area_id,
        )
    )

    porcentaje_cobertura = (
        round(
            trabajadores_con_remuneracion
            / total_trabajadores_rrhh
            * 100,
            2,
        )
        if total_trabajadores_rrhh > 0
        else 0
    )

    evolucion_mensual = [
        {
            "anio": anio_resuelto,
            "mes": int(row["mes"]),
            "label":
                f"{MESES[int(row['mes']) - 1][:3]} "
                f"{anio_resuelto}",
            "value": float(
                row["value"] or 0
            ),
        }
        for row in evolucion_rows
    ]

    return {
        "periodo": {
            "anio": anio_resuelto,
            "mes": mes_resuelto,
        },
        "filtrosAplicados": {
            "areaId": area_id,
            "trabajadorId":
                trabajador_id,
        },
        "kpis": {
            "costoTotal": float(
                metricas["total_haberes"] or 0
            ),
            "sueldoPromedio": float(
                metricas[
                    "remuneracion_promedio"
                ] or 0
            ),
            "horasExtras": float(
                metricas["horas_extras"] or 0
            ),
            "sueldoLiquido": float(
                metricas["sueldo_liquido"] or 0
            ),
            "descuentos": float(
                metricas["descuentos"] or 0
            ),
            "costoEmpresa": float(
                metricas["costo_empresa"] or 0
            ),
        },
        "costoPorArea": costo_por_area,
        "evolucionMensual":
            evolucion_mensual,
        "horasExtrasPorArea":
            horas_por_area,
        "calidadDatos": {
            "datosDisponibles":
                int(
                    metricas["registros"] or 0
                ) > 0,
            "registros":
                int(
                    metricas["registros"] or 0
                ),
            "trabajadoresConRemuneracion":
                trabajadores_con_remuneracion,
            "totalTrabajadoresRrhh":
                total_trabajadores_rrhh,
            "porcentajeCobertura":
                porcentaje_cobertura,
            "coberturaParcial":
                porcentaje_cobertura < 100,
        },
    }


def obtener_detalle_remuneraciones(
    *,
    anio: int,
    mes: int | None = None,
    area_id: int | None = None,
    trabajador_id: str | None = None,
    page: int = 1,
    page_size: int = 20,
) -> dict:
    anio_resuelto, mes_resuelto = (
        resolver_periodo_remuneraciones(
            anio,
            mes,
        )
    )

    where_sql, params = _crear_filtros(
        anio=anio_resuelto,
        mes=mes_resuelto,
        area_id=area_id,
        trabajador_id=trabajador_id,
    )

    offset = (page - 1) * page_size

    with get_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                f"""
                SELECT COUNT(*) AS total
                FROM dw.fact_remuneraciones fr
                JOIN dw.dim_empleado de
                  ON de.empleado_key = fr.empleado_key
                WHERE {where_sql};
                """,
                params,
            )

            total = int(
                cursor.fetchone()["total"]
            )

            cursor.execute(
                f"""
                SELECT
                    fr.remuneracion_fact_key,
                    de.rut_normalizado,
                    CONCAT_WS(
                        ' ',
                        de.nombres,
                        de.apellido_paterno,
                        de.apellido_materno
                    ) AS empleado,
                    da.nombre_area AS area,
                    fr.periodo,
                    fr.sueldo_base,
                    fr.horas_extras,
                    fr.total_haberes,
                    fr.total_descuentos,
                    fr.sueldo_liquido,
                    fr.costo_empresa
                FROM dw.fact_remuneraciones fr
                JOIN dw.dim_empleado de
                  ON de.empleado_key = fr.empleado_key
                LEFT JOIN dw.dim_area da
                  ON da.area_key = fr.area_key
                WHERE {where_sql}
                ORDER BY empleado
                LIMIT %s
                OFFSET %s;
                """,
                [
                    *params,
                    page_size,
                    offset,
                ],
            )

            rows = [
                dict(row)
                for row in cursor.fetchall()
            ]

    items = [
        {
            "remuneracionId":
                int(
                    row[
                        "remuneracion_fact_key"
                    ]
                ),
            "trabajadorId":
                row["rut_normalizado"],
            "empleado":
                row["empleado"],
            "area":
                row["area"],
            "periodo":
                row["periodo"].strip(),
            "sueldoBase":
                float(row["sueldo_base"]),
            "horasExtras":
                float(row["horas_extras"]),
            "totalHaberes":
                float(row["total_haberes"]),
            "descuentos":
                float(row["total_descuentos"]),
            "sueldoLiquido":
                float(row["sueldo_liquido"]),
            "costoEmpresa":
                float(row["costo_empresa"]),
        }
        for row in rows
    ]

    total_pages = (
        (total + page_size - 1)
        // page_size
        if total > 0
        else 0
    )

    return {
        "periodo": {
            "anio": anio_resuelto,
            "mes": mes_resuelto,
        },
        "items": items,
        "page": page,
        "pageSize": page_size,
        "total": total,
        "totalPages": total_pages,
    }


def obtener_trabajadores_remuneraciones(
    *,
    anio: int,
    mes: int | None = None,
    area_id: int | None = None,
) -> dict:
    anio_resuelto, mes_resuelto = (
        resolver_periodo_remuneraciones(
            anio,
            mes,
        )
    )

    where_sql, params = _crear_filtros(
        anio=anio_resuelto,
        mes=mes_resuelto,
        area_id=area_id,
    )

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
                FROM dw.fact_remuneraciones fr
                JOIN dw.dim_empleado de
                  ON de.empleado_key = fr.empleado_key
                WHERE {where_sql}
                ORDER BY label;
                """,
                params,
            )

            items = [
                dict(row)
                for row in cursor.fetchall()
            ]

    return {
        "items": items,
        "periodo": {
            "anio": anio_resuelto,
            "mes": mes_resuelto,
        },
    }
