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


def resolver_periodo_contabilidad(
    anio: int,
    mes: int | None = None,
) -> tuple[int, int]:
    with get_connection() as connection:
        with connection.cursor() as cursor:
            if mes is not None:
                cursor.execute(
                    """
                    SELECT 1
                    FROM dw.fact_contabilidad fc
                    JOIN dw.dim_fecha df
                      ON df.fecha_key = fc.fecha_key
                    WHERE df.anio = %s
                      AND df.mes = %s
                    LIMIT 1;
                    """,
                    [anio, mes],
                )

                if cursor.fetchone() is None:
                    raise ValueError(
                        "No existen movimientos contables "
                        "para el período solicitado."
                    )

                return anio, mes

            cursor.execute(
                """
                SELECT
                    MAX(df.mes) AS mes
                FROM dw.fact_contabilidad fc
                JOIN dw.dim_fecha df
                  ON df.fecha_key = fc.fecha_key
                WHERE df.anio = %s;
                """,
                [anio],
            )

            row = cursor.fetchone()

    mes_resuelto = row["mes"]

    if mes_resuelto is None:
        raise ValueError(
            "No existen movimientos contables "
            "para el año solicitado."
        )

    return anio, int(mes_resuelto)


def _crear_filtros(
    *,
    anio: int,
    mes: int,
    centro_costo_id: int | None = None,
    cuenta_contable_id: int | None = None,
) -> tuple[str, list[object]]:
    condiciones = [
        "df.anio = %s",
        "df.mes = %s",
    ]

    params: list[object] = [
        anio,
        mes,
    ]

    if centro_costo_id is not None:
        condiciones.append(
            "fc.centro_costo_key = %s"
        )
        params.append(centro_costo_id)

    if cuenta_contable_id is not None:
        condiciones.append(
            "fc.cuenta_key = %s"
        )
        params.append(cuenta_contable_id)

    return " AND ".join(condiciones), params


