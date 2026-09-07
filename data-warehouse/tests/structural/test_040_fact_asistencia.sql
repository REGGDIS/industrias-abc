-- ============================================================
-- Industrias ABC - Data Warehouse
-- Test: test_040_fact_asistencia.sql
-- Objetivo:
--   Verificar la estructura física de FACT_ASISTENCIA.
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
          AND table_name = 'fact_asistencia'
    ) THEN
        RAISE EXCEPTION
            'TEST FAIL: no existe dw.fact_asistencia';
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
          AND t.relname = 'fact_asistencia'
          AND c.conname = 'pk_fact_asistencia'
          AND c.contype = 'p'
    ) THEN
        RAISE EXCEPTION
            'TEST FAIL: falta pk_fact_asistencia';
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
          AND t.relname = 'fact_asistencia'
          AND c.conname = 'uq_fact_asistencia_empleado_fecha'
          AND c.contype = 'u'
    ) THEN
        RAISE EXCEPTION
            'TEST FAIL: falta uq_fact_asistencia_empleado_fecha';
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
                ('fk_fact_asistencia_fecha'),
                ('fk_fact_asistencia_empleado'),
                ('fk_fact_asistencia_area'),
                ('fk_fact_asistencia_cargo'),
                ('fk_fact_asistencia_centro_costo'),
                ('fk_fact_asistencia_turno')
        ) AS esperadas(nombre)
        WHERE NOT EXISTS (
            SELECT 1
            FROM pg_constraint c
            JOIN pg_class t
              ON t.oid = c.conrelid
            JOIN pg_namespace n
              ON n.oid = t.relnamespace
            WHERE n.nspname = 'dw'
              AND t.relname = 'fact_asistencia'
              AND c.conname = esperadas.nombre
              AND c.contype = 'f'
        )
    ) faltantes_fk;

    IF faltantes IS NOT NULL THEN
        RAISE EXCEPTION
            'TEST FAIL: faltan FK en FACT_ASISTENCIA: %',
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
                ('ck_fact_asistencia_estado'),
                ('ck_fact_asistencia_horas_trabajadas'),
                ('ck_fact_asistencia_horas_normales'),
                ('ck_fact_asistencia_horas_extras'),
                ('ck_fact_asistencia_horas_extras_vs_trabajadas'),
                ('ck_fact_asistencia_minutos_atraso'),
                ('ck_fact_asistencia_dias_trabajados'),
                ('ck_fact_asistencia_dias_ausentes'),
                ('ck_fact_asistencia_dias_coherentes'),
                ('ck_fact_asistencia_cantidad_registros'),
                ('ck_fact_asistencia_estado_dias'),
                ('ck_fact_asistencia_ausencia_coherente')
        ) AS esperadas(nombre)
        WHERE NOT EXISTS (
            SELECT 1
            FROM pg_constraint c
            JOIN pg_class t
              ON t.oid = c.conrelid
            JOIN pg_namespace n
              ON n.oid = t.relnamespace
            WHERE n.nspname = 'dw'
              AND t.relname = 'fact_asistencia'
              AND c.conname = esperadas.nombre
              AND c.contype = 'c'
        )
    ) faltantes_ck;

    IF faltantes IS NOT NULL THEN
        RAISE EXCEPTION
            'TEST FAIL: faltan CHECK en FACT_ASISTENCIA: %',
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
                ('idx_fact_asistencia_fecha'),
                ('idx_fact_asistencia_turno'),
                ('idx_fact_asistencia_area'),
                ('idx_fact_asistencia_centro_costo')
        ) AS esperados(nombre)
        WHERE NOT EXISTS (
            SELECT 1
            FROM pg_indexes i
            WHERE i.schemaname = 'dw'
              AND i.tablename = 'fact_asistencia'
              AND i.indexname = esperados.nombre
        )
    ) faltantes_idx;

    IF faltantes IS NOT NULL THEN
        RAISE EXCEPTION
            'TEST FAIL: faltan índices en FACT_ASISTENCIA: %',
            faltantes;
    END IF;

    RAISE NOTICE
        'TEST OK: FACT_ASISTENCIA, restricciones e índices verificados.';
END
$$;