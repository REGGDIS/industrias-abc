-- ============================================================
-- Industrias ABC - Data Warehouse
-- Test: test_270_fact_produccion.sql
-- Objetivo:
--   Verificar la estructura física de FACT_PRODUCCION.
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
          AND table_name = 'fact_produccion'
          AND table_type = 'BASE TABLE'
    ) THEN
        RAISE EXCEPTION
            'TEST FAIL: no existe dw.fact_produccion';
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
                ('produccion_fact_key'),
                ('fecha_inicio_key'),
                ('fecha_termino_key'),
                ('producto_key'),
                ('centro_costo_key'),
                ('area_key'),
                ('numero_orden'),
                ('cantidad_planificada'),
                ('cantidad_producida'),
                ('cantidad_rechazada'),
                ('estado')
        ) AS esperadas(nombre)
        WHERE NOT EXISTS (
            SELECT 1
            FROM information_schema.columns c
            WHERE c.table_schema = 'dw'
              AND c.table_name = 'fact_produccion'
              AND c.column_name = esperadas.nombre
        )
    ) columnas_faltantes;

    IF faltantes IS NOT NULL THEN
        RAISE EXCEPTION
            'TEST FAIL: faltan columnas en FACT_PRODUCCION: %',
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
          AND t.relname = 'fact_produccion'
          AND c.conname = 'pk_fact_produccion'
          AND c.contype = 'p'
    ) THEN
        RAISE EXCEPTION
            'TEST FAIL: falta pk_fact_produccion';
    END IF;

    -- ========================================================
    -- 4. UNIQUE DEL GRANO
    -- ========================================================

    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint c
        JOIN pg_class t
          ON t.oid = c.conrelid
        JOIN pg_namespace n
          ON n.oid = t.relnamespace
        WHERE n.nspname = 'dw'
          AND t.relname = 'fact_produccion'
          AND c.conname = 'uq_fact_produccion_numero_orden'
          AND c.contype = 'u'
    ) THEN
        RAISE EXCEPTION
            'TEST FAIL: falta uq_fact_produccion_numero_orden';
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
                ('fk_fact_produccion_fecha_inicio'),
                ('fk_fact_produccion_fecha_termino'),
                ('fk_fact_produccion_producto'),
                ('fk_fact_produccion_centro_costo'),
                ('fk_fact_produccion_area')
        ) AS esperadas(nombre)
        WHERE NOT EXISTS (
            SELECT 1
            FROM pg_constraint c
            JOIN pg_class t
              ON t.oid = c.conrelid
            JOIN pg_namespace n
              ON n.oid = t.relnamespace
            WHERE n.nspname = 'dw'
              AND t.relname = 'fact_produccion'
              AND c.conname = esperadas.nombre
              AND c.contype = 'f'
        )
    ) fk_faltantes;

    IF faltantes IS NOT NULL THEN
        RAISE EXCEPTION
            'TEST FAIL: faltan FK en FACT_PRODUCCION: %',
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
                ('ck_fact_produccion_key'),
                ('ck_fact_produccion_cantidad_planificada'),
                ('ck_fact_produccion_cantidad_producida'),
                ('ck_fact_produccion_cantidad_rechazada'),
                ('ck_fact_produccion_rechazada_no_supera_producida')
        ) AS esperadas(nombre)
        WHERE NOT EXISTS (
            SELECT 1
            FROM pg_constraint c
            JOIN pg_class t
              ON t.oid = c.conrelid
            JOIN pg_namespace n
              ON n.oid = t.relnamespace
            WHERE n.nspname = 'dw'
              AND t.relname = 'fact_produccion'
              AND c.conname = esperadas.nombre
              AND c.contype = 'c'
        )
    ) checks_faltantes;

    IF faltantes IS NOT NULL THEN
        RAISE EXCEPTION
            'TEST FAIL: faltan CHECK en FACT_PRODUCCION: %',
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
                ('idx_fact_produccion_fecha_inicio'),
                ('idx_fact_produccion_fecha_termino'),
                ('idx_fact_produccion_producto'),
                ('idx_fact_produccion_centro_costo'),
                ('idx_fact_produccion_area')
        ) AS esperados(nombre)
        WHERE NOT EXISTS (
            SELECT 1
            FROM pg_indexes i
            WHERE i.schemaname = 'dw'
              AND i.tablename = 'fact_produccion'
              AND i.indexname = esperados.nombre
        )
    ) indices_faltantes;

    IF faltantes IS NOT NULL THEN
        RAISE EXCEPTION
            'TEST FAIL: faltan índices en FACT_PRODUCCION: %',
            faltantes;
    END IF;

    RAISE NOTICE
        'TEST OK: FACT_PRODUCCION, columnas, restricciones e índices verificados.';

END
$$;