def obtener_resumen_contabilidad(
    *,
    anio: int,
    mes: int | None = None,
    centro_costo_id: int | None = None,
    cuenta_contable_id: int | None = None,
) -> dict:
    anio_resuelto, mes_resuelto = (
        resolver_periodo_contabilidad(
            anio,
            mes,
        )
    )

    where_sql, params = _crear_filtros(
        anio=anio_resuelto,
        mes=mes_resuelto,
        centro_costo_id=centro_costo_id,
        cuenta_contable_id=cuenta_contable_id,
    )

    with get_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                f"""
                SELECT
                    COUNT(*) AS movimientos,

                    COALESCE(
                        SUM(
                            CASE
                                WHEN dcc.tipo_cuenta = 'GASTOS'
                                THEN fc.debe
                                ELSE 0
                            END
                        ),
                        0
                    ) AS gastos_totales,

                    COALESCE(
                        SUM(fc.debe),
                        0
                    ) AS debe_total,

                    COALESCE(
                        SUM(fc.haber),
                        0
                    ) AS haber_total,

                    COALESCE(
                        SUM(fc.saldo),
                        0
                    ) AS saldo
                FROM dw.fact_contabilidad fc
                JOIN dw.dim_fecha df
                  ON df.fecha_key = fc.fecha_key
                JOIN dw.dim_cuenta_contable dcc
                  ON dcc.cuenta_key = fc.cuenta_key
                WHERE {where_sql};
                """,
                params,
            )

            metricas = dict(cursor.fetchone())

            cursor.execute(
                f"""
                SELECT
                    dcc.codigo_cuenta || ' - ' ||
                    dcc.nombre_cuenta AS label,

                    SUM(fc.debe) AS value
                FROM dw.fact_contabilidad fc
                JOIN dw.dim_fecha df
                  ON df.fecha_key = fc.fecha_key
                JOIN dw.dim_cuenta_contable dcc
                  ON dcc.cuenta_key = fc.cuenta_key
                WHERE {where_sql}
                  AND dcc.tipo_cuenta = 'GASTOS'
                GROUP BY
                    dcc.cuenta_key,
                    dcc.codigo_cuenta,
                    dcc.nombre_cuenta
                ORDER BY value DESC;
                """,
                params,
            )

            gastos_por_cuenta = [
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
                    dcc.nombre_centro_costo AS label,
                    SUM(fc.debe) AS value
                FROM dw.fact_contabilidad fc
                JOIN dw.dim_fecha df
                  ON df.fecha_key = fc.fecha_key
                JOIN dw.dim_cuenta_contable cta
                  ON cta.cuenta_key = fc.cuenta_key
                LEFT JOIN dw.dim_centro_costo dcc
                  ON dcc.centro_costo_key =
                     fc.centro_costo_key
                WHERE {where_sql}
                  AND cta.tipo_cuenta = 'GASTOS'
                GROUP BY
                    fc.centro_costo_key,
                    dcc.nombre_centro_costo
                ORDER BY value DESC;
                """,
                params,
            )

            gastos_por_centro = [
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
                    SUM(fc.debe) AS value
                FROM dw.fact_contabilidad fc
                JOIN dw.dim_fecha df
                  ON df.fecha_key = fc.fecha_key
                JOIN dw.dim_cuenta_contable cta
                  ON cta.cuenta_key = fc.cuenta_key
                LEFT JOIN dw.dim_area da
                  ON da.area_key = fc.area_key
                WHERE {where_sql}
                  AND cta.tipo_cuenta = 'GASTOS'
                GROUP BY
                    fc.area_key,
                    da.nombre_area
                ORDER BY value DESC;
                """,
                params,
            )

            gastos_por_area = [
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

            if centro_costo_id is not None:
                evolucion_condiciones.append(
                    "fc.centro_costo_key = %s"
                )
                evolucion_params.append(
                    centro_costo_id
                )

            if cuenta_contable_id is not None:
                evolucion_condiciones.append(
                    "fc.cuenta_key = %s"
                )
                evolucion_params.append(
                    cuenta_contable_id
                )

            evolucion_where = " AND ".join(
                evolucion_condiciones
            )

            cursor.execute(
                f"""
                SELECT
                    df.mes,
                    COALESCE(
                        SUM(
                            CASE
                                WHEN dcc.tipo_cuenta = 'GASTOS'
                                THEN fc.debe
                                ELSE 0
                            END
                        ),
                        0
                    ) AS value
                FROM dw.fact_contabilidad fc
                JOIN dw.dim_fecha df
                  ON df.fecha_key = fc.fecha_key
                JOIN dw.dim_cuenta_contable dcc
                  ON dcc.cuenta_key = fc.cuenta_key
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

            cursor.execute(
                f"""
                SELECT
                    dcc.nombre_centro_costo,
                    SUM(fc.debe) AS gastos
                FROM dw.fact_contabilidad fc
                JOIN dw.dim_fecha df
                  ON df.fecha_key = fc.fecha_key
                JOIN dw.dim_cuenta_contable cta
                  ON cta.cuenta_key = fc.cuenta_key
                LEFT JOIN dw.dim_centro_costo dcc
                  ON dcc.centro_costo_key =
                     fc.centro_costo_key
                WHERE {where_sql}
                  AND cta.tipo_cuenta = 'GASTOS'
                GROUP BY
                    fc.centro_costo_key,
                    dcc.nombre_centro_costo
                ORDER BY gastos DESC
                LIMIT 1;
                """,
                params,
            )

            mayor_centro_row = cursor.fetchone()

            mes_anterior = mes_resuelto - 1
            anio_anterior = anio_resuelto

            if mes_anterior == 0:
                mes_anterior = 12
                anio_anterior -= 1

            comparacion_condiciones = [
                "df.anio = %s",
                "df.mes = %s",
            ]

            comparacion_params: list[object] = [
                anio_anterior,
                mes_anterior,
            ]

            if centro_costo_id is not None:
                comparacion_condiciones.append(
                    "fc.centro_costo_key = %s"
                )
                comparacion_params.append(
                    centro_costo_id
                )

            if cuenta_contable_id is not None:
                comparacion_condiciones.append(
                    "fc.cuenta_key = %s"
                )
                comparacion_params.append(
                    cuenta_contable_id
                )

            comparacion_where = " AND ".join(
                comparacion_condiciones
            )

            cursor.execute(
                f"""
                SELECT
                    COALESCE(
                        SUM(
                            CASE
                                WHEN dcc.tipo_cuenta = 'GASTOS'
                                THEN fc.debe
                                ELSE 0
                            END
                        ),
                        0
                    ) AS gastos
                FROM dw.fact_contabilidad fc
                JOIN dw.dim_fecha df
                  ON df.fecha_key = fc.fecha_key
                JOIN dw.dim_cuenta_contable dcc
                  ON dcc.cuenta_key = fc.cuenta_key
                WHERE {comparacion_where};
                """,
                comparacion_params,
            )

            gasto_anterior = float(
                cursor.fetchone()["gastos"] or 0
            )

    gasto_actual = float(
        metricas["gastos_totales"] or 0
    )

    variacion_mensual = (
        round(
            (
                gasto_actual - gasto_anterior
            )
            / gasto_anterior
            * 100,
            2,
        )
        if gasto_anterior > 0
        else None
    )

    evolucion_gastos = [
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
            "centroCostoId":
                centro_costo_id,
            "cuentaContableId":
                cuenta_contable_id,
        },
        "kpis": {
            "gastosTotales": gasto_actual,
            "debeTotal": float(
                metricas["debe_total"] or 0
            ),
            "haberTotal": float(
                metricas["haber_total"] or 0
            ),
            "saldo": float(
                metricas["saldo"] or 0
            ),
            "mayorCentroCosto": (
                mayor_centro_row[
                    "nombre_centro_costo"
                ]
                if mayor_centro_row
                else None
            ),
            "variacionMensual":
                variacion_mensual,
        },
        "evolucionGastos":
            evolucion_gastos,
        "gastosPorCuenta":
            gastos_por_cuenta,
        "gastosPorCentroCosto":
            gastos_por_centro,
        "gastosPorArea":
            gastos_por_area,
        "calidadDatos": {
            "datosDisponibles":
                int(
                    metricas["movimientos"] or 0
                ) > 0,
            "movimientos":
                int(
                    metricas["movimientos"] or 0
                ),
        },
    }


def obtener_movimientos_contabilidad(
    *,
    anio: int,
    mes: int | None = None,
    centro_costo_id: int | None = None,
    cuenta_contable_id: int | None = None,
    page: int = 1,
    page_size: int = 20,
) -> dict:
    anio_resuelto, mes_resuelto = (
        resolver_periodo_contabilidad(
            anio,
            mes,
        )
    )

    where_sql, params = _crear_filtros(
        anio=anio_resuelto,
        mes=mes_resuelto,
        centro_costo_id=centro_costo_id,
        cuenta_contable_id=cuenta_contable_id,
    )

    offset = (page - 1) * page_size

    with get_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                f"""
                SELECT COUNT(*) AS total
                FROM dw.fact_contabilidad fc
                JOIN dw.dim_fecha df
                  ON df.fecha_key = fc.fecha_key
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
                    fc.movimiento_id_origen,
                    df.fecha,
                    dcc.codigo_cuenta,
                    dcc.nombre_cuenta,
                    dccentro.nombre_centro_costo,
                    fc.documento_tipo,
                    fc.documento_numero,
                    fc.descripcion,
                    fc.debe,
                    fc.haber,
                    fc.saldo
                FROM dw.fact_contabilidad fc
                JOIN dw.dim_fecha df
                  ON df.fecha_key = fc.fecha_key
                JOIN dw.dim_cuenta_contable dcc
                  ON dcc.cuenta_key = fc.cuenta_key
                LEFT JOIN dw.dim_centro_costo dccentro
                  ON dccentro.centro_costo_key =
                     fc.centro_costo_key
                WHERE {where_sql}
                ORDER BY
                    df.fecha DESC,
                    fc.contabilidad_fact_key DESC
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
            "movimientoId":
                int(
                    row[
                        "movimiento_id_origen"
                    ]
                ),
            "fecha":
                row["fecha"].isoformat(),
            "cuentaContable":
                f"{row['codigo_cuenta']} - "
                f"{row['nombre_cuenta']}",
            "centroCosto":
                row[
                    "nombre_centro_costo"
                ],
            "documento":
                (
                    f"{row['documento_tipo']} "
                    f"{row['documento_numero']}"
                ),
            "descripcion":
                row["descripcion"],
            "debe":
                float(row["debe"]),
            "haber":
                float(row["haber"]),
            "saldo":
                float(row["saldo"]),
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
