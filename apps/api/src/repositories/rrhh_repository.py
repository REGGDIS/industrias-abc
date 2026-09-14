from __future__ import annotations

import calendar
from datetime import date

from src.core.database import get_connection


MESES = {
    1: "Ene",
    2: "Feb",
    3: "Mar",
    4: "Abr",
    5: "May",
    6: "Jun",
    7: "Jul",
    8: "Ago",
    9: "Sep",
    10: "Oct",
    11: "Nov",
    12: "Dic",
}


def obtener_fecha_maxima_rrhh() -> date:
    sql = """
        SELECT MAX(fecha_desde) AS fecha_maxima
        FROM dw.dim_empleado
        WHERE empleado_key <> 0;
    """

    with get_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute(sql)
            row = cursor.fetchone()

    return row["fecha_maxima"]


def resolver_fecha_corte(
    anio: int,
    mes: int | None,
) -> date:
    fecha_maxima = obtener_fecha_maxima_rrhh()

    if anio > fecha_maxima.year:
        raise ValueError(
            f"No existen datos RRHH disponibles para el año {anio}."
        )

    if mes is not None and not 1 <= mes <= 12:
        raise ValueError("El mes debe estar entre 1 y 12.")

    if mes is None:
        if anio == fecha_maxima.year:
            return fecha_maxima

        return date(anio, 12, 31)

    ultimo_dia = calendar.monthrange(anio, mes)[1]
    cierre_mes = date(anio, mes, ultimo_dia)

    if cierre_mes > fecha_maxima:
        if (
            anio == fecha_maxima.year
            and mes == fecha_maxima.month
        ):
            return fecha_maxima

        raise ValueError(
            "El período solicitado es posterior "
            "al último período RRHH disponible."
        )

    return cierre_mes


def _crear_filtros(
    area_id: int | None,
    cargo_id: int | None,
) -> tuple[str, dict]:
    condiciones = []
    parametros = {}

    if area_id is not None:
        condiciones.append("e.area_key = %(area_id)s")
        parametros["area_id"] = area_id

    if cargo_id is not None:
        condiciones.append("e.cargo_key = %(cargo_id)s")
        parametros["cargo_id"] = cargo_id

    if not condiciones:
        return "", parametros

    return " AND " + " AND ".join(condiciones), parametros


def obtener_distribucion_area(
    fecha_corte: date,
    area_id: int | None,
    cargo_id: int | None,
) -> list[dict]:
    filtro_extra, filtros = _crear_filtros(area_id, cargo_id)

    parametros = {
        "fecha_corte": fecha_corte,
        **filtros,
    }

    sql = f"""
        SELECT
            a.nombre_area AS label,
            COUNT(DISTINCT e.rut_normalizado) AS value
        FROM dw.dim_empleado e
        JOIN dw.dim_area a
          ON a.area_key = e.area_key
        WHERE
            e.empleado_key <> 0
            AND e.fecha_desde <= %(fecha_corte)s
            AND (
                e.fecha_hasta IS NULL
                OR %(fecha_corte)s < e.fecha_hasta
            )
            {filtro_extra}
        GROUP BY
            a.area_key,
            a.nombre_area
        ORDER BY
            value DESC,
            a.nombre_area;
    """

    with get_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute(sql, parametros)
            return cursor.fetchall()


def obtener_distribucion_cargo(
    fecha_corte: date,
    area_id: int | None,
    cargo_id: int | None,
) -> list[dict]:
    filtro_extra, filtros = _crear_filtros(area_id, cargo_id)

    parametros = {
        "fecha_corte": fecha_corte,
        **filtros,
    }

    sql = f"""
        SELECT
            c.nombre_cargo AS label,
            COUNT(DISTINCT e.rut_normalizado) AS value
        FROM dw.dim_empleado e
        JOIN dw.dim_cargo c
          ON c.cargo_key = e.cargo_key
        WHERE
            e.empleado_key <> 0
            AND e.fecha_desde <= %(fecha_corte)s
            AND (
                e.fecha_hasta IS NULL
                OR %(fecha_corte)s < e.fecha_hasta
            )
            {filtro_extra}
        GROUP BY
            c.cargo_key,
            c.nombre_cargo
        ORDER BY
            value DESC,
            c.nombre_cargo;
    """

    with get_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute(sql, parametros)
            return cursor.fetchall()


