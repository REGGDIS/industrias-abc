-- ============================================================
-- Industrias ABC - Data Warehouse
-- Índices FACT_CONTABILIDAD
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_fact_contabilidad_fecha
    ON dw.fact_contabilidad (fecha_key);

CREATE INDEX IF NOT EXISTS idx_fact_contabilidad_cuenta
    ON dw.fact_contabilidad (cuenta_key);

CREATE INDEX IF NOT EXISTS idx_fact_contabilidad_area
    ON dw.fact_contabilidad (area_key);

CREATE INDEX IF NOT EXISTS idx_fact_contabilidad_centro_costo
    ON dw.fact_contabilidad (centro_costo_key);

CREATE INDEX IF NOT EXISTS idx_fact_contabilidad_documento
    ON dw.fact_contabilidad (documento_tipo, documento_numero);
