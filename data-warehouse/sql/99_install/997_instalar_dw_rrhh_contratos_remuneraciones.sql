-- ============================================================
-- Industrias ABC - Data Warehouse
-- Script: 997_instalar_dw_rrhh_contratos_remuneraciones.sql
-- Objetivo:
--   Instalar el paquete físico DW-RRHH 0.3:
--   contratos y remuneraciones.
--
-- Dependencia:
--   El DW-CORE debe estar instalado previamente.
--
-- Incluye:
--   DIM_CONTRATO
--   Índices de DIM_CONTRATO
--   FACT_REMUNERACIONES
--   Índices de FACT_REMUNERACIONES
--
-- Motor:
--   PostgreSQL
--
-- Cliente:
--   psql
-- ============================================================

\set ON_ERROR_STOP on

\echo '============================================================'
\echo 'Industrias ABC - Instalacion DW-RRHH 0.3'
\echo 'Contratos y Remuneraciones'
\echo '============================================================'

BEGIN;

\echo '[1/4] Creando DIM_CONTRATO...'
\ir ../20_dimensions/120_crear_dim_contrato.sql

\echo '[2/4] Creando indices de DIM_CONTRATO...'
\ir ../30_indexes/130_crear_indices_dim_contrato.sql

\echo '[3/4] Creando FACT_REMUNERACIONES...'
\ir ../40_facts/140_crear_fact_remuneraciones.sql

\echo '[4/4] Creando indices de FACT_REMUNERACIONES...'
\ir ../30_indexes/150_crear_indices_fact_remuneraciones.sql

COMMIT;

\echo '============================================================'
\echo 'DW-RRHH 0.3 instalado correctamente.'
\echo '============================================================'