def obtener_evolucion_dotacion(
    anio: int,
    fecha_corte: date,
    area_id: int | None,
    cargo_id: int | None,
) -> list[dict]:
    filtro_extra, filtros = _crear_filtros(area_id, cargo_id)

    parametros = {
        "anio": anio,
        "fecha_corte": fecha_corte,
        **filtros,
    }

    sql = f"""
        WITH meses AS (
            SELECT generate_series(
                make_date(%(anio)s, 1, 1),
                date_trunc(
                    'month',
                    %(fecha_corte)s::date
                )::date,
                interval '1 month'
            )::date AS mes_inicio
        ),
        cortes AS (
            SELECT
                mes_inicio,
                LEAST(
                    (
                        mes_inicio
                        + interval '1 month'
                        - interval '1 day'
                    )::date,
                    %(fecha_corte)s::date
                ) AS fecha_corte_mes
            FROM meses
        )
        SELECT
            EXTRACT(
                MONTH FROM c.mes_inicio
            )::int AS mes,
            COUNT(
                DISTINCT e.rut_normalizado
            ) AS value
        FROM cortes c
        LEFT JOIN dw.dim_empleado e
          ON e.empleado_key <> 0
         AND e.fecha_ingreso <= c.fecha_corte_mes
         AND (
                e.fecha_salida IS NULL
                OR e.fecha_salida > c.fecha_corte_mes
         )
         AND e.fecha_desde <= c.fecha_corte_mes
         AND (
                e.fecha_hasta IS NULL
                OR c.fecha_corte_mes < e.fecha_hasta
         )
         {filtro_extra}
        GROUP BY
            c.mes_inicio,
            c.fecha_corte_mes
        ORDER BY
            c.mes_inicio;
    """

    with get_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute(sql, parametros)
            rows = cursor.fetchall()

    return [
        {
            "anio": anio,
            "mes": row["mes"],
            "label": MESES[row["mes"]],
            "value": row["value"],
        }
        for row in rows
    ]


def obtener_rotacion(
    anio: int,
    mes: int | None,
    fecha_corte: date,
    area_id: int | None,
    cargo_id: int | None,
) -> dict:
    if mes is None:
        fecha_inicio = date(
            fecha_corte.year,
            fecha_corte.month,
            1,
        )
    else:
        fecha_inicio = date(anio, mes, 1)

    filtro_extra, filtros = _crear_filtros(
        area_id,
        cargo_id,
    )

    parametros = {
        "fecha_inicio": fecha_inicio,
        "fecha_corte": fecha_corte,
        **filtros,
    }

    sql_dotacion_inicio = f"""
        SELECT
            COUNT(DISTINCT e.rut_normalizado) AS dotacion
        FROM dw.dim_empleado e
        WHERE
            e.empleado_key <> 0
            AND e.fecha_ingreso <= %(fecha_inicio)s
            AND (
                e.fecha_salida IS NULL
                OR e.fecha_salida > %(fecha_inicio)s
            )
            AND e.fecha_desde <= %(fecha_inicio)s
            AND (
                e.fecha_hasta IS NULL
                OR %(fecha_inicio)s < e.fecha_hasta
            )
            {filtro_extra};
    """

    sql_dotacion_fin = f"""
        SELECT
            COUNT(DISTINCT e.rut_normalizado) AS dotacion
        FROM dw.dim_empleado e
        WHERE
            e.empleado_key <> 0
            AND e.fecha_ingreso <= %(fecha_corte)s
            AND (
                e.fecha_salida IS NULL
                OR e.fecha_salida > %(fecha_corte)s
            )
            AND e.fecha_desde <= %(fecha_corte)s
            AND (
                e.fecha_hasta IS NULL
                OR %(fecha_corte)s < e.fecha_hasta
            )
            {filtro_extra};
    """

    sql_salidas = f"""
        SELECT
            COUNT(DISTINCT e.rut_normalizado) AS salidas
        FROM dw.dim_empleado e
        WHERE
            e.empleado_key <> 0
            AND e.fecha_salida >= %(fecha_inicio)s
            AND e.fecha_salida <= %(fecha_corte)s
            AND e.fecha_desde <= e.fecha_salida
            AND (
                e.fecha_hasta IS NULL
                OR e.fecha_salida < e.fecha_hasta
            )
            {filtro_extra};
    """

    with get_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                sql_dotacion_inicio,
                parametros,
            )
            dotacion_inicio = (
                cursor.fetchone()["dotacion"] or 0
            )

            cursor.execute(
                sql_dotacion_fin,
                parametros,
            )
            dotacion_fin = (
                cursor.fetchone()["dotacion"] or 0
            )

            cursor.execute(
                sql_salidas,
                parametros,
            )
            salidas = (
                cursor.fetchone()["salidas"] or 0
            )

    dotacion_promedio = (
        dotacion_inicio + dotacion_fin
    ) / 2

    if dotacion_promedio == 0:
        valor = None
    else:
        valor = round(
            salidas
            / dotacion_promedio
            * 100,
            2,
        )

    return {
        "valor": valor,
        "fechaDesde": fecha_inicio.isoformat(),
        "fechaHasta": fecha_corte.isoformat(),
        "salidas": salidas,
        "dotacionInicio": dotacion_inicio,
        "dotacionFin": dotacion_fin,
        "dotacionPromedio": dotacion_promedio,
    }


