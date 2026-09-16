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


def resolver_periodo_compras(
    anio: int,
    mes: int | None = None,
) -> tuple[int, int]:
    with get_connection() as connection:
        with connection.cursor() as cursor:
            if mes is not None:
                cursor.execute(
                    """
                    SELECT 1
                    FROM dw.fact_compras fc
                    JOIN dw.dim_fecha df
                      ON df.fecha_key =
                         fc.fecha_emision_key
                    WHERE df.anio = %s
                      AND df.mes = %s
                    LIMIT 1;
                    """,
                    [anio, mes],
                )

                if cursor.fetchone() is None:
                    raise ValueError(
                        "No existen compras "
                        "para el período solicitado."
                    )

                return anio, mes

            cursor.execute(
                """
                SELECT
                    MAX(df.mes) AS mes
                FROM dw.fact_compras fc
                JOIN dw.dim_fecha df
                  ON df.fecha_key =
                     fc.fecha_emision_key
                WHERE df.anio = %s;
                """,
                [anio],
            )

            row = cursor.fetchone()

    mes_resuelto = row["mes"]

    if mes_resuelto is None:
        raise ValueError(
            "No existen compras "
            "para el año solicitado."
        )

    return anio, int(mes_resuelto)


def _crear_filtros(
    *,
    anio: int,
    mes: int,
    proveedor_id: int | None = None,
    insumo_id: int | None = None,
) -> tuple[str, list[object]]:
    condiciones = [
        "df.anio = %s",
        "df.mes = %s",
    ]

    params: list[object] = [
        anio,
        mes,
    ]

    if proveedor_id is not None:
        condiciones.append(
            "fc.proveedor_key = %s"
        )
        params.append(proveedor_id)

    if insumo_id is not None:
        condiciones.append(
            "fc.insumo_key = %s"
        )
        params.append(insumo_id)

    return " AND ".join(condiciones), params


