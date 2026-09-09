-- ============================================================
-- Industrias ABC - Data Warehouse
-- Script: 996_instalar_dw_compras.sql
-- Objetivo:
--   Instalar el paquete físico DW-COMPRAS.
--
-- Dependencia:
--   El DW-CORE debe estar instalado previamente
--   (esquema dw, dim_fecha, dim_area, dim_centro_costo).
--
-- Incluye:
--   DIM_PROVEEDOR
--   DIM_INSUMO
--   FACT_COMPRAS
--   Índices complementarios de Compras
--
-- Motor:   PostgreSQL
-- Cliente: psql
--
-- Observación:
--   Usa \ir para resolver rutas relativas a este archivo.
--   Transaccional (BEGIN/COMMIT) y con ON_ERROR_STOP.
-- ============================================================

\set ON_ERROR_STOP on

\echo '============================================================'
\echo 'Industrias ABC - Instalacion DW-COMPRAS'
\echo '============================================================'

BEGIN;

\echo '[1/4] Creando DIM_PROVEEDOR...'
\ir ../20_dimensions/160_crear_dim_proveedor.sql

\echo '[2/4] Creando DIM_INSUMO...'
\ir ../20_dimensions/170_crear_dim_insumo.sql

\echo '[3/4] Creando FACT_COMPRAS...'
\ir ../40_facts/180_crear_fact_compras.sql

\echo '[4/4] Creando indices de Compras...'
\ir ../30_indexes/190_crear_indices_compras.sql

COMMIT;

\echo '============================================================'
\echo 'DW-COMPRAS instalado correctamente.'
\echo '============================================================'