def obtener_contratos_proximos_vencer(
    fecha_corte: date,
    area_id: int | None,
    cargo_id: int | None,
    ventana_dias: int = 90,
) -> dict:
    condiciones = []

    parametros = {
        "fecha_corte": fecha_corte,
        "ventana_dias": ventana_dias,
    }

    if area_id is not None:
        condiciones.append(
            "ev.area_key = %(area_id)s"
        )
        parametros["area_id"] = area_id

    if cargo_id is not None:
        condiciones.append(
            "ev.cargo_key = %(cargo_id)s"
        )
        parametros["cargo_id"] = cargo_id

    filtro_extra = ""

    if condiciones:
        filtro_extra = (
            " AND "
            + " AND ".join(condiciones)
        )

    sql = f"""
        WITH empleados_corte AS (
            SELECT
                e.rut_normalizado,
                e.area_key,
                e.cargo_key
            FROM dw.dim_empleado e
            WHERE
                e.empleado_key <> 0
                AND e.fecha_desde <= %(fecha_corte)s
                AND (
                    e.fecha_hasta IS NULL
                    OR %(fecha_corte)s < e.fecha_hasta
                )
        ),
        contratos_base AS (
            SELECT
                c.contrato_key,
                c.numero_contrato,
                c.fecha_inicio,
                c.fecha_termino,
                c.estado_contrato,
                ec.rut_normalizado
            FROM dw.dim_contrato c
            JOIN dw.dim_empleado ec
              ON ec.empleado_key = c.empleado_key
            WHERE
                c.contrato_key <> 0
        ),
        universo AS (
            SELECT
                COUNT(
                    DISTINCT ev.rut_normalizado
                ) AS total_trabajadores
            FROM empleados_corte ev
            WHERE
                TRUE
                {filtro_extra}
        ),
        cobertura AS (
            SELECT
                COUNT(
                    DISTINCT cb.rut_normalizado
                ) AS trabajadores_con_contrato
            FROM contratos_base cb
            JOIN empleados_corte ev
              ON ev.rut_normalizado = cb.rut_normalizado
            WHERE
                cb.fecha_inicio <= %(fecha_corte)s
                {filtro_extra}
        ),
        proximos AS (
            SELECT
                COUNT(*) AS contratos_proximos
            FROM contratos_base cb
            JOIN empleados_corte ev
              ON ev.rut_normalizado = cb.rut_normalizado
            WHERE
                cb.estado_contrato = 'VIGENTE'
                AND cb.fecha_inicio <= %(fecha_corte)s
                AND cb.fecha_termino IS NOT NULL
                AND cb.fecha_termino > %(fecha_corte)s
                AND cb.fecha_termino
                    <= (
                        %(fecha_corte)s
                        + (
                            %(ventana_dias)s
                            * INTERVAL '1 day'
                        )
                    )
                {filtro_extra}
        )
        SELECT
            p.contratos_proximos,
            c.trabajadores_con_contrato,
            u.total_trabajadores
        FROM proximos p
        CROSS JOIN cobertura c
        CROSS JOIN universo u;
    """

    with get_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                sql,
                parametros,
            )
            row = cursor.fetchone()

    contratos_proximos = (
        row["contratos_proximos"] or 0
    )

    trabajadores_con_contrato = (
        row["trabajadores_con_contrato"] or 0
    )

    total_trabajadores = (
        row["total_trabajadores"] or 0
    )

    if total_trabajadores == 0:
        porcentaje_cobertura = None
    else:
        porcentaje_cobertura = round(
            trabajadores_con_contrato
            / total_trabajadores
            * 100,
            2,
        )

    return {
        "valor": contratos_proximos,
        "ventanaDias": ventana_dias,
        "fechaCorte": fecha_corte.isoformat(),
        "trabajadoresConContrato": (
            trabajadores_con_contrato
        ),
        "totalTrabajadoresPeriodo": (
            total_trabajadores
        ),
        "porcentajeCobertura": (
            porcentaje_cobertura
        ),
        "coberturaParcial": (
            trabajadores_con_contrato
            < total_trabajadores
        ),
    }

