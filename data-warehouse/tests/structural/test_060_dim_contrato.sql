-- ============================================================
-- Industrias ABC - Data Warehouse
-- Test: test_060_dim_contrato.sql
-- Objetivo:
--   Verificar la estructura física de DIM_CONTRATO.
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
          AND table_name = 'dim_contrato'
    ) THEN
        RAISE EXCEPTION
            'TEST FAIL: no existe dw.dim_contrato';
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
          AND t.relname = 'dim_contrato'
          AND c.conname = 'pk_dim_contrato'
          AND c.contype = 'p'
    ) THEN
        RAISE EXCEPTION
            'TEST FAIL: falta pk_dim_contrato';
    END IF;

    -- ========================================================
    -- 3. BUSINESS KEY UNIQUE
    -- ========================================================

    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint c
        JOIN pg_class t
          ON t.oid = c.conrelid
        JOIN pg_namespace n
          ON n.oid = t.relnamespace
        WHERE n.nspname = 'dw'
          AND t.relname = 'dim_contrato'
          AND c.conname = 'uq_dim_contrato_numero'
          AND c.contype = 'u'
    ) THEN
        RAISE EXCEPTION
            'TEST FAIL: falta uq_dim_contrato_numero';
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
                ('fk_dim_contrato_empleado'),
                ('fk_dim_contrato_cargo')
        ) AS esperadas(nombre)
        WHERE NOT EXISTS (
            SELECT 1
            FROM pg_constraint c
            JOIN pg_class t
              ON t.oid = c.conrelid
            JOIN pg_namespace n
              ON n.oid = t.relnamespace
            WHERE n.nspname = 'dw'
              AND t.relname = 'dim_contrato'
              AND c.conname = esperadas.nombre
              AND c.contype = 'f'
        )
    ) faltantes_fk;

    IF faltantes IS NOT NULL THEN
        RAISE EXCEPTION
            'TEST FAIL: faltan FK en DIM_CONTRATO: %',
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
                ('ck_dim_contrato_key'),
                ('ck_dim_contrato_desconocido'),
                ('ck_dim_contrato_tipo'),
                ('ck_dim_contrato_estado'),
                ('ck_dim_contrato_sueldo_base'),
                ('ck_dim_contrato_fechas'),
                ('ck_dim_contrato_fecha_termino_tipo')
        ) AS esperadas(nombre)
        WHERE NOT EXISTS (
            SELECT 1
            FROM pg_constraint c
            JOIN pg_class t
              ON t.oid = c.conrelid
            JOIN pg_namespace n
              ON n.oid = t.relnamespace
            WHERE n.nspname = 'dw'
              AND t.relname = 'dim_contrato'
              AND c.conname = esperadas.nombre
              AND c.contype = 'c'
        )
    ) faltantes_ck;

    IF faltantes IS NOT NULL THEN
        RAISE EXCEPTION
            'TEST FAIL: faltan CHECK en DIM_CONTRATO: %',
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
                ('idx_dim_contrato_empleado'),
                ('idx_dim_contrato_cargo'),
                ('idx_dim_contrato_estado'),
                ('idx_dim_contrato_vigencia')
        ) AS esperados(nombre)
        WHERE NOT EXISTS (
            SELECT 1
            FROM pg_indexes i
            WHERE i.schemaname = 'dw'
              AND i.tablename = 'dim_contrato'
              AND i.indexname = esperados.nombre
        )
    ) faltantes_idx;

    IF faltantes IS NOT NULL THEN
        RAISE EXCEPTION
            'TEST FAIL: faltan índices en DIM_CONTRATO: %',
            faltantes;
    END IF;

    -- ========================================================
    -- 7. MIEMBRO DESCONOCIDO
    -- ========================================================

    IF NOT EXISTS (
        SELECT 1
        FROM dw.dim_contrato
        WHERE contrato_key = 0
          AND numero_contrato = 'DESCONOCIDO'
          AND empleado_key = 0
          AND cargo_key = 0
    ) THEN
        RAISE EXCEPTION
            'TEST FAIL: miembro desconocido de DIM_CONTRATO inválido o inexistente';
    END IF;

    RAISE NOTICE
        'TEST OK: DIM_CONTRATO, restricciones, índices y miembro desconocido verificados.';
END
$$;