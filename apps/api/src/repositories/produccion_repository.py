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


def resolver_periodo_produccion(
    anio: int,
    mes: int | None = None,
) -> tuple[int, int]:
    with get_connection() as connection:
        with connection.cursor() as cursor:
            if mes is not None:
                cursor.execute(
                    """
                    SELECT 1
                    FROM dw.fact_produccion fp
                    JOIN dw.dim_fecha df
                      ON df.fecha_key = fp.fecha_inicio_key
                    WHERE df.anio = %s
                      AND df.mes = %s
                    LIMIT 1;
                    """,
                    [anio, mes],
                )

                if cursor.fetchone() is None:
                    raise ValueError(
                        "No existen órdenes de producción "
                        "para el período solicitado."
                    )

                return anio, mes

            cursor.execute(
                """
                SELECT MAX(df.mes) AS mes
                FROM dw.fact_produccion fp
                JOIN dw.dim_fecha df
                  ON df.fecha_key = fp.fecha_inicio_key
                WHERE df.anio = %s;
                """,
                [anio],
            )

            row = cursor.fetchone()

    mes_resuelto = row["mes"]

    if mes_resuelto is None:
        raise ValueError(
            "No existen órdenes de producción "
            "para el año solicitado."
        )

    return anio, int(mes_resuelto)


def _crear_filtros_produccion(
    *,
    anio: int,
    mes: int,
    producto_id: int | None = None,
    insumo_ref: str | None = None,
    fecha_alias: str = "df",
) -> tuple[str, list[object]]:
    condiciones = [
        f"{fecha_alias}.anio = %s",
        f"{fecha_alias}.mes = %s",
    ]

    params: list[object] = [
        anio,
        mes,
    ]

    if producto_id is not None:
        condiciones.append(
            "fp.producto_key = %s"
        )
        params.append(producto_id)

    if insumo_ref:
        condiciones.append(
            """
            EXISTS (
                SELECT 1
                FROM dw.fact_consumo_insumo fci_filtro
                WHERE fci_filtro.numero_orden =
                      fp.numero_orden
                  AND fci_filtro.insumo_codigo_origen = %s
            )
            """.strip()
        )
        params.append(insumo_ref)

    return " AND ".join(condiciones), params


def _crear_filtros_evolucion(
    *,
    anio: int,
    producto_id: int | None = None,
    insumo_ref: str | None = None,
) -> tuple[str, list[object]]:
    condiciones = [
        "df.anio = %s",
    ]
    params: list[object] = [
        anio,
    ]

    if producto_id is not None:
        condiciones.append(
            "fp.producto_key = %s"
        )
        params.append(producto_id)

    if insumo_ref:
        condiciones.append(
            """
            EXISTS (
                SELECT 1
                FROM dw.fact_consumo_insumo fci_filtro
                WHERE fci_filtro.numero_orden =
                      fp.numero_orden
                  AND fci_filtro.insumo_codigo_origen = %s
            )
            """.strip()
        )
        params.append(insumo_ref)

    return " AND ".join(condiciones), params


