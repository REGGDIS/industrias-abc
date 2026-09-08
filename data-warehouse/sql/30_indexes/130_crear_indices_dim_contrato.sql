-- ============================================================
-- Industrias ABC - Data Warehouse
-- Script: 130_crear_indices_dim_contrato.sql
-- Objetivo:
--   Crear índices complementarios para DIM_CONTRATO.
--
-- Motor:
--   PostgreSQL
--
-- Esquema:
--   dw
-- ============================================================

-- ============================================================
-- EMPLEADO
-- Facilita búsqueda de contratos asociados a un empleado.
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_dim_contrato_empleado
    ON dw.dim_contrato (empleado_key);

-- ============================================================
-- CARGO
-- Facilita análisis contractual por cargo.
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_dim_contrato_cargo
    ON dw.dim_contrato (cargo_key);

-- ============================================================
-- ESTADO
-- Facilita filtros por contrato vigente o terminado.
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_dim_contrato_estado
    ON dw.dim_contrato (estado_contrato);

-- ============================================================
-- FECHAS DE VIGENCIA
-- Facilita búsqueda temporal de contratos.
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_dim_contrato_vigencia
    ON dw.dim_contrato (fecha_inicio, fecha_termino);