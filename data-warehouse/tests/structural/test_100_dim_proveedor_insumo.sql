-- ============================================================
-- Industrias ABC - Data Warehouse
-- Test estructural: test_100_dim_proveedor_insumo.sql
-- Objetivo:
--   Validar la estructura física de DIM_PROVEEDOR y DIM_INSUMO:
--     - Existencia de tablas y columnas de business key.
--     - PRIMARY KEY, UNIQUE (business key), CHECK (>=0, desconocido).
--     - Presencia del miembro desconocido (key = 0).
--     - Reglas de dominio operativas (rechazos esperados).
--
-- Mecanismo:
--   Bloques DO anónimos que consultan el catálogo (pg_constraint,
--   information_schema) y lanzan RAISE EXCEPTION si falta estructura.
--   No modifica datos de negocio (los inserts de prueba se revierten).
--
-- Uso:
--   psql -v ON_ERROR_STOP=1 -f test_100_dim_proveedor_insumo.sql
-- ============================================================

\set ON_ERROR_STOP on
\echo '== TEST 100: DIM_PROVEEDOR / DIM_INSUMO =='

-- ------------------------------------------------------------
-- 1) Existencia de tablas
-- ------------------------------------------------------------
DO $$
BEGIN
    IF to_regclass('dw.dim_proveedor') IS NULL THEN
        RAISE EXCEPTION 'FALLO: no existe la tabla dw.dim_proveedor';
    END IF;
    IF to_regclass('dw.dim_insumo') IS NULL THEN
        RAISE EXCEPTION 'FALLO: no existe la tabla dw.dim_insumo';
    END IF;
    RAISE NOTICE 'OK: existen dw.dim_proveedor y dw.dim_insumo';
END $$;

-- ------------------------------------------------------------
-- 2) Restricciones esperadas por nombre
-- ------------------------------------------------------------
DO $$
DECLARE
    v_faltantes TEXT := '';
    v_nombre    TEXT;
    v_esperadas TEXT[] := ARRAY[
        'pk_dim_proveedor',
        'uq_dim_proveedor_rut',
        'ck_dim_proveedor_key',
        'ck_dim_proveedor_desconocido',
        'pk_dim_insumo',
        'uq_dim_insumo_codigo',
        'ck_dim_insumo_key',
        'ck_dim_insumo_stock_minimo',
        'ck_dim_insumo_desconocido'
    ];
BEGIN
    FOREACH v_nombre IN ARRAY v_esperadas LOOP
        IF NOT EXISTS (
            SELECT 1 FROM pg_constraint WHERE conname = v_nombre
        ) THEN
            v_faltantes := v_faltantes || ' ' || v_nombre;
        END IF;
    END LOOP;

    IF length(v_faltantes) > 0 THEN
        RAISE EXCEPTION 'FALLO: faltan restricciones:%', v_faltantes;
    END IF;
    RAISE NOTICE 'OK: todas las restricciones esperadas existen';
END $$;

-- ------------------------------------------------------------
-- 3) Miembro desconocido (key = 0) presente en ambas dims
-- ------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM dw.dim_proveedor
        WHERE proveedor_key = 0 AND rut_proveedor_normalizado = 'DESCONOCIDO'
    ) THEN
        RAISE EXCEPTION 'FALLO: DIM_PROVEEDOR sin miembro desconocido (key=0)';
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM dw.dim_insumo
        WHERE insumo_key = 0 AND codigo_insumo = 'DESCONOCIDO'
    ) THEN
        RAISE EXCEPTION 'FALLO: DIM_INSUMO sin miembro desconocido (key=0)';
    END IF;
    RAISE NOTICE 'OK: miembro desconocido presente en ambas dimensiones';
END $$;

-- ------------------------------------------------------------
-- 4) Reglas de dominio operativas (rechazos esperados)
--    Se prueban dentro de sub-transacciones que se revierten.
-- ------------------------------------------------------------

-- 4a) DIM_PROVEEDOR: un registro real NO puede usar RUT 'DESCONOCIDO'
DO $$
BEGIN
    BEGIN
        INSERT INTO dw.dim_proveedor (rut_proveedor_normalizado, razon_social)
        VALUES ('DESCONOCIDO', 'Intruso');
        RAISE EXCEPTION 'FALLO: DIM_PROVEEDOR aceptó RUT=DESCONOCIDO en registro real';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'OK: DIM_PROVEEDOR rechaza RUT=DESCONOCIDO en registro real';
    END;
END $$;

-- 4b) DIM_INSUMO: stock_minimo negativo rechazado
DO $$
BEGIN
    BEGIN
        INSERT INTO dw.dim_insumo (codigo_insumo, nombre_insumo, unidad_medida, stock_minimo)
        VALUES ('TEST-NEG', 'Insumo prueba', 'UNIDAD', -5);
        RAISE EXCEPTION 'FALLO: DIM_INSUMO aceptó stock_minimo negativo';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'OK: DIM_INSUMO rechaza stock_minimo negativo';
    END;
END $$;

-- 4c) DIM_INSUMO: unidad_medida es obligatoria para un insumo real
DO $$
BEGIN
    BEGIN
        INSERT INTO dw.dim_insumo (codigo_insumo, nombre_insumo, unidad_medida)
        VALUES ('TEST-SIN-UM', 'Insumo sin unidad', NULL);
        RAISE EXCEPTION 'FALLO: DIM_INSUMO aceptó unidad_medida NULL';
    EXCEPTION WHEN not_null_violation THEN
        RAISE NOTICE 'OK: DIM_INSUMO rechaza unidad_medida NULL';
    END;
END $$;

\echo '== TEST 100: TODOS LOS CHEQUEOS OK =='
