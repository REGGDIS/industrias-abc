from __future__ import annotations

from calendar import monthrange
from datetime import date, timedelta

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


def resolver_corte_contratos(
    anio: int,
    mes: int | None = None,
) -> date:
    hoy = date.today()

    if anio > hoy.year:
        raise ValueError(
            "No hay datos contractuales disponibles "
            "para años futuros."
        )

    if mes is not None:
        if mes < 1 or mes > 12:
            raise ValueError(
                "El mes debe estar entre 1 y 12."
            )

        ultimo_dia = monthrange(anio, mes)[1]
        corte = date(anio, mes, ultimo_dia)

        if corte > hoy:
            corte = hoy

        return corte

    if anio == hoy.year:
        return hoy

    return date(anio, 12, 31)


def _crear_filtros(
    *,
    fecha_corte: date,
    area_id: int | None = None,
    trabajador_id: str | None = None,
) -> tuple[str, list[object]]:
    condiciones = [
        "dc.contrato_key > 0",
        "dc.fecha_inicio <= %s",
    ]

    params: list[object] = [fecha_corte]

    if area_id is not None:
        condiciones.append("de.area_key = %s")
        params.append(area_id)

    if trabajador_id is not None:
        condiciones.append(
            "de.rut_normalizado = %s"
        )
        params.append(trabajador_id)

    return " AND ".join(condiciones), params


def obtener_resumen_contratos(
    *,
    anio: int,
    mes: int | None = None,
    area_id: int | None = None,
    trabajador_id: str | None = None,
) -> dict:
    fecha_corte = resolver_corte_contratos(
        anio,
        mes,
    )

    where_sql, params = _crear_filtros(
        fecha_corte=fecha_corte,
        area_id=area_id,
        trabajador_id=trabajador_id,
    )

    sql_metricas = f"""
        SELECT
            COUNT(*) FILTER (
                WHERE dc.fecha_termino IS NULL
                   OR dc.fecha_termino >= %s
            ) AS vigentes,

            COUNT(*) FILTER (
                WHERE (
                    dc.fecha_termino IS NULL
                    OR dc.fecha_termino >= %s
                )
                AND dc.tipo_contrato = 'INDEFINIDO'
            ) AS indefinidos,

            COUNT(*) FILTER (
                WHERE (
                    dc.fecha_termino IS NULL
                    OR dc.fecha_termino >= %s
                )
                AND dc.tipo_contrato = 'PLAZO_FIJO'
            ) AS plazo_fijo,

            COUNT(*) FILTER (
                WHERE (
                    dc.fecha_termino IS NULL
                    OR dc.fecha_termino >= %s
                )
                AND dc.tipo_contrato = 'TEMPORAL'
            ) AS temporales,

            COUNT(*) FILTER (
                WHERE dc.fecha_termino > %s
                  AND dc.fecha_termino
                      <= %s + INTERVAL '90 days'
            ) AS proximos_vencer,

            COUNT(*) FILTER (
                WHERE dc.fecha_termino < %s
            ) AS vencidos,

            COUNT(*) AS contratos_visibles,
            COUNT(
                DISTINCT de.rut_normalizado
            ) AS trabajadores_con_contrato
        FROM dw.dim_contrato dc
        JOIN dw.dim_empleado de
          ON de.empleado_key = dc.empleado_key
        WHERE {where_sql};
    """

    metric_params = [
        fecha_corte,
        fecha_corte,
        fecha_corte,
        fecha_corte,
        fecha_corte,
        fecha_corte,
        fecha_corte,
        *params,
    ]

    with get_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                sql_metricas,
                metric_params,
            )
            metricas = dict(cursor.fetchone())

            cursor.execute(
                f"""
                SELECT
                    dc.tipo_contrato AS label,
                    COUNT(*) AS value
                FROM dw.dim_contrato dc
                JOIN dw.dim_empleado de
                  ON de.empleado_key = dc.empleado_key
                WHERE {where_sql}
                  AND (
                      dc.fecha_termino IS NULL
                      OR dc.fecha_termino >= %s
                  )
                GROUP BY dc.tipo_contrato
                ORDER BY value DESC, label;
                """,
                [*params, fecha_corte],
            )
            contratos_por_tipo = [
                dict(row)
                for row in cursor.fetchall()
            ]

            cursor.execute(
                f"""
                SELECT
                    EXTRACT(
                        MONTH FROM dc.fecha_termino
                    )::int AS mes,
                    COUNT(*) AS value
                FROM dw.dim_contrato dc
                JOIN dw.dim_empleado de
                  ON de.empleado_key = dc.empleado_key
                WHERE {where_sql}
                  AND dc.fecha_termino IS NOT NULL
                  AND EXTRACT(
                      YEAR FROM dc.fecha_termino
                  )::int = %s
                GROUP BY
                    EXTRACT(
                        MONTH FROM dc.fecha_termino
                    )
                ORDER BY mes;
                """,
                [*params, anio],
            )
            vencimientos_rows = [
                dict(row)
                for row in cursor.fetchall()
            ]

    vencimientos_map = {
        int(row["mes"]): int(row["value"])
        for row in vencimientos_rows
    }

    meses_a_mostrar = (
        [mes]
        if mes is not None
        else list(range(1, 13))
    )

    vencimientos_por_mes = [
        {
            "anio": anio,
            "mes": numero_mes,
            "label": MESES[numero_mes - 1][:3],
            "value": vencimientos_map.get(
                numero_mes,
                0,
            ),
        }
        for numero_mes in meses_a_mostrar
    ]

    return {
        "periodo": {
            "anio": anio,
            "mes": (
                mes
                if mes is not None
                else fecha_corte.month
            ),
            "fechaCorte":
                fecha_corte.isoformat(),
        },
        "filtrosAplicados": {
            "areaId": area_id,
            "trabajadorId": trabajador_id,
        },
        "kpis": {
            "vigentes":
                int(metricas["vigentes"] or 0),
            "indefinidos":
                int(metricas["indefinidos"] or 0),
            "plazoFijo":
                int(metricas["plazo_fijo"] or 0),
            "temporales":
                int(metricas["temporales"] or 0),
            "proximosVencer":
                int(
                    metricas[
                        "proximos_vencer"
                    ] or 0
                ),
            "vencidos":
                int(metricas["vencidos"] or 0),
        },
        "contratosPorTipo": [
            {
                "label": row["label"],
                "value": int(row["value"]),
            }
            for row in contratos_por_tipo
        ],
        "vencimientosPorMes":
            vencimientos_por_mes,
        "calidadDatos": {
            "datosDisponibles":
                int(
                    metricas[
                        "contratos_visibles"
                    ] or 0
                ) > 0,
            "contratosVisibles":
                int(
                    metricas[
                        "contratos_visibles"
                    ] or 0
                ),
            "trabajadoresConContrato":
                int(
                    metricas[
                        "trabajadores_con_contrato"
                    ] or 0
                ),
        },
    }


