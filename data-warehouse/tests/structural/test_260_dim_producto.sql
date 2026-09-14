-- ============================================================
-- Industrias ABC - Data Warehouse
-- Test: test_260_dim_producto.sql
-- Objetivo:
--   Verificar la estructura física de DIM_PRODUCTO.
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
          AND table_name = 'dim_producto'
          AND table_type = 'BASE TABLE'
    ) THEN
        RAISE EXCEPTION
            'TEST FAIL: no existe dw.dim_producto';
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
                ('producto_key'),
                ('codigo_producto'),
                ('nombre_producto'),
                ('categoria'),
                ('unidad_medida')
        ) AS esperadas(nombre)
        WHERE NOT EXISTS (
            SELECT 1
            FROM information_schema.columns c
            WHERE c.table_schema = 'dw'
              AND c.table_name = 'dim_producto'
              AND c.column_name = esperadas.nombre
        )
    ) columnas_faltantes;

    IF faltantes IS NOT NULL THEN
        RAISE EXCEPTION
            'TEST FAIL: faltan columnas en DIM_PRODUCTO: %',
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
          AND t.relname = 'dim_producto'
          AND c.conname = 'pk_dim_producto'
          AND c.contype = 'p'
    ) THEN
        RAISE EXCEPTION
            'TEST FAIL: falta pk_dim_producto';
    END IF;

    -- ========================================================
    -- 4. UNIQUE DE BUSINESS KEY
    -- ========================================================

    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint c
        JOIN pg_class t
          ON t.oid = c.conrelid
        JOIN pg_namespace n
          ON n.oid = t.relnamespace
        WHERE n.nspname = 'dw'
          AND t.relname = 'dim_producto'
          AND c.conname = 'uq_dim_producto_codigo'
          AND c.contype = 'u'
    ) THEN
        RAISE EXCEPTION
            'TEST FAIL: falta uq_dim_producto_codigo';
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
                ('ck_dim_producto_key'),
                ('ck_dim_producto_desconocido')
        ) AS esperadas(nombre)
        WHERE NOT EXISTS (
            SELECT 1
            FROM pg_constraint c
            JOIN pg_class t
              ON t.oid = c.conrelid
            JOIN pg_namespace n
              ON n.oid = t.relnamespace
            WHERE n.nspname = 'dw'
              AND t.relname = 'dim_producto'
              AND c.conname = esperadas.nombre
              AND c.contype = 'c'
        )
    ) checks_faltantes;

    IF faltantes IS NOT NULL THEN
        RAISE EXCEPTION
            'TEST FAIL: faltan CHECK en DIM_PRODUCTO: %',
            faltantes;
    END IF;

    -- ========================================================
    -- 6. MIEMBRO DESCONOCIDO
    -- ========================================================

    IF NOT EXISTS (
        SELECT 1
        FROM dw.dim_producto
        WHERE producto_key = 0
          AND codigo_producto = 'DESCONOCIDO'
    ) THEN
        RAISE EXCEPTION
            'TEST FAIL: falta o es inconsistente el miembro desconocido de DIM_PRODUCTO';
    END IF;

    -- ========================================================
    -- 7. ESTADO DEL MIEMBRO DESCONOCIDO
    -- ========================================================

    IF EXISTS (
        SELECT 1
        FROM dw.dim_producto
        WHERE producto_key = 0
          AND (
              nombre_producto <> 'No informado'
              OR categoria <> 'DESCONOCIDO'
              OR unidad_medida <> 'DESCONOCIDO'
          )
    ) THEN
        RAISE EXCEPTION
            'TEST FAIL: los atributos del miembro desconocido de DIM_PRODUCTO son inconsistentes';
    END IF;

    RAISE NOTICE
        'TEST OK: DIM_PRODUCTO, columnas, restricciones y miembro desconocido verificados.';

END
$$;