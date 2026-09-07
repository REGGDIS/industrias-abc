-- ============================================================
-- Industrias ABC - Data Warehouse
-- Script: 001_crear_esquema_dw.sql
-- Objetivo:
--   Crear el esquema principal del Data Warehouse.
-- Motor:
--   PostgreSQL
-- ============================================================

CREATE SCHEMA IF NOT EXISTS dw;

COMMENT ON SCHEMA dw IS
'Esquema principal del Data Warehouse de Industrias ABC.';
