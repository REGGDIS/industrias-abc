-- ============================================================
-- Industrias ABC - Data Warehouse
-- Script: 230_crear_indices_fact_produccion.sql
-- Objetivo:
--   Crear índices complementarios para FACT_PRODUCCION.
-- Motor:
--   PostgreSQL 16
-- Esquema:
--   dw
--
-- Criterio:
--   - La business key numero_orden ya queda indexada por su
--     restricción UNIQUE.
--   - PostgreSQL no crea índices automáticamente para las
--     FOREIGN KEY.
--   - Se indexan las FK utilizadas en joins, filtros y
--     validaciones.
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_fact_produccion_fecha_inicio
    ON dw.fact_produccion (fecha_inicio_key);

CREATE INDEX IF NOT EXISTS idx_fact_produccion_fecha_termino
    ON dw.fact_produccion (fecha_termino_key);

CREATE INDEX IF NOT EXISTS idx_fact_produccion_producto
    ON dw.fact_produccion (producto_key);

CREATE INDEX IF NOT EXISTS idx_fact_produccion_centro_costo
    ON dw.fact_produccion (centro_costo_key);

CREATE INDEX IF NOT EXISTS idx_fact_produccion_area
    ON dw.fact_produccion (area_key);