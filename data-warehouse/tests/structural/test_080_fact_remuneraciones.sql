-- ============================================================
-- Industrias ABC - Data Warehouse
-- Test: test_080_fact_remuneraciones.sql
-- Objetivo:
--   Verificar la estructura física de FACT_REMUNERACIONES.
--
-- Motor:
--   PostgreSQL
--
-- Esquema:
--   dw
-- ============================================================

DO $$
DECLARE
    faltantes TEXT;
BEGIN
    -- ========================================================
    -- 1. EXISTENCIA DE LA TABLA
    -- ========================================================

    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.tables
        WHERE table_schema = 'dw'
          AND table_name = 'fact_remuneraciones'
    ) THEN
        RAISE EXCEPTION
            'TEST FAIL: no existe dw.fact_remuneraciones';
    END IF;

    -- ========================================================
    -- 2. PRIMARY KEY
    -- ========================================================

    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint c
        JOIN pg_class t
          ON t.oid = c.conrelid
        JOIN pg_namespace n
          ON n.oid = t.relnamespace
        WHERE n.nspname = 'dw'
          AND t.relname = 'fact_remuneraciones'
          AND c.conname = 'pk_fact_remuneraciones'
          AND c.contype = 'p'
    ) THEN
        RAISE EXCEPTION
            'TEST FAIL: falta pk_fact_remuneraciones';
    END IF;

    -- ========================================================
    -- 3. UNIQUE DEL GRANO
    -- ========================================================

    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint c
        JOIN pg_class t
          ON t.oid = c.conrelid
        JOIN pg_namespace n
          ON n.oid = t.relnamespace
        WHERE n.nspname = 'dw'
          AND t.relname = 'fact_remuneraciones'
          AND c.conname = 'uq_fact_remuneraciones_empleado_periodo'
          AND c.contype = 'u'
    ) THEN
        RAISE EXCEPTION
            'TEST FAIL: falta uq_fact_remuneraciones_empleado_periodo';
    END IF;

    -- ========================================================
    -- 4. FOREIGN KEYS
    -- ========================================================

    SELECT string_agg(nombre, ', ')
    INTO faltantes
    FROM (
        SELECT nombre
        FROM (
            VALUES
                ('fk_fact_remuneraciones_fecha'),
                ('fk_fact_remuneraciones_empleado'),
                ('fk_fact_remuneraciones_area'),
                ('fk_fact_remuneraciones_cargo'),
                ('fk_fact_remuneraciones_centro_costo'),
                ('fk_fact_remuneraciones_contrato')
        ) AS esperadas(nombre)
        WHERE NOT EXISTS (
            SELECT 1
            FROM pg_constraint c
            JOIN pg_class t
              ON t.oid = c.conrelid
            JOIN pg_namespace n
              ON n.oid = t.relnamespace
            WHERE n.nspname = 'dw'
              AND t.relname = 'fact_remuneraciones'
              AND c.conname = esperadas.nombre
              AND c.contype = 'f'
        )
    ) faltantes_fk;

    IF faltantes IS NOT NULL THEN
        RAISE EXCEPTION
            'TEST FAIL: faltan FK en FACT_REMUNERACIONES: %',
            faltantes;
    END IF;

    -- ========================================================
    -- 5. CHECKS CRÍTICOS
    -- ========================================================

    SELECT string_agg(nombre, ', ')
    INTO faltantes
    FROM (
        SELECT nombre
        FROM (
            VALUES
                ('ck_fact_remuneraciones_periodo'),
                ('ck_fact_remuneraciones_sueldo_base'),
                ('ck_fact_remuneraciones_horas_extras'),
                ('ck_fact_remuneraciones_sueldo_imponible'),
                ('ck_fact_remuneraciones_sueldo_liquido'),
                ('ck_fact_remuneraciones_costo_empresa'),
                ('ck_fact_remuneraciones_total_haberes'),
                ('ck_fact_remuneraciones_total_descuentos'),
                ('ck_fact_remuneraciones_total_aportes'),
                ('ck_fact_remuneraciones_cantidad_registros')
        ) AS esperadas(nombre)
        WHERE NOT EXISTS (
            SELECT 1
            FROM pg_constraint c
            JOIN pg_class t
              ON t.oid = c.conrelid
            JOIN pg_namespace n
              ON n.oid = t.relnamespace
            WHERE n.nspname = 'dw'
              AND t.relname = 'fact_remuneraciones'
              AND c.conname = esperadas.nombre
              AND c.contype = 'c'
        )
    ) faltantes_ck;

    IF faltantes IS NOT NULL THEN
        RAISE EXCEPTION
            'TEST FAIL: faltan CHECK en FACT_REMUNERACIONES: %',
            faltantes;
    END IF;

    -- ========================================================
    -- 6. ÍNDICES COMPLEMENTARIOS
    -- ========================================================

    SELECT string_agg(nombre, ', ')
    INTO faltantes
    FROM (
        SELECT nombre
        FROM (
            VALUES
                ('idx_fact_remuneraciones_fecha'),
                ('idx_fact_remuneraciones_contrato'),
                ('idx_fact_remuneraciones_area'),
                ('idx_fact_remuneraciones_cargo'),
                ('idx_fact_remuneraciones_centro_costo')
        ) AS esperados(nombre)
        WHERE NOT EXISTS (
            SELECT 1
            FROM pg_indexes i
            WHERE i.schemaname = 'dw'
              AND i.tablename = 'fact_remuneraciones'
              AND i.indexname = esperados.nombre
        )
    ) faltantes_idx;

    IF faltantes IS NOT NULL THEN
        RAISE EXCEPTION
            'TEST FAIL: faltan índices en FACT_REMUNERACIONES: %',
            faltantes;
    END IF;

    RAISE NOTICE
        'TEST OK: FACT_REMUNERACIONES, restricciones e índices verificados.';
END
$$;