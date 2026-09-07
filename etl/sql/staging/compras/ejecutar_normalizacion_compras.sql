-- =====================================================================
--  ejecutar_normalizacion_compras.sql
--  ETL Compras 0.4 · Ejecución reproducible completa
--  Proyecto: Business Intelligence - Industrias ABC (Equipo BInnova)
--
--  OBJETIVO
--    Ejecutar en una sola sesión:
--      1) preparación de fixtures RAW temporales
--      2) normalización y estandarización de Compras
--
--  De esta forma normalizar_compras.sql no depende de una preparación
--  manual previa de tablas temporales.
-- =====================================================================

\set ON_ERROR_STOP on

\echo '=== PASO 1: PREPARAR RAW COMPRAS ==='
\ir preparar_raw_compras.sql

\echo '=== PASO 2: NORMALIZAR COMPRAS ==='
\ir normalizar_compras.sql

\echo '=== NORMALIZACION COMPRAS 0.4 FINALIZADA ==='

-- Fin de ejecutar_normalizacion_compras.sql