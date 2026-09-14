-- ============================================================
-- Industrias ABC - Data Warehouse
-- Script: 994_instalar_dw_contabilidad.sql
-- Objetivo: instalar el paquete físico DW-CONTABILIDAD.
-- Dependencias: DW-CORE previamente instalado.
-- Motor: PostgreSQL 16 / psql
-- ============================================================

\set ON_ERROR_STOP on

\echo '============================================================'
\echo 'Industrias ABC - Instalacion DW-CONTABILIDAD'
\echo '============================================================'

BEGIN;

\echo '[1/4] Creando DIM_CUENTA_CONTABLE...'
\ir ../20_dimensions/300_crear_dim_cuenta_contable.sql

\echo '[2/4] Creando indices de DIM_CUENTA_CONTABLE...'
\ir ../30_indexes/310_crear_indices_dim_cuenta_contable.sql

\echo '[3/4] Creando FACT_CONTABILIDAD...'
\ir ../40_facts/320_crear_fact_contabilidad.sql

\echo '[4/4] Creando indices de FACT_CONTABILIDAD...'
\ir ../30_indexes/330_crear_indices_fact_contabilidad.sql

COMMIT;

\echo '============================================================'
\echo 'DW-CONTABILIDAD instalado correctamente.'
\echo '============================================================'
