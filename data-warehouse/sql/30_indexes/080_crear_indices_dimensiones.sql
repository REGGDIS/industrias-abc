-- ============================================================
-- Industrias ABC - Data Warehouse
-- Script: 080_crear_indices_dimensiones.sql
-- Objetivo:
--   Crear índices complementarios para las dimensiones CORE.
-- Motor:
--   PostgreSQL
-- Esquema:
--   dw
-- ============================================================

-- ============================================================
-- DIM_EMPLEADO
-- ============================================================

-- Garantiza que exista como máximo una versión actual
-- por RUT normalizado.
CREATE UNIQUE INDEX IF NOT EXISTS uq_dim_empleado_rut_actual
ON dw.dim_empleado (rut_normalizado)
WHERE es_actual = TRUE;

-- Optimiza la resolución histórica del empleado por:
--   RUT + fecha del hecho
-- siguiendo intervalos SCD2 [fecha_desde, fecha_hasta).
CREATE INDEX IF NOT EXISTS idx_dim_empleado_rut_vigencia
ON dw.dim_empleado (
    rut_normalizado,
    fecha_desde,
    fecha_hasta
);

-- PostgreSQL no crea automáticamente índices para las FK.
-- Estos índices facilitan joins y validaciones organizacionales.
CREATE INDEX IF NOT EXISTS idx_dim_empleado_area
ON dw.dim_empleado (area_key);

CREATE INDEX IF NOT EXISTS idx_dim_empleado_cargo
ON dw.dim_empleado (cargo_key);

CREATE INDEX IF NOT EXISTS idx_dim_empleado_centro_costo
ON dw.dim_empleado (centro_costo_key);
