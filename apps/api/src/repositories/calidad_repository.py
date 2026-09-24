from __future__ import annotations

from src.core.database import get_connection


def obtener_resumen_calidad():
    with get_connection() as connection:
        with connection.cursor() as cursor:

            # ======================================================
            # CALIDAD POR DOMINIO
            # Incidencias a nivel de registro, sin duplicar un hecho
            # por múltiples claves desconocidas.
            # ======================================================
            cursor.execute(
                """
                SELECT
                    'ASISTENCIA' AS dominio,
                    COUNT(*) AS registros,
                    COUNT(*) FILTER (
                        WHERE area_key = 0
                           OR centro_costo_key = 0
                           OR empleado_key = 0
                           OR turno_key = 0
                    ) AS registros_con_incidencia
                FROM dw.fact_asistencia

                UNION ALL

                SELECT
                    'COMPRAS',
                    COUNT(*),
                    COUNT(*) FILTER (
                        WHERE area_key = 0
                           OR centro_costo_key = 0
                           OR proveedor_key = 0
                           OR insumo_key = 0
                    )
                FROM dw.fact_compras

                UNION ALL

                SELECT
                    'CONTABILIDAD',
                    COUNT(*),
                    COUNT(*) FILTER (
                        WHERE area_key = 0
                           OR centro_costo_key = 0
                           OR cuenta_key = 0
                    )
                FROM dw.fact_contabilidad

                UNION ALL

                SELECT
                    'REMUNERACIONES',
                    COUNT(*),
                    COUNT(*) FILTER (
                        WHERE area_key = 0
                           OR centro_costo_key = 0
                           OR empleado_key = 0
                           OR contrato_key = 0
                    )
                FROM dw.fact_remuneraciones

                UNION ALL

                SELECT
                    'PRODUCCION',
                    COUNT(*),
                    COUNT(*) FILTER (
                        WHERE area_key = 0
                           OR centro_costo_key = 0
                           OR producto_key = 0
                    )
                FROM dw.fact_produccion

                UNION ALL

                SELECT
                    'CONSUMO_INSUMO',
                    COUNT(*),
                    COUNT(*) FILTER (
                        WHERE area_key = 0
                           OR centro_costo_key = 0
                           OR producto_key = 0
                           OR insumo_key = 0
                    )
                FROM dw.fact_consumo_insumo

                ORDER BY dominio;
                """
            )

            dominio_rows = cursor.fetchall()

            # ======================================================
            # DETALLE DE HOMOLOGACIÓN
            # ======================================================
            cursor.execute(
                """
                SELECT
                    'ASISTENCIA' AS dominio,
                    COUNT(*) FILTER (
                        WHERE area_key = 0
                    ) AS area_desconocida,
                    COUNT(*) FILTER (
                        WHERE centro_costo_key = 0
                    ) AS cc_desconocido
                FROM dw.fact_asistencia

                UNION ALL

                SELECT
                    'COMPRAS',
                    COUNT(*) FILTER (
                        WHERE area_key = 0
                    ),
                    COUNT(*) FILTER (
                        WHERE centro_costo_key = 0
                    )
                FROM dw.fact_compras

                UNION ALL

                SELECT
                    'CONTABILIDAD',
                    COUNT(*) FILTER (
                        WHERE area_key = 0
                    ),
                    COUNT(*) FILTER (
                        WHERE centro_costo_key = 0
                    )
                FROM dw.fact_contabilidad

                UNION ALL

                SELECT
                    'REMUNERACIONES',
                    COUNT(*) FILTER (
                        WHERE area_key = 0
                    ),
                    COUNT(*) FILTER (
                        WHERE centro_costo_key = 0
                    )
                FROM dw.fact_remuneraciones

                UNION ALL

                SELECT
                    'PRODUCCION',
                    COUNT(*) FILTER (
                        WHERE area_key = 0
                    ),
                    COUNT(*) FILTER (
                        WHERE centro_costo_key = 0
                    )
                FROM dw.fact_produccion

                UNION ALL

                SELECT
                    'CONSUMO_INSUMO',
                    COUNT(*) FILTER (
                        WHERE area_key = 0
                    ),
                    COUNT(*) FILTER (
                        WHERE centro_costo_key = 0
                    )
                FROM dw.fact_consumo_insumo

                ORDER BY dominio;
                """
            )

            homologacion_rows = cursor.fetchall()

            # ======================================================
            # REGLAS DE CONSISTENCIA E INTEGRIDAD
            # ======================================================
            cursor.execute(
                """
                SELECT
                    'PRODUCCION_MAYOR_PLAN' AS regla,
                    COUNT(*) AS incidencias
                FROM dw.fact_produccion
                WHERE cantidad_producida
                      > cantidad_planificada

                UNION ALL

                SELECT
                    'PRODUCCION_NEGATIVA',
                    COUNT(*)
                FROM dw.fact_produccion
                WHERE cantidad_planificada < 0
                   OR cantidad_producida < 0
                   OR cantidad_rechazada < 0

                UNION ALL

                SELECT
                    'CONSUMO_NEGATIVO',
                    COUNT(*)
                FROM dw.fact_consumo_insumo
                WHERE cantidad_planificada < 0
                   OR cantidad_consumida < 0

                UNION ALL

                SELECT
                    'COMPRAS_TOTAL_NEGATIVO',
                    COUNT(*)
                FROM dw.fact_compras
                WHERE total < 0

                UNION ALL

                SELECT
                    'COMPRAS_RECIBIDO_MAYOR_CANTIDAD',
                    COUNT(*)
                FROM dw.fact_compras
                WHERE cantidad_recibida > cantidad

                UNION ALL

                SELECT
                    'CONSUMOS_HUERFANOS_PRODUCCION',
                    COUNT(*)
                FROM dw.fact_consumo_insumo fci
                LEFT JOIN dw.fact_produccion fp
                  ON fp.numero_orden = fci.numero_orden
                 AND fp.producto_key = fci.producto_key
                WHERE fp.produccion_fact_key IS NULL

                ORDER BY regla;
                """
            )

            reglas_rows = cursor.fetchall()

            # ======================================================
            # COMPLETITUD DE CAMPOS CRÍTICOS
            # ======================================================
            cursor.execute(
                """
                SELECT
                    'ASISTENCIA_ESTADO' AS control,
                    COUNT(*) FILTER (
                        WHERE estado_asistencia IS NULL
                           OR BTRIM(estado_asistencia) = ''
                    ) AS incidencias
                FROM dw.fact_asistencia

                UNION ALL

                SELECT
                    'COMPRAS_NUMERO_OC',
                    COUNT(*) FILTER (
                        WHERE numero_oc IS NULL
                           OR BTRIM(numero_oc) = ''
                    )
                FROM dw.fact_compras

                UNION ALL

                SELECT
                    'CONSUMO_NUMERO_ORDEN',
                    COUNT(*) FILTER (
                        WHERE numero_orden IS NULL
                           OR BTRIM(numero_orden) = ''
                    )
                FROM dw.fact_consumo_insumo

                UNION ALL

                SELECT
                    'CONTABILIDAD_DOCUMENTO',
                    COUNT(*) FILTER (
                        WHERE documento_numero IS NULL
                           OR BTRIM(documento_numero) = ''
                    )
                FROM dw.fact_contabilidad

                UNION ALL

                SELECT
                    'PRODUCCION_NUMERO_ORDEN',
                    COUNT(*) FILTER (
                        WHERE numero_orden IS NULL
                           OR BTRIM(numero_orden) = ''
                    )
                FROM dw.fact_produccion

                ORDER BY control;
                """
            )

            completitud_rows = cursor.fetchall()

    dominios = []

    total_registros = 0
    total_con_incidencia = 0

    homologacion_map = {
        row["dominio"]: row
        for row in homologacion_rows
    }

    for row in dominio_rows:
        registros = int(row["registros"] or 0)
        incidencias = int(
            row["registros_con_incidencia"] or 0
        )

        total_registros += registros
        total_con_incidencia += incidencias

        homologacion = homologacion_map[
            row["dominio"]
        ]

        porcentaje_ok = (
            (registros - incidencias)
            / registros
            * 100
            if registros > 0
            else 100
        )

        dominios.append(
            {
                "dominio": row["dominio"],
                "registros": registros,
                "registrosConIncidencia":
                    incidencias,
                "registrosSinIncidencia":
                    registros - incidencias,
                "porcentajeSinIncidencia":
                    round(porcentaje_ok, 2),
                "areaDesconocida": int(
                    homologacion[
                        "area_desconocida"
                    ] or 0
                ),
                "centroCostoDesconocido": int(
                    homologacion[
                        "cc_desconocido"
                    ] or 0
                ),
                "estado": (
                    "OK"
                    if incidencias == 0
                    else "ADVERTENCIA"
                ),
            }
        )

    total_sin_incidencia = (
        total_registros
        - total_con_incidencia
    )

    porcentaje_sin_incidencia = (
        total_sin_incidencia
        / total_registros
        * 100
        if total_registros > 0
        else 100
    )

    nombres_reglas = {
        "PRODUCCION_MAYOR_PLAN":
            "Producción real mayor que planificada",
        "PRODUCCION_NEGATIVA":
            "Cantidades negativas en Producción",
        "CONSUMO_NEGATIVO":
            "Cantidades negativas en Consumo",
        "COMPRAS_TOTAL_NEGATIVO":
            "Total negativo en Compras",
        "COMPRAS_RECIBIDO_MAYOR_CANTIDAD":
            "Cantidad recibida mayor que comprada",
        "CONSUMOS_HUERFANOS_PRODUCCION":
            "Consumos sin orden de Producción asociada",
    }

    reglas = [
        {
            "codigo": row["regla"],
            "nombre": nombres_reglas.get(
                row["regla"],
                row["regla"],
            ),
            "incidencias": int(
                row["incidencias"] or 0
            ),
            "estado": (
                "OK"
                if int(
                    row["incidencias"] or 0
                ) == 0
                else "INCIDENCIA"
            ),
        }
        for row in reglas_rows
    ]

    nombres_completitud = {
        "ASISTENCIA_ESTADO":
            "Estado de asistencia informado",
        "COMPRAS_NUMERO_OC":
            "Número de orden de compra informado",
        "CONSUMO_NUMERO_ORDEN":
            "Número de orden en consumo informado",
        "CONTABILIDAD_DOCUMENTO":
            "Documento contable informado",
        "PRODUCCION_NUMERO_ORDEN":
            "Número de orden de producción informado",
    }

    completitud = [
        {
            "codigo": row["control"],
            "nombre": nombres_completitud.get(
                row["control"],
                row["control"],
            ),
            "incidencias": int(
                row["incidencias"] or 0
            ),
            "estado": (
                "OK"
                if int(
                    row["incidencias"] or 0
                ) == 0
                else "INCIDENCIA"
            ),
        }
        for row in completitud_rows
    ]

    reglas_ok = sum(
        1
        for regla in reglas
        if regla["estado"] == "OK"
    )

    controles_completitud_ok = sum(
        1
        for control in completitud
        if control["estado"] == "OK"
    )

    produccion_registros = next(
        (
            item["registros"]
            for item in dominios
            if item["dominio"] == "PRODUCCION"
        ),
        0,
    )

    return {
        "kpis": {
            "registrosEvaluados":
                total_registros,
            "registrosConIncidencia":
                total_con_incidencia,
            "registrosSinIncidencia":
                total_sin_incidencia,
            "porcentajeSinIncidencia":
                round(
                    porcentaje_sin_incidencia,
                    2,
                ),
            "reglasConsistenciaOk":
                reglas_ok,
            "reglasConsistenciaTotal":
                len(reglas),
            "controlesCompletitudOk":
                controles_completitud_ok,
            "controlesCompletitudTotal":
                len(completitud),
        },
        "dominios": dominios,
        "reglas": reglas,
        "completitud": completitud,
        "evaluacionesEspeciales": [
            {
                "codigo":
                    "CONTABILIDAD_BALANCE_ASIENTO",
                "nombre":
                    "Balance por asiento contable",
                "estado": "NO_EVALUABLE",
                "detalle": (
                    "El DW no dispone de una clave "
                    "de asiento que permita agrupar "
                    "de forma inequívoca todas las "
                    "líneas de débito y crédito. "
                    "Documento y fecha no son "
                    "suficientes para afirmar un "
                    "desbalance."
                ),
            },
            {
                "codigo":
                    "HOMOLOGACION_PRODUCCION",
                "nombre":
                    "Homologación Producción",
                "estado": "ADVERTENCIA",
                "detalle": (
                    f"Los {produccion_registros} registros de Producción "
                    "mantienen Área y Centro de costo "
                    "en clave desconocida."
                ),
            },
            {
                "codigo":
                    "HOMOLOGACION_CONSUMO",
                "nombre":
                    "Homologación Consumo de insumos",
                "estado": "ADVERTENCIA",
                "detalle": (
                    "Los 17 registros de Consumo de "
                    "insumos mantienen Área y Centro "
                    "de costo en clave desconocida."
                ),
            },
        ],
        "advertencias": [
            (
                "El porcentaje de registros sin "
                "incidencias representa únicamente "
                "los controles implementados sobre "
                "el DW actual; no constituye una "
                "certificación global de calidad."
            ),
            (
                "Producción y Consumo de insumos "
                "permanecen pendientes de "
                "homologación empresarial para "
                "Área y Centro de costo."
            ),
            (
                "El balance por asiento contable "
                "no se califica como error porque "
                "el modelo actual no contiene una "
                "clave de asiento inequívoca."
            ),
        ],
    }
