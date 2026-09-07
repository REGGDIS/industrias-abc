-- ============================================================
-- Industrias ABC - Data Warehouse
-- Script: 998_instalar_dw_rrhh_asistencia.sql
-- Objetivo:
--   Instalar el paquete físico DW-RRHH / Asistencia.
--
-- Dependencia:
--   El DW-CORE debe estar instalado previamente.
--
-- Incluye:
--   FACT_ASISTENCIA
--   Índices complementarios de FACT_ASISTENCIA
--
-- Motor:
--   PostgreSQL
--
-- Cliente:
--   psql
-- ============================================================

\set ON_ERROR_STOP on

\echo '============================================================'
\echo 'Industrias ABC - Instalacion DW-RRHH / Asistencia'
\echo '============================================================'

BEGIN;

\echo '[1/2] Creando FACT_ASISTENCIA...'
\ir ../40_facts/100_crear_fact_asistencia.sql

\echo '[2/2] Creando indices de FACT_ASISTENCIA...'
\ir ../30_indexes/110_crear_indices_fact_asistencia.sql

COMMIT;

\echo '============================================================'
\echo 'DW-RRHH / Asistencia instalado correctamente.'
\echo '============================================================'