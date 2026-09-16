-- ============================================================
-- Industrias ABC - Data Warehouse
-- Script: 999_instalar_dw_core.sql
-- Objetivo:
--   Instalar de forma ordenada y reproducible el DW-CORE.
-- Motor:
--   PostgreSQL
--
-- Ejecución:
--   Este archivo debe ejecutarse mediante psql.
--
-- Observación:
--   Utiliza \ir para resolver las rutas relativamente a este
--   mismo archivo, independientemente del directorio desde el
--   cual se invoque psql.
-- ============================================================

\set ON_ERROR_STOP on

\echo '============================================================'
\echo 'Industrias ABC - Instalacion DW-CORE'
\echo '============================================================'

BEGIN;

-- ============================================================
-- 1. ESQUEMA
-- ============================================================

\echo '[1/9] Creando esquema dw...'
\ir ../00_schema/001_crear_esquema_dw.sql

-- ============================================================
-- 2. DIMENSION FECHA
-- ============================================================

\echo '[2/9] Creando DIM_FECHA...'
\ir ../20_dimensions/020_crear_dim_fecha.sql

\echo '[3/9] Poblando DIM_FECHA...'
\ir ../20_dimensions/021_poblar_dim_fecha.sql

-- ============================================================
-- 3. DIMENSIONES ORGANIZACIONALES
-- ============================================================

\echo '[4/9] Creando DIM_AREA...'
\ir ../20_dimensions/030_crear_dim_area.sql

\echo '[5/9] Creando DIM_CENTRO_COSTO...'
\ir ../20_dimensions/040_crear_dim_centro_costo.sql

\echo '[6/9] Creando DIM_CARGO...'
\ir ../20_dimensions/050_crear_dim_cargo.sql

-- ============================================================
-- 4. DIMENSION EMPLEADO
-- ============================================================

\echo '[7/9] Creando DIM_EMPLEADO...'
\ir ../20_dimensions/060_crear_dim_empleado.sql

-- ============================================================
-- 5. DIMENSION TURNO
-- ============================================================

\echo '[8/9] Creando DIM_TURNO...'
\ir ../20_dimensions/070_crear_dim_turno.sql

-- ============================================================
-- 6. INDICES COMPLEMENTARIOS
-- ============================================================

\echo '[9/9] Creando indices de dimensiones...'
\ir ../30_indexes/080_crear_indices_dimensiones.sql

COMMIT;

\echo '============================================================'
\echo 'DW-CORE instalado correctamente.'
\echo '============================================================'