def obtener_ausentismo(
    anio: int,
    mes: int | None,
    fecha_corte: date,
    area_id: int | None,
    cargo_id: int | None,
) -> dict:
    if mes is None:
        fecha_inicio = date(
            fecha_corte.year,
            fecha_corte.month,
            1,
        )
    else:
        fecha_inicio = date(anio, mes, 1)

    filtro_extra, filtros = _crear_filtros(
        area_id,
        cargo_id,
    )

    parametros = {
        "fecha_inicio": fecha_inicio,
        "fecha_corte": fecha_corte,
        **filtros,
    }

    sql_asistencia = f"""
        SELECT
            COUNT(*) AS registros,

            COUNT(
                DISTINCT e.rut_normalizado
            ) AS trabajadores,

            MIN(f.fecha) AS primera_fecha,
            MAX(f.fecha) AS ultima_fecha,

            COALESCE(
                SUM(a.dias_trabajados),
                0
            ) AS dias_trabajados,

            COALESCE(
                SUM(a.dias_ausentes),
                0
            ) AS dias_ausentes

        FROM dw.fact_asistencia a

        JOIN dw.dim_fecha f
          ON f.fecha_key = a.fecha_key

        JOIN dw.dim_empleado e
          ON e.empleado_key = a.empleado_key

        WHERE
            f.fecha >= %(fecha_inicio)s
            AND f.fecha <= %(fecha_corte)s
            {filtro_extra};
    """

    sql_universo = f"""
        SELECT
            COUNT(
                DISTINCT e.rut_normalizado
            ) AS total_trabajadores
        FROM dw.dim_empleado e
        WHERE
            e.empleado_key <> 0

            AND e.fecha_desde <= %(fecha_corte)s

            AND (
                e.fecha_hasta IS NULL
                OR %(fecha_corte)s < e.fecha_hasta
            )

            {filtro_extra};
    """

    with get_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                sql_asistencia,
                parametros,
            )
            asistencia = cursor.fetchone()

            cursor.execute(
                sql_universo,
                parametros,
            )
            universo = cursor.fetchone()

    registros = asistencia["registros"] or 0

    trabajadores = (
        asistencia["trabajadores"] or 0
    )

    dias_trabajados = (
        asistencia["dias_trabajados"] or 0
    )

    dias_ausentes = (
        asistencia["dias_ausentes"] or 0
    )

    total_trabajadores = (
        universo["total_trabajadores"] or 0
    )

    jornadas_observadas = (
        dias_trabajados + dias_ausentes
    )

    if registros == 0 or jornadas_observadas == 0:
        valor = None
    else:
        valor = round(
            dias_ausentes
            / jornadas_observadas
            * 100,
            2,
        )

    if total_trabajadores == 0:
        porcentaje_cobertura = None
    else:
        porcentaje_cobertura = round(
            trabajadores
            / total_trabajadores
            * 100,
            2,
        )

    primera_fecha = asistencia["primera_fecha"]
    ultima_fecha = asistencia["ultima_fecha"]

    return {
        "valor": valor,
        "periodoSolicitadoDesde": (
            fecha_inicio.isoformat()
        ),
        "periodoSolicitadoHasta": (
            fecha_corte.isoformat()
        ),
        "fechaDesdeDatos": (
            primera_fecha.isoformat()
            if primera_fecha
            else None
        ),
        "fechaHastaDatos": (
            ultima_fecha.isoformat()
            if ultima_fecha
            else None
        ),
        "registros": registros,
        "trabajadoresConAsistencia": trabajadores,
        "totalTrabajadoresPeriodo": total_trabajadores,
        "porcentajeCobertura": porcentaje_cobertura,
        "diasTrabajados": float(dias_trabajados),
        "diasAusentes": float(dias_ausentes),
        "jornadasObservadas": float(
            jornadas_observadas
        ),
        "coberturaParcial": (
            trabajadores < total_trabajadores
        ),
        "datosDisponibles": registros > 0,
    }

