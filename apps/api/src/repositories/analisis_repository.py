from __future__ import annotations

from src.core.database import get_connection


def _number(value):
    if value is None:
        return 0

    return float(value)


def obtener_resumen_analisis():
    with get_connection() as connection:
        with connection.cursor() as cursor:

            # ======================================================
            # BLOQUE LABORAL
            # Julio 2026.
            #
            # Asistencia tiene cobertura parcial:
            # 27-07-2026 a 29-07-2026.
            # ======================================================
            cursor.execute(
                """
                WITH asistencia AS (
                    SELECT
                        fa.area_key,
                        SUM(fa.horas_extras)
                            AS horas_registradas,
                        COUNT(*) AS registros,
                        MIN(df.fecha) AS desde,
                        MAX(df.fecha) AS hasta
                    FROM dw.fact_asistencia fa
                    JOIN dw.dim_fecha df
                      ON df.fecha_key = fa.fecha_key
                    WHERE df.anio = 2026
                      AND df.mes = 7
                    GROUP BY fa.area_key
                ),
                remuneraciones AS (
                    SELECT
                        fr.area_key,
                        COUNT(
                            DISTINCT fr.empleado_key
                        ) AS empleados,
                        SUM(fr.horas_extras)
                            AS horas_pagadas,
                        SUM(fr.costo_empresa)
                            AS costo_empresa
                    FROM dw.fact_remuneraciones fr
                    JOIN dw.dim_fecha df
                      ON df.fecha_key = fr.fecha_key
                    WHERE df.anio = 2026
                      AND df.mes = 7
                    GROUP BY fr.area_key
                )
                SELECT
                    da.area_key,
                    da.nombre_area,
                    COALESCE(
                        r.empleados,
                        0
                    ) AS empleados_remunerados,
                    COALESCE(
                        a.horas_registradas,
                        0
                    ) AS horas_extra_asistencia,
                    COALESCE(
                        r.horas_pagadas,
                        0
                    ) AS horas_extra_remuneradas,
                    COALESCE(
                        r.costo_empresa,
                        0
                    ) AS costo_empresa,
                    a.desde AS asistencia_desde,
                    a.hasta AS asistencia_hasta
                FROM dw.dim_area da
                LEFT JOIN asistencia a
                  ON a.area_key = da.area_key
                LEFT JOIN remuneraciones r
                  ON r.area_key = da.area_key
                WHERE da.area_key > 0
                  AND (
                       a.area_key IS NOT NULL
                       OR r.area_key IS NOT NULL
                  )
                ORDER BY da.nombre_area;
                """
            )

            laboral_rows = cursor.fetchall()

            # ======================================================
            # COMPRAS + CONTABILIDAD
            # Enero a mayo 2025.
            #
            # Se presentan como series paralelas.
            # No se suman ni se interpreta Debe como gasto.
            # ======================================================
            cursor.execute(
                """
                WITH compras AS (
                    SELECT
                        df.anio,
                        df.mes,
                        COUNT(
                            DISTINCT fc.numero_oc
                        ) AS ordenes,
                        SUM(
                            CASE
                                WHEN UPPER(
                                    fc.estado_oc
                                ) <> 'ANULADA'
                                THEN fc.total
                                ELSE 0
                            END
                        ) AS total_compras
                    FROM dw.fact_compras fc
                    JOIN dw.dim_fecha df
                      ON df.fecha_key =
                         fc.fecha_emision_key
                    WHERE df.anio = 2025
                      AND df.mes BETWEEN 1 AND 5
                    GROUP BY
                        df.anio,
                        df.mes
                ),
                contabilidad AS (
                    SELECT
                        df.anio,
                        df.mes,
                        COUNT(*) AS movimientos,
                        SUM(fco.debe) AS total_debe,
                        SUM(fco.haber) AS total_haber
                    FROM dw.fact_contabilidad fco
                    JOIN dw.dim_fecha df
                      ON df.fecha_key =
                         fco.fecha_key
                    WHERE df.anio = 2025
                      AND df.mes BETWEEN 1 AND 5
                    GROUP BY
                        df.anio,
                        df.mes
                )
                SELECT
                    c.anio,
                    c.mes,
                    c.ordenes,
                    c.total_compras,
                    co.movimientos,
                    co.total_debe,
                    co.total_haber
                FROM compras c
                JOIN contabilidad co
                  ON co.anio = c.anio
                 AND co.mes = c.mes
                ORDER BY
                    c.anio,
                    c.mes;
                """
            )

            financiero_rows = cursor.fetchall()

            # ======================================================
            # PRODUCCIÓN + CONSUMO
            # Agosto 2026.
            #
            # Cruce validado por:
            # numero_orden + producto_key.
            # ======================================================
            cursor.execute(
                """
                SELECT
                    fp.numero_orden,
                    dp.codigo_producto,
                    dp.nombre_producto,
                    dfp.fecha AS fecha_inicio,
                    fp.cantidad_planificada,
                    fp.cantidad_producida,
                    fp.cantidad_rechazada,
                    COUNT(
                        fci.consumo_fact_key
                    ) AS lineas_consumo,
                    COALESCE(
                        SUM(
                            fci.cantidad_planificada
                        ),
                        0
                    ) AS consumo_planificado,
                    COALESCE(
                        SUM(
                            fci.cantidad_consumida
                        ),
                        0
                    ) AS consumo_real,
                    COALESCE(
                        SUM(fci.desviacion),
                        0
                    ) AS desviacion_consumo
                FROM dw.fact_produccion fp
                JOIN dw.dim_fecha dfp
                  ON dfp.fecha_key =
                     fp.fecha_inicio_key
                JOIN dw.dim_producto dp
                  ON dp.producto_key =
                     fp.producto_key
                LEFT JOIN dw.fact_consumo_insumo fci
                  ON fci.numero_orden =
                     fp.numero_orden
                 AND fci.producto_key =
                     fp.producto_key
                WHERE dfp.anio = 2026
                  AND dfp.mes = 8
                GROUP BY
                    fp.numero_orden,
                    dp.codigo_producto,
                    dp.nombre_producto,
                    dfp.fecha,
                    fp.cantidad_planificada,
                    fp.cantidad_producida,
                    fp.cantidad_rechazada
                ORDER BY
                    dfp.fecha,
                    fp.numero_orden;
                """
            )

            produccion_rows = cursor.fetchall()

            # ======================================================
            # CONTROL DE INTEGRIDAD DEL CRUCE
            # ======================================================
            cursor.execute(
                """
                SELECT COUNT(*) AS cantidad
                FROM dw.fact_consumo_insumo fci
                LEFT JOIN dw.fact_produccion fp
                  ON fp.numero_orden =
                     fci.numero_orden
                 AND fp.producto_key =
                     fci.producto_key
                WHERE fp.produccion_fact_key
                      IS NULL;
                """
            )

            huerfanos = cursor.fetchone()

    laboral = [
        {
            "areaId": int(row["area_key"]),
            "area": row["nombre_area"],
            "empleadosRemunerados": int(
                row["empleados_remunerados"] or 0
            ),
            "horasExtraAsistencia": _number(
                row["horas_extra_asistencia"]
            ),
            "horasExtraRemuneradas": _number(
                row["horas_extra_remuneradas"]
            ),
            "costoEmpresa": _number(
                row["costo_empresa"]
            ),
            "asistenciaDesde": (
                row["asistencia_desde"].isoformat()
                if row["asistencia_desde"]
                else None
            ),
            "asistenciaHasta": (
                row["asistencia_hasta"].isoformat()
                if row["asistencia_hasta"]
                else None
            ),
        }
        for row in laboral_rows
    ]

    financiero = [
        {
            "anio": int(row["anio"]),
            "mes": int(row["mes"]),
            "ordenesCompra": int(
                row["ordenes"] or 0
            ),
            "totalCompras": _number(
                row["total_compras"]
            ),
            "movimientosContables": int(
                row["movimientos"] or 0
            ),
            "totalDebe": _number(
                row["total_debe"]
            ),
            "totalHaber": _number(
                row["total_haber"]
            ),
        }
        for row in financiero_rows
    ]

    produccion = [
        {
            "numeroOrden": row["numero_orden"],
            "codigoProducto":
                row["codigo_producto"],
            "producto":
                row["nombre_producto"],
            "fechaInicio":
                row["fecha_inicio"].isoformat(),
            "produccionPlanificada": _number(
                row["cantidad_planificada"]
            ),
            "produccionReal": _number(
                row["cantidad_producida"]
            ),
            "produccionRechazada": _number(
                row["cantidad_rechazada"]
            ),
            "lineasConsumo": int(
                row["lineas_consumo"] or 0
            ),
            "consumoPlanificado": _number(
                row["consumo_planificado"]
            ),
            "consumoReal": _number(
                row["consumo_real"]
            ),
            "desviacionConsumo": _number(
                row["desviacion_consumo"]
            ),
        }
        for row in produccion_rows
    ]

    costo_empresa_total = sum(
        item["costoEmpresa"]
        for item in laboral
    )

    horas_asistencia_total = sum(
        item["horasExtraAsistencia"]
        for item in laboral
    )

    horas_remuneradas_total = sum(
        item["horasExtraRemuneradas"]
        for item in laboral
    )

    compras_total = sum(
        item["totalCompras"]
        for item in financiero
    )

    produccion_planificada = sum(
        item["produccionPlanificada"]
        for item in produccion
    )

    produccion_real = sum(
        item["produccionReal"]
        for item in produccion
    )

    consumo_planificado = sum(
        item["consumoPlanificado"]
        for item in produccion
    )

    consumo_real = sum(
        item["consumoReal"]
        for item in produccion
    )

    cumplimiento_produccion = (
        produccion_real
        / produccion_planificada
        * 100
        if produccion_planificada > 0
        else 0
    )

    desviacion_consumo = (
        consumo_real
        - consumo_planificado
    )

    return {
        "kpis": {
            "costoEmpresaJulio2026":
                costo_empresa_total,
            "horasExtraAsistencia":
                horas_asistencia_total,
            "horasExtraRemuneradas":
                horas_remuneradas_total,
            "comprasEneroMayo2025":
                compras_total,
            "produccionPlanificadaAgosto2026":
                produccion_planificada,
            "produccionRealAgosto2026":
                produccion_real,
            "cumplimientoProduccion":
                cumplimiento_produccion,
            "desviacionConsumo":
                desviacion_consumo,
        },
        "laboral": laboral,
        "comprasContabilidad":
            financiero,
        "produccionConsumo":
            produccion,
        "calidadCruceProduccion": {
            "consumosHuerfanos": int(
                huerfanos["cantidad"] or 0
            ),
            "cruceValido": (
                int(
                    huerfanos["cantidad"] or 0
                ) == 0
            ),
        },
        "periodos": {
            "laboral": {
                "anio": 2026,
                "mes": 7,
                "asistenciaDesde":
                    "2026-07-27",
                "asistenciaHasta":
                    "2026-07-29",
            },
            "comprasContabilidad": {
                "anio": 2025,
                "mesDesde": 1,
                "mesHasta": 5,
            },
            "produccionConsumo": {
                "anio": 2026,
                "mes": 8,
            },
        },
        "advertencias": [
            (
                "Asistencia cubre solo del 27 al "
                "29 de julio de 2026, mientras "
                "Remuneraciones representa el "
                "período mensual de julio."
            ),
            (
                "Compras y Contabilidad se "
                "presentan como magnitudes "
                "paralelas y no se suman entre sí."
            ),
            (
                "El total Debe de Contabilidad "
                "no se interpreta automáticamente "
                "como gasto."
            ),
            (
                "Producción y Consumo se cruzan "
                "por número de orden y producto; "
                "no por Área ni Centro de costo."
            ),
        ],
    }
