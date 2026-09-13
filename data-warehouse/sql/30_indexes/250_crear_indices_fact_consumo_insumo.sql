-- ============================================================
-- Industrias ABC - Data Warehouse
-- Script: 250_crear_indices_fact_consumo_insumo.sql
-- Objetivo:
--   Crear índices complementarios para
--   FACT_CONSUMO_INSUMO.
-- Motor:
--   PostgreSQL 16
-- Esquema:
--   dw
--
-- Criterio:
--   - consumo_id ya queda indexado mediante su restricción
--     UNIQUE.
--   - PostgreSQL no crea índices automáticamente para las
--     FOREIGN KEY.
--   - Se indexan las FK utilizadas en joins, filtros y
--     validaciones.
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_fact_consumo_insumo_fecha
    ON dw.fact_consumo_insumo (fecha_consumo_key);

CREATE INDEX IF NOT EXISTS idx_fact_consumo_insumo_producto
    ON dw.fact_consumo_insumo (producto_key);

CREATE INDEX IF NOT EXISTS idx_fact_consumo_insumo_insumo
    ON dw.fact_consumo_insumo (insumo_key);

CREATE INDEX IF NOT EXISTS idx_fact_consumo_insumo_centro_costo
    ON dw.fact_consumo_insumo (centro_costo_key);

CREATE INDEX IF NOT EXISTS idx_fact_consumo_insumo_area
    ON dw.fact_consumo_insumo (area_key);