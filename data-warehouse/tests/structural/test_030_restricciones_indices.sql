-- ============================================================
-- Industrias ABC - Data Warehouse
-- Test: test_030_restricciones_indices.sql
-- Objetivo:
--   Verificar restricciones e índices críticos del DW-CORE.
-- Motor:
--   PostgreSQL
-- Esquema:
--   dw
-- ============================================================

DO $$
DECLARE
    objeto_faltante TEXT;
BEGIN
    -- ========================================================
    -- PRIMARY KEYS
    -- ========================================================

    SELECT nombre
    INTO objeto_faltante
    FROM (
        VALUES
            ('pk_dim_fecha'),
            ('pk_dim_area'),
            ('pk_dim_centro_costo'),
            ('pk_dim_cargo'),
            ('pk_dim_empleado'),
            ('pk_dim_turno')
    ) AS esperadas(nombre)
    WHERE NOT EXISTS (
        SELECT 1
        FROM pg_constraint c
        JOIN pg_namespace n
          ON n.oid = c.connamespace
        WHERE n.nspname = 'dw'
          AND c.conname = esperadas.nombre
          AND c.contype = 'p'
    )
    LIMIT 1;

    IF objeto_faltante IS NOT NULL THEN
        RAISE EXCEPTION
            'TEST FALLIDO: falta la PRIMARY KEY %.',
            objeto_faltante;
    END IF;

    -- ========================================================
    -- UNIQUE CONSTRAINTS
    -- ========================================================

    objeto_faltante := NULL;

    SELECT nombre
    INTO objeto_faltante
    FROM (
        VALUES
            ('uq_dim_fecha_fecha'),
            ('uq_dim_area_codigo'),
            ('uq_dim_centro_costo_codigo'),
            ('uq_dim_cargo_codigo'),
            ('uq_dim_empleado_rut_fecha_desde'),
            ('uq_dim_turno_bk')
    ) AS esperadas(nombre)
    WHERE NOT EXISTS (
        SELECT 1
        FROM pg_constraint c
        JOIN pg_namespace n
          ON n.oid = c.connamespace
        WHERE n.nspname = 'dw'
          AND c.conname = esperadas.nombre
          AND c.contype = 'u'
    )
    LIMIT 1;

    IF objeto_faltante IS NOT NULL THEN
        RAISE EXCEPTION
            'TEST FALLIDO: falta la restriccion UNIQUE %.',
            objeto_faltante;
    END IF;

    -- ========================================================
    -- FOREIGN KEYS DE DIM_EMPLEADO
    -- ========================================================

    objeto_faltante := NULL;

    SELECT nombre
    INTO objeto_faltante
    FROM (
        VALUES
            ('fk_dim_empleado_area'),
            ('fk_dim_empleado_cargo'),
            ('fk_dim_empleado_centro_costo')
    ) AS esperadas(nombre)
    WHERE NOT EXISTS (
        SELECT 1
        FROM pg_constraint c
        JOIN pg_namespace n
          ON n.oid = c.connamespace
        WHERE n.nspname = 'dw'
          AND c.conname = esperadas.nombre
          AND c.contype = 'f'
    )
    LIMIT 1;

    IF objeto_faltante IS NOT NULL THEN
        RAISE EXCEPTION
            'TEST FALLIDO: falta la FOREIGN KEY %.',
            objeto_faltante;
    END IF;

    -- ========================================================
    -- INDICES CRITICOS DE DIM_EMPLEADO
    -- ========================================================

    objeto_faltante := NULL;

    SELECT nombre
    INTO objeto_faltante
    FROM (
        VALUES
            ('uq_dim_empleado_rut_actual'),
            ('idx_dim_empleado_rut_vigencia'),
            ('idx_dim_empleado_area'),
            ('idx_dim_empleado_cargo'),
            ('idx_dim_empleado_centro_costo')
    ) AS esperadas(nombre)
    WHERE NOT EXISTS (
        SELECT 1
        FROM pg_indexes i
        WHERE i.schemaname = 'dw'
          AND i.tablename = 'dim_empleado'
          AND i.indexname = esperadas.nombre
    )
    LIMIT 1;

    IF objeto_faltante IS NOT NULL THEN
        RAISE EXCEPTION
            'TEST FALLIDO: falta el indice %.',
            objeto_faltante;
    END IF;

    -- ========================================================
    -- INDICE UNICO PARCIAL SCD2
    -- ========================================================

    IF NOT EXISTS (
        SELECT 1
        FROM pg_indexes i
        WHERE i.schemaname = 'dw'
          AND i.tablename = 'dim_empleado'
          AND i.indexname = 'uq_dim_empleado_rut_actual'
          AND i.indexdef ILIKE '%UNIQUE INDEX%'
          AND i.indexdef ILIKE '%WHERE%es_actual%'
    ) THEN
        RAISE EXCEPTION
            'TEST FALLIDO: uq_dim_empleado_rut_actual no es un indice unico parcial sobre es_actual.';
    END IF;
END
$$;

SELECT
    'TEST OK: restricciones e indices CORE verificados.' AS resultado;
