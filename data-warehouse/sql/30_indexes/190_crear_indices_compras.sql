-- ============================================================
-- Industrias ABC - Data Warehouse
-- Script: 190_crear_indices_compras.sql
-- Objetivo:
--   Índices complementarios del dominio Compras.
-- Motor:
--   PostgreSQL
-- Esquema:
--   dw
--
-- Criterio:
--   - Las business keys de DIM_PROVEEDOR y DIM_INSUMO ya quedan
--     indexadas por sus restricciones UNIQUE; no se crean índices
--     redundantes sobre ellas.
--   - PostgreSQL no crea índices automáticos para las FOREIGN KEY.
--     Se indexan las FK de FACT_COMPRAS usadas en joins/filtros.
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_fact_compras_fecha_emision
    ON dw.fact_compras (fecha_emision_key);

CREATE INDEX IF NOT EXISTS idx_fact_compras_fecha_requerida
    ON dw.fact_compras (fecha_requerida_key);

CREATE INDEX IF NOT EXISTS idx_fact_compras_proveedor
    ON dw.fact_compras (proveedor_key);

CREATE INDEX IF NOT EXISTS idx_fact_compras_insumo
    ON dw.fact_compras (insumo_key);

CREATE INDEX IF NOT EXISTS idx_fact_compras_centro_costo
    ON dw.fact_compras (centro_costo_key);

CREATE INDEX IF NOT EXISTS idx_fact_compras_area
    ON dw.fact_compras (area_key);
