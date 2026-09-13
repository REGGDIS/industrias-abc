-- ============================================================
-- Industrias ABC - Data Warehouse
-- Test: test_280_fact_consumo_insumo.sql
-- Objetivo:
--   Verificar la estructura física de FACT_CONSUMO_INSUMO.
-- Motor:
--   PostgreSQL 16
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
          AND table_name = 'fact_consumo_insumo'
          AND table_type = 'BASE TABLE'
    ) THEN
        RAISE EXCEPTION
            'TEST FAIL: no existe dw.fact_consumo_insumo';
    END IF;

    -- ========================================================
    -- 2. COLUMNAS OBLIGATORIAS
    -- ========================================================

    SELECT string_agg(nombre, ', ')
    INTO faltantes
    FROM (
        SELECT nombre
        FROM (
            VALUES
                ('consumo_fact_key'),
                ('fecha_consumo_key'),
                ('producto_key'),
                ('insumo_key'),
                ('centro_costo_key'),
                ('area_key'),
                ('numero_orden'),
                ('consumo_id'),
                ('cantidad_planificada'),
                ('cantidad_consumida'),
                ('desviacion')
        ) AS esperadas(nombre)
        WHERE NOT EXISTS (
            SELECT 1
            FROM information_schema.columns c
            WHERE c.table_schema = 'dw'
              AND c.table_name = 'fact_consumo_insumo'
              AND c.column_name = esperadas.nombre
        )
    ) columnas_faltantes;

    IF faltantes IS NOT NULL THEN
        RAISE EXCEPTION
            'TEST FAIL: faltan columnas en FACT_CONSUMO_INSUMO: %',
            faltantes;
    END IF;

    -- ========================================================
    -- 3. PRIMARY KEY
    -- ========================================================

    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint c
        JOIN pg_class t
          ON t.oid = c.conrelid
        JOIN pg_namespace n
          ON n.oid = t.relnamespace
        WHERE n.nspname = 'dw'
          AND t.relname = 'fact_consumo_insumo'
          AND c.conname = 'pk_fact_consumo_insumo'
          AND c.contype = 'p'
    ) THEN
        RAISE EXCEPTION
            'TEST FAIL: falta pk_fact_consumo_insumo';
    END IF;

    -- ========================================================
    -- 4. UNIQUE DE TRAZABILIDAD
    -- ========================================================

    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint c
        JOIN pg_class t
          ON t.oid = c.conrelid
        JOIN pg_namespace n
          ON n.oid = t.relnamespace
        WHERE n.nspname = 'dw'
          AND t.relname = 'fact_consumo_insumo'
          AND c.conname = 'uq_fact_consumo_insumo_origen'
          AND c.contype = 'u'
    ) THEN
        RAISE EXCEPTION
            'TEST FAIL: falta uq_fact_consumo_insumo_origen';
    END IF;

    -- ========================================================
    -- 5. FOREIGN KEYS
    -- ========================================================

    SELECT string_agg(nombre, ', ')
    INTO faltantes
    FROM (
        SELECT nombre
        FROM (
            VALUES
                ('fk_fact_consumo_insumo_fecha'),
                ('fk_fact_consumo_insumo_producto'),
                ('fk_fact_consumo_insumo_insumo'),
                ('fk_fact_consumo_insumo_centro_costo'),
                ('fk_fact_consumo_insumo_area')
        ) AS esperadas(nombre)
        WHERE NOT EXISTS (
            SELECT 1
            FROM pg_constraint c
            JOIN pg_class t
              ON t.oid = c.conrelid
            JOIN pg_namespace n
              ON n.oid = t.relnamespace
            WHERE n.nspname = 'dw'
              AND t.relname = 'fact_consumo_insumo'
              AND c.conname = esperadas.nombre
              AND c.contype = 'f'
        )
    ) fk_faltantes;

    IF faltantes IS NOT NULL THEN
        RAISE EXCEPTION
            'TEST FAIL: faltan FK en FACT_CONSUMO_INSUMO: %',
            faltantes;
    END IF;

    -- ========================================================
    -- 6. CHECKS CRÍTICOS
    -- ========================================================

    SELECT string_agg(nombre, ', ')
    INTO faltantes
    FROM (
        SELECT nombre
        FROM (
            VALUES
                ('ck_fact_consumo_insumo_key'),
                ('ck_fact_consumo_insumo_cantidad_planificada'),
                ('ck_fact_consumo_insumo_cantidad_consumida'),
                ('ck_fact_consumo_insumo_consumida_no_supera_planificada')
        ) AS esperadas(nombre)
        WHERE NOT EXISTS (
            SELECT 1
            FROM pg_constraint c
            JOIN pg_class t
              ON t.oid = c.conrelid
            JOIN pg_namespace n
              ON n.oid = t.relnamespace
            WHERE n.nspname = 'dw'
              AND t.relname = 'fact_consumo_insumo'
              AND c.conname = esperadas.nombre
              AND c.contype = 'c'
        )
    ) checks_faltantes;

    IF faltantes IS NOT NULL THEN
        RAISE EXCEPTION
            'TEST FAIL: faltan CHECK en FACT_CONSUMO_INSUMO: %',
            faltantes;
    END IF;

    -- ========================================================
    -- 7. ÍNDICES COMPLEMENTARIOS
    -- ========================================================

    SELECT string_agg(nombre, ', ')
    INTO faltantes
    FROM (
        SELECT nombre
        FROM (
            VALUES
                ('idx_fact_consumo_insumo_fecha'),
                ('idx_fact_consumo_insumo_producto'),
                ('idx_fact_consumo_insumo_insumo'),
                ('idx_fact_consumo_insumo_centro_costo'),
                ('idx_fact_consumo_insumo_area')
        ) AS esperados(nombre)
        WHERE NOT EXISTS (
            SELECT 1
            FROM pg_indexes i
            WHERE i.schemaname = 'dw'
              AND i.tablename = 'fact_consumo_insumo'
              AND i.indexname = esperados.nombre
        )
    ) indices_faltantes;

    IF faltantes IS NOT NULL THEN
        RAISE EXCEPTION
            'TEST FAIL: faltan índices en FACT_CONSUMO_INSUMO: %',
            faltantes;
    END IF;

    RAISE NOTICE
        'TEST OK: FACT_CONSUMO_INSUMO, columnas, restricciones e índices verificados.';

END
$$;