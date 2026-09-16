-- ============================================================
-- Industrias ABC - Data Warehouse
-- Test estructural: test_110_fact_compras.sql
-- Objetivo:
--   Validar la estructura física de FACT_COMPRAS:
--     - Existencia de tabla.
--     - PRIMARY KEY, UNIQUE de grano, 6 FOREIGN KEY, CHECKs de dominio.
--     - Integridad referencial operativa (rechazos esperados).
--     - Unicidad de grano (numero_oc, insumo_key).
--     - Índices de las FK.
--
-- Mecanismo:
--   Bloques DO anónimos + inserts de prueba revertidos.
--   Requiere DW-CORE + DIM_PROVEEDOR + DIM_INSUMO instalados
--   (usa los miembros desconocidos key=0 como referencia válida).
--
-- Uso:
--   psql -v ON_ERROR_STOP=1 -f test_110_fact_compras.sql
-- ============================================================

\set ON_ERROR_STOP on
\echo '== TEST 110: FACT_COMPRAS =='

-- ------------------------------------------------------------
-- 1) Existencia de tabla
-- ------------------------------------------------------------
DO $$
BEGIN
    IF to_regclass('dw.fact_compras') IS NULL THEN
        RAISE EXCEPTION 'FALLO: no existe la tabla dw.fact_compras';
    END IF;
    RAISE NOTICE 'OK: existe dw.fact_compras';
END $$;

-- ------------------------------------------------------------
-- 2) Conteo de restricciones por tipo
--    Esperado: PK=1, UNIQUE=1, FK=6, CHECK>=11
-- ------------------------------------------------------------
DO $$
DECLARE
    v_pk INT; v_uq INT; v_fk INT; v_ck INT;
    v_rel oid := 'dw.fact_compras'::regclass;
BEGIN
    SELECT count(*) INTO v_pk FROM pg_constraint WHERE conrelid = v_rel AND contype = 'p';
    SELECT count(*) INTO v_uq FROM pg_constraint WHERE conrelid = v_rel AND contype = 'u';
    SELECT count(*) INTO v_fk FROM pg_constraint WHERE conrelid = v_rel AND contype = 'f';
    SELECT count(*) INTO v_ck FROM pg_constraint WHERE conrelid = v_rel AND contype = 'c';

    IF v_pk <> 1 THEN RAISE EXCEPTION 'FALLO: se esperaba 1 PK, hay %', v_pk; END IF;
    IF v_uq <> 1 THEN RAISE EXCEPTION 'FALLO: se esperaba 1 UNIQUE, hay %', v_uq; END IF;
    IF v_fk <> 6 THEN RAISE EXCEPTION 'FALLO: se esperaban 6 FK, hay %', v_fk; END IF;
    IF v_ck < 11 THEN RAISE EXCEPTION 'FALLO: se esperaban >=11 CHECK, hay %', v_ck; END IF;

    RAISE NOTICE 'OK: restricciones PK=% UNIQUE=% FK=% CHECK=%', v_pk, v_uq, v_fk, v_ck;
END $$;

-- ------------------------------------------------------------
-- 3) FK esperadas por nombre
-- ------------------------------------------------------------
DO $$
DECLARE
    v_faltantes TEXT := '';
    v_nombre    TEXT;
    v_esperadas TEXT[] := ARRAY[
        'fk_fact_compras_fecha_emision',
        'fk_fact_compras_fecha_requerida',
        'fk_fact_compras_proveedor',
        'fk_fact_compras_insumo',
        'fk_fact_compras_centro_costo',
        'fk_fact_compras_area'
    ];
BEGIN
    FOREACH v_nombre IN ARRAY v_esperadas LOOP
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = v_nombre) THEN
            v_faltantes := v_faltantes || ' ' || v_nombre;
        END IF;
    END LOOP;
    IF length(v_faltantes) > 0 THEN
        RAISE EXCEPTION 'FALLO: faltan FK:%', v_faltantes;
    END IF;
    RAISE NOTICE 'OK: las 6 FK esperadas existen';
END $$;

-- ------------------------------------------------------------
-- 4) Índices de las FK esperados por nombre
-- ------------------------------------------------------------
DO $$
DECLARE
    v_faltantes TEXT := '';
    v_nombre    TEXT;
    v_esperados TEXT[] := ARRAY[
        'idx_fact_compras_fecha_emision',
        'idx_fact_compras_fecha_requerida',
        'idx_fact_compras_proveedor',
        'idx_fact_compras_insumo',
        'idx_fact_compras_centro_costo',
        'idx_fact_compras_area'
    ];
