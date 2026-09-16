-- ============================================================
-- Industrias ABC - Data Warehouse
-- Script: 021_poblar_dim_fecha.sql
-- Objetivo:
--   Poblar la dimensión calendario con fechas reales.
-- Motor:
--   PostgreSQL
-- Esquema:
--   dw
--
-- Rango inicial:
--   2016-01-01 a 2030-12-31
--
-- Observación:
--   El script es idempotente. El rango puede ampliarse
--   posteriormente sin recrear la dimensión.
-- ============================================================

WITH parametros AS (
    SELECT
        DATE '2016-01-01' AS fecha_desde,
        DATE '2030-12-31' AS fecha_hasta
),
fechas AS (
    SELECT
        serie::DATE AS fecha
    FROM parametros
    CROSS JOIN LATERAL generate_series(
        fecha_desde,
        fecha_hasta,
        INTERVAL '1 day'
    ) AS serie
)
INSERT INTO dw.dim_fecha (
    fecha_key,
    fecha,
    anio,
    semestre,
    trimestre,
    mes,
    nombre_mes,
    anio_mes,
    dia_mes,
    dia_anio,
    dia_semana,
    nombre_dia,
    anio_iso,
    semana_iso,
    es_dia_laboral_semana
)
SELECT
    (
        EXTRACT(YEAR FROM fecha)::INTEGER * 10000
        + EXTRACT(MONTH FROM fecha)::INTEGER * 100
        + EXTRACT(DAY FROM fecha)::INTEGER
    ) AS fecha_key,

    fecha,

    EXTRACT(YEAR FROM fecha)::SMALLINT AS anio,

    CASE
        WHEN EXTRACT(MONTH FROM fecha) BETWEEN 1 AND 6 THEN 1
        ELSE 2
    END::SMALLINT AS semestre,

    EXTRACT(QUARTER FROM fecha)::SMALLINT AS trimestre,

    EXTRACT(MONTH FROM fecha)::SMALLINT AS mes,

    CASE EXTRACT(MONTH FROM fecha)::INTEGER
        WHEN 1 THEN 'enero'
        WHEN 2 THEN 'febrero'
        WHEN 3 THEN 'marzo'
        WHEN 4 THEN 'abril'
        WHEN 5 THEN 'mayo'
        WHEN 6 THEN 'junio'
        WHEN 7 THEN 'julio'
        WHEN 8 THEN 'agosto'
        WHEN 9 THEN 'septiembre'
        WHEN 10 THEN 'octubre'
        WHEN 11 THEN 'noviembre'
        WHEN 12 THEN 'diciembre'
    END AS nombre_mes,

    TO_CHAR(fecha, 'YYYY-MM') AS anio_mes,

    EXTRACT(DAY FROM fecha)::SMALLINT AS dia_mes,

    EXTRACT(DOY FROM fecha)::SMALLINT AS dia_anio,

    EXTRACT(ISODOW FROM fecha)::SMALLINT AS dia_semana,

    CASE EXTRACT(ISODOW FROM fecha)::INTEGER
        WHEN 1 THEN 'lunes'
        WHEN 2 THEN 'martes'
        WHEN 3 THEN 'miércoles'
        WHEN 4 THEN 'jueves'
        WHEN 5 THEN 'viernes'
        WHEN 6 THEN 'sábado'
        WHEN 7 THEN 'domingo'
    END AS nombre_dia,

    EXTRACT(ISOYEAR FROM fecha)::SMALLINT AS anio_iso,

    EXTRACT(WEEK FROM fecha)::SMALLINT AS semana_iso,

    (
        EXTRACT(ISODOW FROM fecha)::INTEGER BETWEEN 1 AND 5
    ) AS es_dia_laboral_semana

FROM fechas

ON CONFLICT (fecha_key) DO NOTHING;
