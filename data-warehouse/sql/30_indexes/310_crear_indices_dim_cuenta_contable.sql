-- ============================================================
-- Industrias ABC - Data Warehouse
-- Índices DIM_CUENTA_CONTABLE
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_dim_cuenta_contable_tipo
    ON dw.dim_cuenta_contable (tipo_cuenta);

CREATE INDEX IF NOT EXISTS idx_dim_cuenta_contable_grupo
    ON dw.dim_cuenta_contable (grupo);

CREATE INDEX IF NOT EXISTS idx_dim_cuenta_contable_padre
    ON dw.dim_cuenta_contable (codigo_cuenta_padre);
