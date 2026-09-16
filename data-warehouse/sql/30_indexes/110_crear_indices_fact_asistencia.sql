-- ============================================================
-- Industrias ABC - Data Warehouse
-- Script: 110_crear_indices_fact_asistencia.sql
-- Objetivo:
--   Crear índices complementarios para FACT_ASISTENCIA.
--
-- Motor:
--   PostgreSQL
--
-- Esquema:
--   dw
-- ============================================================

-- ============================================================
-- FECHA
-- Permite consultas y agregaciones eficientes por período.
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_fact_asistencia_fecha
    ON dw.fact_asistencia (fecha_key);

-- ============================================================
-- TURNO
-- Facilita análisis y filtros por turno operacional.
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_fact_asistencia_turno
    ON dw.fact_asistencia (turno_key);

-- ============================================================
-- ÁREA
-- Facilita análisis organizacional por área.
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_fact_asistencia_area
    ON dw.fact_asistencia (area_key);

-- ============================================================
-- CENTRO DE COSTO
-- Facilita análisis e integración con otras FACT.
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_fact_asistencia_centro_costo
    ON dw.fact_asistencia (centro_costo_key);