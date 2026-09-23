from __future__ import annotations

from src.core.database import get_connection


def _number(value):
    if value is None:
        return 0

    if hasattr(value, "as_integer_ratio"):
        return float(value)

    return value


def obtener_resumen_dashboard():
    with get_connection() as connection:
        with connection.cursor() as cursor:

            # ==========================================================
            # RRHH
            # Dotación total según la última versión disponible
            # de DIM_EMPLEADO.
            # ==========================================================
            cursor.execute(
                """
                WITH fecha_corte AS (
                    SELECT MAX(fecha_desde) AS fecha
                    FROM dw.dim_empleado
                    WHERE empleado_key <> 0
                )
                SELECT
                    fc.fecha,
                    COUNT(
                        DISTINCT e.rut_normalizado
                    ) AS total_trabajadores
                FROM fecha_corte fc
                LEFT JOIN dw.dim_empleado e
                  ON e.empleado_key <> 0
                 AND e.fecha_desde <= fc.fecha
                 AND (
                        e.fecha_hasta IS NULL
                        OR fc.fecha < e.fecha_hasta
                 )
                GROUP BY fc.fecha;
                """
            )

            rrhh = cursor.fetchone()

            # ==========================================================
            # ASISTENCIA
            # Último día disponible.
            # ==========================================================
            cursor.execute(
                """
                WITH ultima_fecha AS (
                    SELECT MAX(fecha_key) AS fecha_key
                    FROM dw.fact_asistencia
                )
                SELECT
                    df.fecha,
                    COUNT(
                        DISTINCT fa.empleado_key
                    ) AS empleados_con_registro,
                    COALESCE(
                        SUM(fa.horas_extras),
                        0
                    ) AS horas_extras,
                    COALESCE(
                        SUM(fa.minutos_atraso),
                        0
                    ) AS minutos_atraso,
                    COALESCE(
                        SUM(fa.dias_ausentes),
                        0
                    ) AS dias_ausentes
                FROM dw.fact_asistencia fa
                JOIN ultima_fecha uf
                  ON uf.fecha_key = fa.fecha_key
                JOIN dw.dim_fecha df
                  ON df.fecha_key = fa.fecha_key
                GROUP BY df.fecha;
                """
            )

            asistencia = cursor.fetchone()

            # ==========================================================
            # REMUNERACIONES
            # Último período disponible.
            # ==========================================================
            cursor.execute(
                """
                WITH ultimo_periodo AS (
                    SELECT MAX(fecha_key) AS fecha_key
                    FROM dw.fact_remuneraciones
                )
                SELECT
                    df.fecha,
                    COUNT(
                        DISTINCT fr.empleado_key
                    ) AS empleados,
                    COALESCE(
                        SUM(fr.costo_empresa),
                        0
                    ) AS costo_empresa,
                    COALESCE(
                        SUM(fr.sueldo_liquido),
                        0
                    ) AS sueldo_liquido,
                    COALESCE(
                        SUM(fr.horas_extras),
                        0
                    ) AS horas_extras_remuneradas
                FROM dw.fact_remuneraciones fr
                JOIN ultimo_periodo up
                  ON up.fecha_key = fr.fecha_key
                JOIN dw.dim_fecha df
                  ON df.fecha_key = fr.fecha_key
                GROUP BY df.fecha;
                """
            )

            remuneraciones = cursor.fetchone()

            # ==========================================================
            # COMPRAS
            # Último mes disponible.
            # Órdenes anuladas se excluyen de monto y efectivas.
            # ==========================================================
            cursor.execute(
                """
                WITH ultimo_mes AS (
                    SELECT
                        df.anio,
                        df.mes
                    FROM dw.fact_compras fc
                    JOIN dw.dim_fecha df
                      ON df.fecha_key = fc.fecha_emision_key
                    ORDER BY df.fecha DESC
                    LIMIT 1
                )
                SELECT
                    um.anio,
                    um.mes,
                    COUNT(
                        DISTINCT fc.numero_oc
                    ) AS ordenes,
                    COUNT(
                        DISTINCT fc.numero_oc
                    ) FILTER (
                        WHERE fc.estado_oc <> 'ANULADA'
                    ) AS ordenes_efectivas,
                    COALESCE(
                        SUM(fc.total) FILTER (
                            WHERE fc.estado_oc <> 'ANULADA'
                        ),
                        0
                    ) AS total_compras
                FROM dw.fact_compras fc
                JOIN dw.dim_fecha df
                  ON df.fecha_key = fc.fecha_emision_key
                CROSS JOIN ultimo_mes um
                WHERE df.anio = um.anio
                  AND df.mes = um.mes
                GROUP BY
                    um.anio,
                    um.mes;
                """
            )

            compras = cursor.fetchone()

            # ==========================================================
            # CONTABILIDAD
            # Último mes disponible.
            #
            # No se denomina "gasto" al total Debe:
            # son magnitudes contables diferentes.
            # ==========================================================
            cursor.execute(
                """
                WITH ultimo_mes AS (
                    SELECT
                        df.anio,
                        df.mes
                    FROM dw.fact_contabilidad fc
                    JOIN dw.dim_fecha df
                      ON df.fecha_key = fc.fecha_key
                    ORDER BY df.fecha DESC
                    LIMIT 1
                )
                SELECT
                    um.anio,
                    um.mes,
                    COUNT(*) AS movimientos,
                    COALESCE(
                        SUM(fc.debe),
                        0
                    ) AS total_debe,
                    COALESCE(
                        SUM(fc.haber),
                        0
                    ) AS total_haber,
                    COALESCE(
                        SUM(fc.saldo),
                        0
                    ) AS saldo
                FROM dw.fact_contabilidad fc
                JOIN dw.dim_fecha df
                  ON df.fecha_key = fc.fecha_key
                CROSS JOIN ultimo_mes um
                WHERE df.anio = um.anio
                  AND df.mes = um.mes
                GROUP BY
                    um.anio,
                    um.mes;
                """
            )

            contabilidad = cursor.fetchone()

            # ==========================================================
            # PRINCIPALES CENTROS DE COSTO
            # Último año con cuentas contables de tipo GASTOS.
            # ==========================================================
            cursor.execute(
                """
                WITH ultimo_anio_gastos AS (
                    SELECT MAX(df.anio) AS anio
                    FROM dw.fact_contabilidad fc
                    JOIN dw.dim_fecha df
                      ON df.fecha_key = fc.fecha_key
                    JOIN dw.dim_cuenta_contable cta
                      ON cta.cuenta_key = fc.cuenta_key
                    WHERE cta.tipo_cuenta = 'GASTOS'
                )
                SELECT
                    uag.anio,
                    dcc.nombre_centro_costo AS label,
                    COALESCE(
                        SUM(fc.debe),
                        0
                    ) AS value
                FROM dw.fact_contabilidad fc
                JOIN dw.dim_fecha df
                  ON df.fecha_key = fc.fecha_key
                JOIN dw.dim_cuenta_contable cta
                  ON cta.cuenta_key = fc.cuenta_key
                LEFT JOIN dw.dim_centro_costo dcc
                  ON dcc.centro_costo_key =
                     fc.centro_costo_key
                CROSS JOIN ultimo_anio_gastos uag
                WHERE df.anio = uag.anio
                  AND cta.tipo_cuenta = 'GASTOS'
                GROUP BY
                    uag.anio,
                    fc.centro_costo_key,
                    dcc.nombre_centro_costo
                ORDER BY value DESC
                LIMIT 5;
                """
            )

            centros_costo_rows = cursor.fetchall()

            # ==========================================================
            # EVOLUCIÓN MENSUAL DE GASTOS
            # Último año con cuentas contables de tipo GASTOS.
            # ==========================================================
            cursor.execute(
                """
                WITH ultimo_anio_gastos AS (
                    SELECT MAX(df.anio) AS anio
                    FROM dw.fact_contabilidad fc
                    JOIN dw.dim_fecha df
                      ON df.fecha_key = fc.fecha_key
                    JOIN dw.dim_cuenta_contable cta
                      ON cta.cuenta_key = fc.cuenta_key
                    WHERE cta.tipo_cuenta = 'GASTOS'
                )
                SELECT
                    uag.anio,
                    df.mes,
                    COALESCE(
                        SUM(
                            CASE
                                WHEN cta.tipo_cuenta = 'GASTOS'
                                THEN fc.debe
                                ELSE 0
                            END
                        ),
                        0
                    ) AS value
                FROM dw.fact_contabilidad fc
                JOIN dw.dim_fecha df
                  ON df.fecha_key = fc.fecha_key
                JOIN dw.dim_cuenta_contable cta
                  ON cta.cuenta_key = fc.cuenta_key
                CROSS JOIN ultimo_anio_gastos uag
                WHERE df.anio = uag.anio
                GROUP BY
                    uag.anio,
                    df.mes
                ORDER BY df.mes;
                """
            )

            evolucion_mensual_rows = cursor.fetchall()

            # ==========================================================
            # PRODUCCIÓN
            # Último mes disponible según fecha de inicio.
            # ==========================================================
            cursor.execute(
                """
                WITH ultimo_mes AS (
                    SELECT
                        df.anio,
                        df.mes
                    FROM dw.fact_produccion fp
                    JOIN dw.dim_fecha df
                      ON df.fecha_key = fp.fecha_inicio_key
                    ORDER BY df.fecha DESC
                    LIMIT 1
                )
                SELECT
                    um.anio,
                    um.mes,
                    COUNT(
                        DISTINCT fp.numero_orden
                    ) AS ordenes,
                    COALESCE(
                        SUM(fp.cantidad_planificada),
                        0
                    ) AS planificada,
                    COALESCE(
                        SUM(fp.cantidad_producida),
                        0
                    ) AS producida,
                    COALESCE(
                        SUM(fp.cantidad_rechazada),
                        0
                    ) AS rechazada,
                    CASE
                        WHEN COALESCE(
                            SUM(fp.cantidad_planificada),
                            0
                        ) = 0
                        THEN 0
                        ELSE
                            SUM(fp.cantidad_producida)
                            / SUM(fp.cantidad_planificada)
                            * 100
                    END AS cumplimiento,
                    CASE
                        WHEN COALESCE(
                            SUM(fp.cantidad_producida),
                            0
                        ) = 0
                        THEN 0
                        ELSE
                            SUM(fp.cantidad_rechazada)
                            / SUM(fp.cantidad_producida)
                            * 100
                    END AS tasa_rechazo
                FROM dw.fact_produccion fp
                JOIN dw.dim_fecha df
                  ON df.fecha_key = fp.fecha_inicio_key
                CROSS JOIN ultimo_mes um
                WHERE df.anio = um.anio
                  AND df.mes = um.mes
                GROUP BY
                    um.anio,
                    um.mes;
                """
            )

            produccion = cursor.fetchone()

            # ==========================================================
            # COBERTURA REAL DE DATOS
            # ==========================================================
            cursor.execute(
                """
                WITH cobertura AS (

                    SELECT
                        'ASISTENCIA' AS dominio,
                        MIN(df.fecha) AS fecha_desde,
                        MAX(df.fecha) AS fecha_hasta,
                        COUNT(*) AS registros
                    FROM dw.fact_asistencia fa
                    JOIN dw.dim_fecha df
                      ON df.fecha_key = fa.fecha_key

                    UNION ALL

                    SELECT
                        'REMUNERACIONES',
                        MIN(df.fecha),
                        MAX(df.fecha),
                        COUNT(*)
                    FROM dw.fact_remuneraciones fr
                    JOIN dw.dim_fecha df
                      ON df.fecha_key = fr.fecha_key

                    UNION ALL

                    SELECT
                        'COMPRAS',
                        MIN(df.fecha),
                        MAX(df.fecha),
                        COUNT(*)
                    FROM dw.fact_compras fc
                    JOIN dw.dim_fecha df
                      ON df.fecha_key = fc.fecha_emision_key

                    UNION ALL

                    SELECT
                        'CONTABILIDAD',
                        MIN(df.fecha),
                        MAX(df.fecha),
                        COUNT(*)
                    FROM dw.fact_contabilidad fc
                    JOIN dw.dim_fecha df
                      ON df.fecha_key = fc.fecha_key

                    UNION ALL

                    SELECT
                        'PRODUCCION',
                        MIN(df.fecha),
                        MAX(df.fecha),
                        COUNT(*)
                    FROM dw.fact_produccion fp
                    JOIN dw.dim_fecha df
                      ON df.fecha_key = fp.fecha_inicio_key

                    UNION ALL

                    SELECT
                        'CONSUMO_INSUMO',
                        MIN(df.fecha),
                        MAX(df.fecha),
                        COUNT(*)
                    FROM dw.fact_consumo_insumo fi
                    JOIN dw.dim_fecha df
                      ON df.fecha_key = fi.fecha_consumo_key
                )
                SELECT
                    dominio,
                    fecha_desde,
                    fecha_hasta,
                    registros
                FROM cobertura
                ORDER BY dominio;
                """
            )

            cobertura_rows = cursor.fetchall()

    cobertura = [
        {
            "dominio": row["dominio"],
            "fechaDesde": (
                row["fecha_desde"].isoformat()
                if row["fecha_desde"] is not None
                else None
            ),
            "fechaHasta": (
                row["fecha_hasta"].isoformat()
                if row["fecha_hasta"] is not None
                else None
            ),
            "registros": int(row["registros"]),
        }
        for row in cobertura_rows
    ]

    principales_centros_costo = [
        {
            "label": (
                row["label"]
                or "Sin centro de costo"
            ),
            "value": _number(row["value"]),
        }
        for row in centros_costo_rows
    ]

    anio_centros_costo = (
        int(centros_costo_rows[0]["anio"])
        if centros_costo_rows
        else None
    )

    nombres_meses = [
        "Ene",
        "Feb",
        "Mar",
        "Abr",
        "May",
        "Jun",
        "Jul",
        "Ago",
        "Sep",
        "Oct",
        "Nov",
        "Dic",
    ]

    evolucion_mensual = [
        {
            "anio": int(row["anio"]),
            "mes": int(row["mes"]),
            "label": (
                f"{nombres_meses[int(row['mes']) - 1]} "
                f"{int(row['anio'])}"
            ),
            "value": _number(row["value"]),
        }
        for row in evolucion_mensual_rows
    ]

    return {
        "kpis": {
            "totalTrabajadores": (
                int(rrhh["total_trabajadores"])
                if rrhh
                else 0
            ),
            "empleadosConAsistencia": (
                int(asistencia["empleados_con_registro"])
                if asistencia
                else 0
            ),
            "horasExtrasAsistencia": (
                _number(asistencia["horas_extras"])
                if asistencia
                else 0
            ),
            "minutosAtraso": (
                int(asistencia["minutos_atraso"])
                if asistencia
                else 0
            ),
            "diasAusentes": (
                int(asistencia["dias_ausentes"])
                if asistencia
                else 0
            ),
            "costoRemuneraciones": (
                _number(remuneraciones["costo_empresa"])
                if remuneraciones
                else 0
            ),
            "sueldoLiquido": (
                _number(remuneraciones["sueldo_liquido"])
                if remuneraciones
                else 0
            ),
            "totalCompras": (
                _number(compras["total_compras"])
                if compras
                else 0
            ),
            "ordenesCompra": (
                int(compras["ordenes"])
                if compras
                else 0
            ),
            "ordenesCompraEfectivas": (
                int(compras["ordenes_efectivas"])
                if compras
                else 0
            ),
            "movimientosContables": (
                int(contabilidad["movimientos"])
                if contabilidad
                else 0
            ),
            "totalDebeContabilidad": (
                _number(contabilidad["total_debe"])
                if contabilidad
                else 0
            ),
            "totalHaberContabilidad": (
                _number(contabilidad["total_haber"])
                if contabilidad
                else 0
            ),
            "saldoContabilidad": (
                _number(contabilidad["saldo"])
                if contabilidad
                else 0
            ),
            "produccionPlanificada": (
                _number(produccion["planificada"])
                if produccion
                else 0
            ),
            "produccionReal": (
                _number(produccion["producida"])
                if produccion
                else 0
            ),
            "produccionRechazada": (
                _number(produccion["rechazada"])
                if produccion
                else 0
            ),
            "tasaRechazoProduccion": (
                _number(produccion["tasa_rechazo"])
                if produccion
                else 0
            ),
            "cumplimientoProduccion": (
                _number(produccion["cumplimiento"])
                if produccion
                else 0
            ),
            "ordenesProduccion": (
                int(produccion["ordenes"])
                if produccion
                else 0
            ),
        },
        "periodos": {
            "rrhh": (
                rrhh["fecha"].isoformat()
                if rrhh and rrhh["fecha"]
                else None
            ),
            "asistencia": (
                asistencia["fecha"].isoformat()
                if asistencia
                else None
            ),
            "remuneraciones": (
                remuneraciones["fecha"].isoformat()
                if remuneraciones
                else None
            ),
            "compras": (
                {
                    "anio": int(compras["anio"]),
                    "mes": int(compras["mes"]),
                }
                if compras
                else None
            ),
            "contabilidad": (
                {
                    "anio": int(contabilidad["anio"]),
                    "mes": int(contabilidad["mes"]),
                }
                if contabilidad
                else None
            ),
            "produccion": (
                {
                    "anio": int(produccion["anio"]),
                    "mes": int(produccion["mes"]),
                }
                if produccion
                else None
            ),
        },
        "principalesCentrosCosto":
            principales_centros_costo,
        "periodoCentrosCosto":
            anio_centros_costo,
        "evolucionMensual":
            evolucion_mensual,
        "cobertura": cobertura,
        "advertencias": [
            (
                "Cada dominio usa su último período real disponible; "
                "los KPI no representan un único corte temporal común."
            ),
            (
                "Producción y consumo de insumos no se consolidan por "
                "Área ni Centro de costo porque sus claves permanecen "
                "sin homologación empresarial validada."
            ),
            (
                "El total Debe de Contabilidad se informa como magnitud "
                "contable y no se interpreta automáticamente como gasto."
            ),
        ],
    }