def obtener_trabajadores_rrhh(
    anio: int,
    mes: int | None,
    area_id: int | None,
    cargo_id: int | None,
    page: int,
    page_size: int,
) -> dict:
    fecha_corte = resolver_fecha_corte(
        anio,
        mes,
    )

    filtro_extra, filtros = _crear_filtros(
        area_id,
        cargo_id,
    )

    offset = (page - 1) * page_size

    parametros = {
        "fecha_corte": fecha_corte,
        "limit": page_size,
        "offset": offset,
        **filtros,
    }

    sql_total = f"""
        SELECT
            COUNT(
                DISTINCT e.rut_normalizado
            ) AS total
        FROM dw.dim_empleado e
        WHERE
            e.empleado_key <> 0

            AND e.fecha_desde <= %(fecha_corte)s

            AND (
                e.fecha_hasta IS NULL
                OR %(fecha_corte)s < e.fecha_hasta
            )

            {filtro_extra};
    """

    sql_items = f"""
        SELECT
            e.rut_normalizado AS trabajador_id,

            CONCAT_WS(
                ' ',
                e.nombres,
                e.apellido_paterno,
                e.apellido_materno
            ) AS nombre,

            e.rut_normalizado AS rut,

            a.nombre_area AS area,
            c.nombre_cargo AS cargo,

            e.fecha_ingreso,
            e.fecha_salida,

            e.estado_laboral AS estado,

            e.contexto_historico_estimado

        FROM dw.dim_empleado e

        JOIN dw.dim_area a
          ON a.area_key = e.area_key

        JOIN dw.dim_cargo c
          ON c.cargo_key = e.cargo_key

        WHERE
            e.empleado_key <> 0

            AND e.fecha_desde <= %(fecha_corte)s

            AND (
                e.fecha_hasta IS NULL
                OR %(fecha_corte)s < e.fecha_hasta
            )

            {filtro_extra}

        ORDER BY
            nombre,
            e.rut_normalizado

        LIMIT %(limit)s
        OFFSET %(offset)s;
    """

    with get_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                sql_total,
                parametros,
            )
            total = (
                cursor.fetchone()["total"] or 0
            )

            cursor.execute(
                sql_items,
                parametros,
            )
            rows = cursor.fetchall()

    total_pages = (
        (total + page_size - 1)
        // page_size
        if total > 0
        else 0
    )

    items = [
        {
            "trabajadorId": row["trabajador_id"],
            "nombre": row["nombre"],
            "rut": row["rut"],
            "area": row["area"],
            "cargo": row["cargo"],
            "fechaIngreso": (
                row["fecha_ingreso"].isoformat()
                if row["fecha_ingreso"]
                else None
            ),
            "fechaSalida": (
                row["fecha_salida"].isoformat()
                if row["fecha_salida"]
                else None
            ),
            "estado": row["estado"],
            "contextoHistoricoEstimado": bool(
                row["contexto_historico_estimado"]
            ),
        }
        for row in rows
    ]

    return {
        "periodo": {
            "anio": fecha_corte.year,
            "mes": fecha_corte.month,
            "fechaCorte": fecha_corte.isoformat(),
        },
        "filtrosAplicados": {
            "areaId": area_id,
            "cargoId": cargo_id,
        },
        "items": items,
        "page": page,
        "pageSize": page_size,
        "total": total,
        "totalPages": total_pages,
    }

