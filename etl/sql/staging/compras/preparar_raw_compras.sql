-- =====================================================================
--  preparar_raw_compras.sql
--  ETL Compras 0.4 · Preparación reproducible de fixtures RAW
--  Proyecto: Business Intelligence - Industrias ABC (Equipo BInnova)
--
--  OBJETIVO
--    Crear en la sesión actual las tablas temporales RAW necesarias para
--    ejecutar normalizar_compras.sql de forma reproducible.
--
--  IMPORTANTE
--    - No modifica las tablas operacionales.
--    - Solo crea TEMP TABLES dentro de la sesión psql actual.
--    - Debe ejecutarse en la misma sesión que normalizar_compras.sql.
-- =====================================================================

\set ON_ERROR_STOP on

DROP TABLE IF EXISTS stg_compras_ordenes_compra_raw;
DROP TABLE IF EXISTS stg_compras_proveedores_raw;
DROP TABLE IF EXISTS stg_compras_insumos_raw;
DROP TABLE IF EXISTS stg_compras_recepciones_raw;

CREATE TEMP TABLE stg_compras_ordenes_compra_raw AS
SELECT *
FROM ordenes_compra;

CREATE TEMP TABLE stg_compras_proveedores_raw AS
SELECT *
FROM proveedores;

CREATE TEMP TABLE stg_compras_insumos_raw AS
SELECT *
FROM insumos;

CREATE TEMP TABLE stg_compras_recepciones_raw AS
SELECT *
FROM recepciones;

\echo '=== FIXTURES RAW COMPRAS PREPARADOS ==='

SELECT 'ordenes_compra' AS entidad, COUNT(*) AS filas
FROM stg_compras_ordenes_compra_raw

UNION ALL

SELECT 'proveedores', COUNT(*)
FROM stg_compras_proveedores_raw

UNION ALL

SELECT 'insumos', COUNT(*)
FROM stg_compras_insumos_raw

UNION ALL

SELECT 'recepciones', COUNT(*)
FROM stg_compras_recepciones_raw

ORDER BY entidad;

-- Fin de preparar_raw_compras.sql