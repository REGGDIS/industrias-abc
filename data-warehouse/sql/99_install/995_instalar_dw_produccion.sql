-- ============================================================
-- Industrias ABC - Data Warehouse
-- Script: 995_instalar_dw_produccion.sql
-- Objetivo:
--   Instalar el paquete físico DW-PRODUCCIÓN.
--
-- Dependencias:
--   El DW-CORE debe estar instalado previamente:
--   - dw.dim_fecha
--   - dw.dim_area
--   - dw.dim_centro_costo
--
--   También debe existir:
--   - dw.dim_insumo
--
-- Incluye:
--   DIM_PRODUCTO
--   FACT_PRODUCCION
--   FACT_CONSUMO_INSUMO
--   Índices complementarios de Producción
--
-- Motor:   PostgreSQL 16
-- Cliente: psql
--
-- Observación:
--   Utiliza \ir para resolver rutas relativas a este archivo.
--   Es transaccional y utiliza ON_ERROR_STOP.
-- ============================================================

\set ON_ERROR_STOP on

\echo '============================================================'
\echo 'Industrias ABC - Instalacion DW-PRODUCCION'
\echo '============================================================'

BEGIN;

\echo '[1/6] Creando DIM_PRODUCTO...'
\ir ../20_dimensions/200_crear_dim_producto.sql

\echo '[2/6] Creando indices de DIM_PRODUCTO...'
\ir ../30_indexes/210_crear_indices_dim_producto.sql

\echo '[3/6] Creando FACT_PRODUCCION...'
\ir ../40_facts/220_crear_fact_produccion.sql

\echo '[4/6] Creando indices de FACT_PRODUCCION...'
\ir ../30_indexes/230_crear_indices_fact_produccion.sql

\echo '[5/6] Creando FACT_CONSUMO_INSUMO...'
\ir ../40_facts/240_crear_fact_consumo_insumo.sql

\echo '[6/6] Creando indices de FACT_CONSUMO_INSUMO...'
\ir ../30_indexes/250_crear_indices_fact_consumo_insumo.sql

COMMIT;

\echo '============================================================'
\echo 'DW-PRODUCCION instalado correctamente.'
\echo '============================================================'