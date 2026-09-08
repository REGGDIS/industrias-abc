-- ============================================================
-- Industrias ABC - Data Warehouse
-- Script: 150_crear_indices_fact_remuneraciones.sql
-- Objetivo:
--   Crear índices complementarios para FACT_REMUNERACIONES.
--
-- Motor:
--   PostgreSQL
--
-- Esquema:
--   dw
-- ============================================================

-- ============================================================
-- FECHA
-- Facilita análisis y agregaciones por período.
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_fact_remuneraciones_fecha
    ON dw.fact_remuneraciones (fecha_key);

-- ============================================================
-- CONTRATO
-- Facilita análisis de liquidaciones por contrato.
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_fact_remuneraciones_contrato
    ON dw.fact_remuneraciones (contrato_key);

-- ============================================================
-- ÁREA
-- Facilita análisis organizacional.
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_fact_remuneraciones_area
    ON dw.fact_remuneraciones (area_key);

-- ============================================================
-- CARGO
-- Facilita análisis por cargo.
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_fact_remuneraciones_cargo
    ON dw.fact_remuneraciones (cargo_key);

-- ============================================================
-- CENTRO DE COSTO
-- Facilita análisis financiero y organizacional.
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_fact_remuneraciones_centro_costo
    ON dw.fact_remuneraciones (centro_costo_key);