BEGIN
    FOREACH v_nombre IN ARRAY v_esperados LOOP
        IF NOT EXISTS (
            SELECT 1 FROM pg_indexes
            WHERE schemaname = 'dw' AND indexname = v_nombre
        ) THEN
            v_faltantes := v_faltantes || ' ' || v_nombre;
        END IF;
    END LOOP;
    IF length(v_faltantes) > 0 THEN
        RAISE EXCEPTION 'FALLO: faltan indices:%', v_faltantes;
    END IF;
    RAISE NOTICE 'OK: los 6 indices de FK existen';
END $$;

-- ------------------------------------------------------------
-- 5) Integridad operativa (rechazos esperados, revertidos)
-- ------------------------------------------------------------

-- 5a) Fila válida contra miembros desconocidos (key=0) debe INSERTAR
DO $$
DECLARE
    v_fecha INT;
BEGIN
    -- toma cualquier fecha_key real de la dimensión fecha
    SELECT fecha_key INTO v_fecha FROM dw.dim_fecha WHERE fecha_key > 0 LIMIT 1;
    IF v_fecha IS NULL THEN
        RAISE EXCEPTION 'FALLO: DIM_FECHA vacía, no se puede probar FACT';
    END IF;

    BEGIN
        INSERT INTO dw.fact_compras (
            fecha_emision_key, fecha_requerida_key, proveedor_key, insumo_key,
            centro_costo_key, area_key, numero_oc, moneda_origen,
            cantidad, precio_unitario, subtotal, impuesto, total
        ) VALUES (
            v_fecha, 0, 0, 0, 0, 0, 'OC-TEST-110', 'CLP',
            10, 100, 1000, 190, 1190
        );
        RAISE NOTICE 'OK: FACT acepta fila válida referenciando miembros key=0';
        -- limpiamos la fila de prueba
        DELETE FROM dw.fact_compras WHERE numero_oc = 'OC-TEST-110';
    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'FALLO: FACT rechazó una fila válida: %', SQLERRM;
    END;
END $$;

-- 5b) FK a proveedor inexistente debe RECHAZAR
DO $$
DECLARE
    v_fecha INT;
BEGIN
    SELECT fecha_key INTO v_fecha FROM dw.dim_fecha WHERE fecha_key > 0 LIMIT 1;
    BEGIN
        INSERT INTO dw.fact_compras (
            fecha_emision_key, fecha_requerida_key, proveedor_key, insumo_key,
            centro_costo_key, area_key, numero_oc, moneda_origen
        ) VALUES (
            v_fecha, 0, 999999, 0, 0, 0, 'OC-TEST-FK', 'CLP'
        );
        RAISE EXCEPTION 'FALLO: FACT aceptó proveedor_key inexistente';
    EXCEPTION WHEN foreign_key_violation THEN
        RAISE NOTICE 'OK: FACT rechaza FK a proveedor inexistente';
    END;
END $$;

-- 5c) Moneda inválida debe RECHAZAR
DO $$
DECLARE
    v_fecha INT;
BEGIN
    SELECT fecha_key INTO v_fecha FROM dw.dim_fecha WHERE fecha_key > 0 LIMIT 1;
    BEGIN
        INSERT INTO dw.fact_compras (
            fecha_emision_key, fecha_requerida_key, proveedor_key, insumo_key,
            centro_costo_key, area_key, numero_oc, moneda_origen
        ) VALUES (
            v_fecha, 0, 0, 0, 0, 0, 'OC-TEST-MON', 'ARS'
        );
        RAISE EXCEPTION 'FALLO: FACT aceptó moneda inválida (ARS)';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'OK: FACT rechaza moneda no permitida';
    END;
END $$;

-- 5d) Unicidad de grano (numero_oc, insumo_key) debe RECHAZAR duplicado
DO $$
DECLARE
    v_fecha INT;
BEGIN
    SELECT fecha_key INTO v_fecha FROM dw.dim_fecha WHERE fecha_key > 0 LIMIT 1;
    BEGIN
        INSERT INTO dw.fact_compras (
            fecha_emision_key, fecha_requerida_key, proveedor_key, insumo_key,
            centro_costo_key, area_key, numero_oc, moneda_origen
        ) VALUES
            (v_fecha, 0, 0, 0, 0, 0, 'OC-DUP', 'CLP'),
            (v_fecha, 0, 0, 0, 0, 0, 'OC-DUP', 'CLP');
        RAISE EXCEPTION 'FALLO: FACT aceptó grano duplicado (numero_oc, insumo_key)';
    EXCEPTION WHEN unique_violation THEN
        RAISE NOTICE 'OK: FACT rechaza grano duplicado (numero_oc, insumo_key)';
    END;
    -- por si la primera fila alcanzó a insertarse en algún motor
    DELETE FROM dw.fact_compras WHERE numero_oc = 'OC-DUP';
END $$;

\echo '== TEST 110: TODOS LOS CHEQUEOS OK =='