def obtener_resumen_compras(
    *,
    anio: int,
    mes: int | None = None,
    proveedor_id: int | None = None,
    insumo_id: int | None = None,
) -> dict:
    anio_resuelto, mes_resuelto = (
        resolver_periodo_compras(
            anio,
            mes,
        )
    )

    where_sql, params = _crear_filtros(
        anio=anio_resuelto,
        mes=mes_resuelto,
        proveedor_id=proveedor_id,
        insumo_id=insumo_id,
    )

    with get_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                f"""
                SELECT
                    COALESCE(
                        SUM(
                            CASE
                                WHEN fc.estado_oc
                                     <> 'ANULADA'
                                THEN fc.total
                                ELSE 0
                            END
                        ),
                        0
                    ) AS total_comprado,

                    COUNT(
                        DISTINCT fc.numero_oc
                    ) AS total_ordenes,

                    COUNT(
                        DISTINCT CASE
                            WHEN fc.estado_oc
                                 <> 'ANULADA'
                            THEN fc.numero_oc
                        END
                    ) AS ordenes_efectivas,

                    COUNT(
                        DISTINCT CASE
                            WHEN fc.estado_oc
                                 <> 'ANULADA'
                            THEN fc.proveedor_key
                        END
                    ) AS proveedores_activos,

                    COALESCE(
                        SUM(
                            CASE
                                WHEN fc.estado_oc
                                     <> 'ANULADA'
                                THEN fc.cantidad_recibida
                                ELSE 0
                            END
                        ),
                        0
                    ) AS insumos_adquiridos
                FROM dw.fact_compras fc
                JOIN dw.dim_fecha df
                  ON df.fecha_key =
                     fc.fecha_emision_key
                WHERE {where_sql};
                """,
                params,
            )

            metricas = dict(cursor.fetchone())

            cursor.execute(
                f"""
                SELECT
                    COUNT(
                        DISTINCT CASE
                            WHEN fc.estado_oc
                                 IN (
                                     'RECIBIDA',
                                     'CERRADA'
                                 )
                            THEN fc.numero_oc
                        END
                    ) AS cumplidas,

                    COUNT(
                        DISTINCT CASE
                            WHEN fc.estado_oc
                                 <> 'ANULADA'
                            THEN fc.numero_oc
                        END
                    ) AS consideradas
                FROM dw.fact_compras fc
                JOIN dw.dim_fecha df
                  ON df.fecha_key =
                     fc.fecha_emision_key
                WHERE {where_sql};
                """,
                params,
            )

            cumplimiento = dict(
                cursor.fetchone()
            )

            cursor.execute(
                f"""
                SELECT
                    COALESCE(
                        dp.nombre_fantasia,
                        dp.razon_social
                    ) AS label,
                    SUM(fc.total) AS value
                FROM dw.fact_compras fc
                JOIN dw.dim_fecha df
                  ON df.fecha_key =
                     fc.fecha_emision_key
                JOIN dw.dim_proveedor dp
                  ON dp.proveedor_key =
                     fc.proveedor_key
                WHERE {where_sql}
                  AND fc.estado_oc <> 'ANULADA'
                GROUP BY
                    fc.proveedor_key,
                    dp.nombre_fantasia,
                    dp.razon_social
                ORDER BY value DESC
                LIMIT 10;
                """,
                params,
            )

            top_proveedores = [
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
                    di.nombre_insumo AS label,
                    SUM(fc.total) AS value
                FROM dw.fact_compras fc
                JOIN dw.dim_fecha df
                  ON df.fecha_key =
                     fc.fecha_emision_key
                JOIN dw.dim_insumo di
                  ON di.insumo_key =
                     fc.insumo_key
                WHERE {where_sql}
                  AND fc.estado_oc <> 'ANULADA'
                GROUP BY
                    fc.insumo_key,
                    di.nombre_insumo
                ORDER BY value DESC
                LIMIT 10;
                """,
                params,
            )

            top_insumos = [
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
                    dcc.nombre_centro_costo
                        AS label,
                    SUM(fc.total) AS value
                FROM dw.fact_compras fc
                JOIN dw.dim_fecha df
                  ON df.fecha_key =
                     fc.fecha_emision_key
                LEFT JOIN dw.dim_centro_costo dcc
                  ON dcc.centro_costo_key =
                     fc.centro_costo_key
                WHERE {where_sql}
                  AND fc.estado_oc <> 'ANULADA'
                GROUP BY
                    fc.centro_costo_key,
                    dcc.nombre_centro_costo
                ORDER BY value DESC;
                """,
                params,
            )

            compras_por_centro = [
                {
                    "label": row["label"],
                    "value": float(
                        row["value"] or 0
                    ),
                }
                for row in cursor.fetchall()
            ]

            evolucion_condiciones = [
                "df.anio = %s",
            ]
            evolucion_params: list[object] = [
                anio_resuelto,
            ]

            if proveedor_id is not None:
                evolucion_condiciones.append(
                    "fc.proveedor_key = %s"
                )
                evolucion_params.append(
                    proveedor_id
                )

            if insumo_id is not None:
                evolucion_condiciones.append(
                    "fc.insumo_key = %s"
                )
                evolucion_params.append(
                    insumo_id
                )

            evolucion_where = " AND ".join(
                evolucion_condiciones
            )

            cursor.execute(
                f"""
                SELECT
                    df.mes,
                    SUM(
                        CASE
                            WHEN fc.estado_oc
                                 <> 'ANULADA'
                            THEN fc.total
                            ELSE 0
                        END
                    ) AS value
                FROM dw.fact_compras fc
                JOIN dw.dim_fecha df
                  ON df.fecha_key =
                     fc.fecha_emision_key
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

    total_comprado = float(
        metricas["total_comprado"] or 0
    )
    total_ordenes = int(
        metricas["total_ordenes"] or 0
    )

    ordenes_efectivas = int(
        metricas["ordenes_efectivas"] or 0
    )

    compra_promedio = (
        total_comprado / ordenes_efectivas
        if ordenes_efectivas > 0
        else 0
    )

    cumplidas = int(
        cumplimiento["cumplidas"] or 0
    )
    consideradas = int(
        cumplimiento["consideradas"] or 0
    )

    porcentaje_cumplimiento = (
        round(
            cumplidas
            / consideradas
            * 100,
            2,
        )
        if consideradas > 0
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
            "proveedorId": proveedor_id,
            "insumoId": insumo_id,
        },
        "kpis": {
            "totalComprado":
                total_comprado,
            "totalOrdenes":
                total_ordenes,
            "compraPromedio":
                compra_promedio,
            "proveedoresActivos":
                int(
                    metricas[
                        "proveedores_activos"
                    ] or 0
                ),
            "cumplimientoProveedores":
                porcentaje_cumplimiento,
            "insumosAdquiridos":
                float(
                    metricas[
                        "insumos_adquiridos"
                    ] or 0
                ),
        },
        "evolucionMensual":
            evolucion_mensual,
        "topProveedores":
            top_proveedores,
        "topInsumos":
            top_insumos,
        "comprasPorCentroCosto":
            compras_por_centro,
    }


def obtener_detalle_compras(
    *,
    anio: int,
    mes: int | None = None,
    proveedor_id: int | None = None,
    insumo_id: int | None = None,
    page: int = 1,
    page_size: int = 20,
) -> dict:
    anio_resuelto, mes_resuelto = (
        resolver_periodo_compras(
            anio,
            mes,
        )
    )

    where_sql, params = _crear_filtros(
        anio=anio_resuelto,
        mes=mes_resuelto,
        proveedor_id=proveedor_id,
        insumo_id=insumo_id,
    )

    offset = (page - 1) * page_size

    with get_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                f"""
                SELECT COUNT(*) AS total
                FROM dw.fact_compras fc
                JOIN dw.dim_fecha df
                  ON df.fecha_key =
                     fc.fecha_emision_key
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
                    fc.compra_fact_key,
                    fc.numero_oc,
                    df.fecha,
                    dp.razon_social,
                    di.nombre_insumo,
                    dcc.nombre_centro_costo,
                    fc.cantidad,
                    fc.total
                FROM dw.fact_compras fc
                JOIN dw.dim_fecha df
                  ON df.fecha_key =
                     fc.fecha_emision_key
                JOIN dw.dim_proveedor dp
                  ON dp.proveedor_key =
                     fc.proveedor_key
                JOIN dw.dim_insumo di
                  ON di.insumo_key =
                     fc.insumo_key
                LEFT JOIN dw.dim_centro_costo dcc
                  ON dcc.centro_costo_key =
                     fc.centro_costo_key
                WHERE {where_sql}
                ORDER BY
                    df.fecha DESC,
                    fc.numero_oc DESC,
                    fc.compra_fact_key DESC
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
            "ordenCompraId":
                int(
                    row[
                        "compra_fact_key"
                    ]
                ),
            "numeroOc":
                row["numero_oc"],
            "fecha":
                row["fecha"].isoformat(),
            "proveedor":
                row["razon_social"],
            "insumo":
                row["nombre_insumo"],
            "centroCosto":
                row[
                    "nombre_centro_costo"
                ],
            "cantidad":
                float(row["cantidad"]),
            "total":
                float(row["total"]),
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