def obtener_resumen_rrhh(
    anio: int,
    mes: int | None = None,
    area_id: int | None = None,
    cargo_id: int | None = None,
) -> dict:
    fecha_corte = resolver_fecha_corte(anio, mes)

    filtro_extra, filtros = _crear_filtros(
        area_id,
        cargo_id,
    )

    parametros = {
        "fecha_corte": fecha_corte,
        **filtros,
    }

    sql_snapshot = f"""
        SELECT
            COUNT(
                DISTINCT e.rut_normalizado
            ) AS total,

            COUNT(
                DISTINCT e.rut_normalizado
            ) FILTER (
                WHERE e.estado_laboral = 'ACTIVO'
            ) AS activos,

            COUNT(
                DISTINCT e.rut_normalizado
            ) FILTER (
                WHERE e.estado_laboral = 'INACTIVO'
            ) AS inactivos,

            BOOL_OR(
                e.contexto_historico_estimado
            ) AS contexto_historico_estimado

        FROM dw.dim_empleado e

        WHERE
            e.empleado_key <> 0
            AND e.fecha_desde <= %(fecha_corte)s
            AND (
                e.fecha_hasta IS NULL
                OR %(fecha_corte)s < e.fecha_hasta
            )
            {filtro_extra};
    """

    with get_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                sql_snapshot,
                parametros,
            )
            snapshot = cursor.fetchone()

    trabajadores_por_area = obtener_distribucion_area(
        fecha_corte,
        area_id,
        cargo_id,
    )

    trabajadores_por_cargo = obtener_distribucion_cargo(
        fecha_corte,
        area_id,
        cargo_id,
    )

    evolucion_dotacion = obtener_evolucion_dotacion(
        anio,
        fecha_corte,
        area_id,
        cargo_id,
    )

    rotacion = obtener_rotacion(
        anio,
        mes,
        fecha_corte,
        area_id,
        cargo_id,
    )

    contratos = obtener_contratos_proximos_vencer(
        fecha_corte,
        area_id,
        cargo_id,
        ventana_dias=90,
    )

    ausentismo = obtener_ausentismo(
        anio,
        mes,
        fecha_corte,
        area_id,
        cargo_id,
    )

    return {
        "periodo": {
            "anio": fecha_corte.year,
            "mes": fecha_corte.month,
            "fechaCorte": fecha_corte.isoformat(),
        },
        "filtrosAplicados": {
            "areaId": area_id,
            "cargoId": cargo_id,
        },
        "kpis": {
            "totalTrabajadores": snapshot["total"] or 0,
            "trabajadoresActivos": snapshot["activos"] or 0,
            "trabajadoresInactivos": snapshot["inactivos"] or 0,
            "rotacion": rotacion["valor"],
            "ausentismo": ausentismo["valor"],
            "contratosProximosVencer": contratos["valor"],
        },
        "calidadDatos": {
            "contextoHistoricoEstimado": bool(
                snapshot["contexto_historico_estimado"]
            ),
            "rotacion": {
                "fechaDesde": rotacion["fechaDesde"],
                "fechaHasta": rotacion["fechaHasta"],
                "salidas": rotacion["salidas"],
                "dotacionInicio": rotacion["dotacionInicio"],
                "dotacionFin": rotacion["dotacionFin"],
                "dotacionPromedio": rotacion["dotacionPromedio"],
            },
            "contratos": {
                "ventanaDias": contratos["ventanaDias"],
                "fechaCorte": contratos["fechaCorte"],
                "trabajadoresConContrato": (
                    contratos["trabajadoresConContrato"]
                ),
                "totalTrabajadoresPeriodo": (
                    contratos["totalTrabajadoresPeriodo"]
                ),
                "porcentajeCobertura": (
                    contratos["porcentajeCobertura"]
                ),
                "coberturaParcial": (
                    contratos["coberturaParcial"]
                ),
            },
            "ausentismo": {
                "periodoSolicitadoDesde": (
                    ausentismo["periodoSolicitadoDesde"]
                ),
                "periodoSolicitadoHasta": (
                    ausentismo["periodoSolicitadoHasta"]
                ),
                "fechaDesdeDatos": (
                    ausentismo["fechaDesdeDatos"]
                ),
                "fechaHastaDatos": (
                    ausentismo["fechaHastaDatos"]
                ),
                "registros": ausentismo["registros"],
                "trabajadoresConAsistencia": (
                    ausentismo["trabajadoresConAsistencia"]
                ),
                "totalTrabajadoresPeriodo": (
                    ausentismo["totalTrabajadoresPeriodo"]
                ),
                "porcentajeCobertura": (
                    ausentismo["porcentajeCobertura"]
                ),
                "diasTrabajados": (
                    ausentismo["diasTrabajados"]
                ),
                "diasAusentes": (
                    ausentismo["diasAusentes"]
                ),
                "jornadasObservadas": (
                    ausentismo["jornadasObservadas"]
                ),
                "coberturaParcial": (
                    ausentismo["coberturaParcial"]
                ),
                "datosDisponibles": (
                    ausentismo["datosDisponibles"]
                ),
            },
        },
        "trabajadoresPorArea": trabajadores_por_area,
        "trabajadoresPorCargo": trabajadores_por_cargo,
        "evolucionDotacion": evolucion_dotacion,
    }