def obtener_detalle_contratos(
    *,
    anio: int,
    mes: int | None = None,
    area_id: int | None = None,
    trabajador_id: str | None = None,
    page: int = 1,
    page_size: int = 20,
) -> dict:
    fecha_corte = resolver_corte_contratos(
        anio,
        mes,
    )

    where_sql, params = _crear_filtros(
        fecha_corte=fecha_corte,
        area_id=area_id,
        trabajador_id=trabajador_id,
    )

    offset = (page - 1) * page_size

    with get_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                f"""
                SELECT COUNT(*) AS total
                FROM dw.dim_contrato dc
                JOIN dw.dim_empleado de
                  ON de.empleado_key = dc.empleado_key
                WHERE {where_sql};
                """,
                params,
            )
            total_row = cursor.fetchone()
            total = int(total_row["total"])

            cursor.execute(
                f"""
                SELECT
                    dc.contrato_key,
                    dc.numero_contrato,
                    de.rut_normalizado,
                    CONCAT_WS(
                        ' ',
                        de.nombres,
                        de.apellido_paterno,
                        de.apellido_materno
                    ) AS empleado,
                    da.nombre_area AS area,
                    dc.tipo_contrato,
                    dc.fecha_inicio,
                    dc.fecha_termino,
                    dc.jornada,
                    dc.sueldo_base_contractual,
                    dc.cargo_contrato
                FROM dw.dim_contrato dc
                JOIN dw.dim_empleado de
                  ON de.empleado_key = dc.empleado_key
                LEFT JOIN dw.dim_area da
                  ON da.area_key = de.area_key
                WHERE {where_sql}
                ORDER BY
                    CASE
                        WHEN (
                            dc.fecha_termino IS NULL
                            OR dc.fecha_termino >= %s
                        )
                        THEN 0
                        ELSE 1
                    END,
                    empleado
                LIMIT %s
                OFFSET %s;
                """,
                [
                    *params,
                    fecha_corte,
                    page_size,
                    offset,
                ],
            )

            rows = [
                dict(row)
                for row in cursor.fetchall()
            ]

    items = []

    for row in rows:
        fecha_termino = row["fecha_termino"]

        vigente = (
            fecha_termino is None
            or fecha_termino >= fecha_corte
        )

        dias_restantes = (
            (fecha_termino - fecha_corte).days
            if vigente
            and fecha_termino is not None
            else None
        )

        items.append(
            {
                "contratoId":
                    int(row["contrato_key"]),
                "numeroContrato":
                    row["numero_contrato"],
                "trabajadorId":
                    row["rut_normalizado"],
                "empleado": row["empleado"],
                "area": row["area"],
                "tipoContrato":
                    row["tipo_contrato"],
                "fechaInicio":
                    row["fecha_inicio"].isoformat(),
                "fechaTermino": (
                    fecha_termino.isoformat()
                    if fecha_termino
                    else None
                ),
                "diasRestantes":
                    dias_restantes,
                "estado": (
                    "VIGENTE"
                    if vigente
                    else "VENCIDO"
                ),
                "jornada": row["jornada"],
                "cargoContrato":
                    row["cargo_contrato"],
                "sueldoBaseContractual":
                    float(
                        row[
                            "sueldo_base_contractual"
                        ]
                    ),
            }
        )

    total_pages = (
        (total + page_size - 1)
        // page_size
        if total > 0
        else 0
    )

    return {
        "periodo": {
            "anio": anio,
            "mes": (
                mes
                if mes is not None
                else fecha_corte.month
            ),
            "fechaCorte":
                fecha_corte.isoformat(),
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


def obtener_trabajadores_contratos(
    *,
    anio: int,
    mes: int | None = None,
    area_id: int | None = None,
) -> dict:
    fecha_corte = resolver_corte_contratos(
        anio,
        mes,
    )

    where_sql, params = _crear_filtros(
        fecha_corte=fecha_corte,
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
                FROM dw.dim_contrato dc
                JOIN dw.dim_empleado de
                  ON de.empleado_key = dc.empleado_key
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
            "anio": anio,
            "mes": (
                mes
                if mes is not None
                else fecha_corte.month
            ),
        },
    }
