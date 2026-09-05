\set ON_ERROR_STOP on

BEGIN ISOLATION LEVEL REPEATABLE READ;

-- =============================================================================
-- FIXTURE TEMPORAL SOURCE -> RAW
-- No modifica tablas operacionales ni crea objetos permanentes.
-- =============================================================================

CREATE TEMP TABLE stg_contabilidad_areas_raw ON COMMIT DROP AS
SELECT *
FROM areas;

CREATE TEMP TABLE stg_contabilidad_centros_costo_raw ON COMMIT DROP AS
SELECT *
FROM centros_costo;

CREATE TEMP TABLE stg_contabilidad_cuentas_contables_raw ON COMMIT DROP AS
SELECT *
FROM cuentas_contables;

CREATE TEMP TABLE stg_contabilidad_movimientos_contables_raw ON COMMIT DROP AS
SELECT *
FROM movimientos_contables;


-- =============================================================================
-- STAGING / CLEAN
-- Reproduce las transformaciones aprobadas del ETL Contabilidad 0.1.
-- =============================================================================

CREATE TEMP TABLE stg_contabilidad_areas_clean ON COMMIT DROP AS
SELECT
    area_id,
    UPPER(TRIM(codigo_area)) AS codigo_area,
    TRIM(nombre_area) AS nombre_area
FROM stg_contabilidad_areas_raw;

CREATE TEMP TABLE stg_contabilidad_centros_costo_clean ON COMMIT DROP AS
SELECT
    centro_costo_id,
    UPPER(TRIM(codigo)) AS codigo,
    TRIM(nombre) AS nombre,
    area_id,
    NULLIF(TRIM(responsable), '') AS responsable,
    UPPER(TRIM(estado)) AS estado
FROM stg_contabilidad_centros_costo_raw;

CREATE TEMP TABLE stg_contabilidad_cuentas_contables_clean ON COMMIT DROP AS
SELECT
    cuenta_id,
    UPPER(TRIM(codigo_cuenta)) AS codigo_cuenta,
    TRIM(nombre_cuenta) AS nombre_cuenta,
    UPPER(TRIM(tipo_cuenta)) AS tipo_cuenta,
    UPPER(TRIM(grupo)) AS grupo,
    nivel,
    cuenta_padre_id,
    UPPER(TRIM(estado)) AS estado
FROM stg_contabilidad_cuentas_contables_raw;

CREATE TEMP TABLE stg_contabilidad_movimientos_contables_clean ON COMMIT DROP AS
SELECT
    movimiento_id,
    CAST(fecha AS DATE) AS fecha,
    cuenta_id,
    centro_costo_id,
    UPPER(TRIM(documento_tipo)) AS documento_tipo,
    TRIM(documento_numero) AS documento_numero,
    TRIM(descripcion) AS descripcion,
    debe,
    haber,
    UPPER(TRIM(moneda)) AS moneda,
    tipo_cambio
FROM stg_contabilidad_movimientos_contables_raw;


-- =============================================================================
-- CONTROLES DE CALIDAD Y RECONCILIACIÓN
-- Una sola fuente de verdad compartida con el runner Python.
-- =============================================================================

\ir ../../validate/contabilidad/controles.sql

ROLLBACK;