def obtener_resumen_produccion(
    *,
    anio: int,
    mes: int | None = None,
    producto_id: int | None = None,
    insumo_ref: str | None = None,
) -> dict:
    anio_resuelto, mes_resuelto = (
        resolver_periodo_produccion(
            anio,
            mes,
        )
    )

    where_sql, params = _crear_filtros_produccion(
        anio=anio_resuelto,
        mes=mes_resuelto,
        producto_id=producto_id,
        insumo_ref=insumo_ref,
    )

    evolucion_where, evolucion_params = (
        _crear_filtros_evolucion(
            anio=anio_resuelto,
            producto_id=producto_id,
            insumo_ref=insumo_ref,
        )
    )

    with get_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                f"""
                SELECT
                    COUNT(*) AS total_ordenes,
                    COALESCE(
                        SUM(fp.cantidad_planificada),
                        0
                    ) AS cantidad_planificada,
                    COALESCE(
                        SUM(fp.cantidad_producida),
                        0
                    ) AS cantidad_producida,
                    COALESCE(
                        SUM(fp.cantidad_rechazada),
                        0
                    ) AS cantidad_rechazada,
                    COUNT(
                        DISTINCT fp.producto_key
                    ) AS productos_activos
                FROM dw.fact_produccion fp
                JOIN dw.dim_fecha df
                  ON df.fecha_key =
                     fp.fecha_inicio_key
                WHERE {where_sql};
                """,
                params,
            )

            metricas = dict(
                cursor.fetchone()
            )

            cursor.execute(
                f"""
                SELECT
                    fp.estado AS label,
                    COUNT(*) AS value
                FROM dw.fact_produccion fp
                JOIN dw.dim_fecha df
                  ON df.fecha_key =
                     fp.fecha_inicio_key
                WHERE {where_sql}
                GROUP BY fp.estado
                ORDER BY
                    value DESC,
                    fp.estado;
                """,
                params,
            )

            ordenes_por_estado = [
                {
                    "label": row["label"],
                    "value": int(
                        row["value"] or 0
                    ),
                }
                for row in cursor.fetchall()
            ]

            cursor.execute(
                f"""
                SELECT
                    dp.nombre_producto AS label,
                    COALESCE(
                        SUM(fp.cantidad_rechazada),
                        0
                    ) AS value
                FROM dw.fact_produccion fp
                JOIN dw.dim_fecha df
                  ON df.fecha_key =
                     fp.fecha_inicio_key
                JOIN dw.dim_producto dp
                  ON dp.producto_key =
                     fp.producto_key
                WHERE {where_sql}
                GROUP BY
                    fp.producto_key,
                    dp.nombre_producto
                HAVING
                    SUM(
                        fp.cantidad_rechazada
                    ) > 0
                ORDER BY
                    value DESC,
                    dp.nombre_producto
                LIMIT 10;
                """,
                params,
            )

            rechazo_por_producto = [
                {
                    "label": row["label"],
                    "value": float(
                        row["value"] or 0
                    ),
                }
                for row in cursor.fetchall()
            ]

            consumo_condiciones = [
                "df.anio = %s",
                "df.mes = %s",
            ]
            consumo_params: list[object] = [
                anio_resuelto,
                mes_resuelto,
            ]

            if producto_id is not None:
                consumo_condiciones.append(
                    "fp.producto_key = %s"
                )
                consumo_params.append(
                    producto_id
                )

            if insumo_ref:
                consumo_condiciones.append(
                    """
                    fci.insumo_codigo_origen = %s
                    """.strip()
                )
                consumo_params.append(
                    insumo_ref
                )

            consumo_where = " AND ".join(
                consumo_condiciones
            )

            cursor.execute(
                f"""
                SELECT
                    fci.insumo_codigo_origen
                        AS label,
                    COALESCE(
                        SUM(
                            fci.cantidad_planificada
                        ),
                        0
                    ) AS planificado,
                    COALESCE(
                        SUM(
                            fci.cantidad_consumida
                        ),
                        0
                    ) AS consumido,
                    COALESCE(
                        SUM(
                            fci.desviacion
                        ),
                        0
                    ) AS desviacion
                FROM dw.fact_consumo_insumo fci
                JOIN dw.fact_produccion fp
                  ON fp.numero_orden =
                     fci.numero_orden
                JOIN dw.dim_fecha df
                  ON df.fecha_key =
                     fp.fecha_inicio_key
                WHERE {consumo_where}
                GROUP BY
                    fci.insumo_codigo_origen
                ORDER BY
                    consumido DESC,
                    fci.insumo_codigo_origen;
                """,
                consumo_params,
            )

            consumo_por_insumo = [
                {
                    "label":
                        row["label"],
                    "planificado":
                        float(
                            row[
                                "planificado"
                            ] or 0
                        ),
                    "consumido":
                        float(
                            row[
                                "consumido"
                            ] or 0
                        ),
                    "desviacion":
                        float(
                            row[
                                "desviacion"
                            ] or 0
                        ),
                }
                for row in cursor.fetchall()
            ]

            cursor.execute(
                f"""
                SELECT
                    df.mes,
                    COALESCE(
                        SUM(
                            fp.cantidad_planificada
                        ),
                        0
                    ) AS planificada,
                    COALESCE(
                        SUM(
                            fp.cantidad_producida
                        ),
                        0
                    ) AS producida,
                    COALESCE(
                        SUM(
                            fp.cantidad_rechazada
                        ),
                        0
                    ) AS rechazada
                FROM dw.fact_produccion fp
                JOIN dw.dim_fecha df
                  ON df.fecha_key =
                     fp.fecha_inicio_key
                WHERE {evolucion_where}
                GROUP BY df.mes
                ORDER BY df.mes;
                """,
                evolucion_params,
            )

            evolucion_rows = [
                dict(row)
                for row in cursor.fetchall()
            ]

    total_ordenes = int(
        metricas["total_ordenes"] or 0
    )
    planificada = float(
        metricas[
            "cantidad_planificada"
        ] or 0
    )
    producida = float(
        metricas[
            "cantidad_producida"
        ] or 0
    )
    rechazada = float(
        metricas[
            "cantidad_rechazada"
        ] or 0
    )

    cumplimiento = (
        round(
            producida
            / planificada
            * 100,
            2,
        )
        if planificada > 0
        else 0
    )

    tasa_rechazo = (
        round(
            rechazada
            / producida
            * 100,
            2,
        )
        if producida > 0
        else 0
    )

    evolucion_mensual = [
        {
            "anio":
                anio_resuelto,
            "mes":
                int(row["mes"]),
            "label":
                f"{MESES[int(row['mes']) - 1][:3]} "
                f"{anio_resuelto}",
            "planificada":
                float(
                    row[
                        "planificada"
                    ] or 0
                ),
            "producida":
                float(
                    row[
                        "producida"
                    ] or 0
                ),
            "rechazada":
                float(
                    row[
                        "rechazada"
                    ] or 0
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
            "productoId":
                producto_id,
            "insumoRef":
                insumo_ref,
        },
        "kpis": {
            "cantidadPlanificada":
                planificada,
            "cantidadProducida":
                producida,
            "cumplimientoProduccion":
                cumplimiento,
            "cantidadRechazada":
                rechazada,
            "tasaRechazo":
                tasa_rechazo,
            "totalOrdenes":
                total_ordenes,
            "productosActivos":
                int(
                    metricas[
                        "productos_activos"
                    ] or 0
                ),
        },
        "evolucionMensual":
            evolucion_mensual,
        "rechazoPorProducto":
            rechazo_por_producto,
        "ordenesPorEstado":
            ordenes_por_estado,
        "consumoPorInsumo":
            consumo_por_insumo,
    }


def obtener_detalle_produccion(
    *,
    anio: int,
    mes: int | None = None,
    producto_id: int | None = None,
    insumo_ref: str | None = None,
    page: int = 1,
    page_size: int = 20,
) -> dict:
    anio_resuelto, mes_resuelto = (
        resolver_periodo_produccion(
            anio,
            mes,
        )
    )

    where_count, params = (
        _crear_filtros_produccion(
            anio=anio_resuelto,
            mes=mes_resuelto,
            producto_id=producto_id,
            insumo_ref=insumo_ref,
            fecha_alias="df",
        )
    )

    where_detail, detail_params = (
        _crear_filtros_produccion(
            anio=anio_resuelto,
            mes=mes_resuelto,
            producto_id=producto_id,
            insumo_ref=insumo_ref,
            fecha_alias="fi",
        )
    )

    offset = (
        page - 1
    ) * page_size

    with get_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                f"""
                SELECT
                    COUNT(*) AS total
                FROM dw.fact_produccion fp
                JOIN dw.dim_fecha df
                  ON df.fecha_key =
                     fp.fecha_inicio_key
                WHERE {where_count};
                """,
                params,
            )

            total = int(
                cursor.fetchone()[
                    "total"
                ]
            )

            cursor.execute(
                f"""
                SELECT
                    fp.produccion_fact_key,
                    fp.numero_orden,
                    fi.fecha
                        AS fecha_inicio,
                    ft.fecha
                        AS fecha_termino,
                    dp.codigo_producto,
                    dp.nombre_producto,
                    dp.categoria,
                    dp.unidad_medida,
                    fp.cantidad_planificada,
                    fp.cantidad_producida,
                    fp.cantidad_rechazada,
                    fp.estado
                FROM dw.fact_produccion fp
                JOIN dw.dim_fecha fi
                  ON fi.fecha_key =
                     fp.fecha_inicio_key
                LEFT JOIN dw.dim_fecha ft
                  ON ft.fecha_key =
                     fp.fecha_termino_key
                 AND fp.fecha_termino_key
                     <> 0
                JOIN dw.dim_producto dp
                  ON dp.producto_key =
                     fp.producto_key
                WHERE {where_detail}
                ORDER BY
                    fi.fecha DESC,
                    fp.numero_orden DESC
                LIMIT %s
                OFFSET %s;
                """,
                [
                    *detail_params,
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
            "produccionId":
                int(
                    row[
                        "produccion_fact_key"
                    ]
                ),
            "numeroOrden":
                row[
                    "numero_orden"
                ],
            "fechaInicio":
                row[
                    "fecha_inicio"
                ].isoformat(),
            "fechaTermino":
                (
                    row[
                        "fecha_termino"
                    ].isoformat()
                    if row[
                        "fecha_termino"
                    ]
                    else None
                ),
            "productoCodigo":
                row[
                    "codigo_producto"
                ],
            "producto":
                row[
                    "nombre_producto"
                ],
            "categoria":
                row[
                    "categoria"
                ],
            "unidadMedida":
                row[
                    "unidad_medida"
                ],
            "cantidadPlanificada":
                float(
                    row[
                        "cantidad_planificada"
                    ]
                ),
            "cantidadProducida":
                float(
                    row[
                        "cantidad_producida"
                    ]
                ),
            "cantidadRechazada":
                float(
                    row[
                        "cantidad_rechazada"
                    ]
                ),
            "estado":
                row["estado"],
        }
        for row in rows
    ]

    total_pages = (
        (
            total
            + page_size
            - 1
        )
        // page_size
        if total > 0
        else 0
    )

    return {
        "periodo": {
            "anio":
                anio_resuelto,
            "mes":
                mes_resuelto,
        },
        "filtrosAplicados": {
            "productoId":
                producto_id,
            "insumoRef":
                insumo_ref,
        },
        "items": items,
        "page": page,
        "pageSize": page_size,
        "total": total,
        "totalPages": total_pages,
    }
