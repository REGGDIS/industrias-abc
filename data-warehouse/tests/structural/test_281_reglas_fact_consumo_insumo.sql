-- ============================================================
-- Industrias ABC - Data Warehouse
-- Test: test_281_reglas_fact_consumo_insumo.sql
-- Objetivo:
--   Verificar funcionalmente las reglas críticas de
--   FACT_CONSUMO_INSUMO.
-- Motor:
--   PostgreSQL 16
-- Esquema:
--   dw
--
-- Estrategia:
--   Las pruebas se ejecutan dentro de una transacción y
--   terminan con ROLLBACK para no contaminar el DW.
-- ============================================================

\set ON_ERROR_STOP on

BEGIN;

-- ============================================================
-- 1. REGISTRO VÁLIDO
-- ============================================================

INSERT INTO dw.fact_consumo_insumo (
    consumo_fact_key,
    fecha_consumo_key,
    producto_key,
    insumo_key,
    centro_costo_key,
    area_key,
    numero_orden,
    consumo_id,
    insumo_codigo_origen,
    cantidad_planificada,
    cantidad_consumida
)
VALUES (
    920001,
    20260801,
    0,
    0,
    0,
    0,
    'TEST-OP-001',
    930001,
    'INS-1001',
    500.00,
    495.00
);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM dw.fact_consumo_insumo
        WHERE consumo_fact_key = 920001
          AND consumo_id = 930001
          AND numero_orden = 'TEST-OP-001'
          AND insumo_codigo_origen = 'INS-1001'
          AND cantidad_planificada = 500.00
          AND cantidad_consumida = 495.00
          AND desviacion = -5.00
    ) THEN
        RAISE EXCEPTION
            'TEST FAIL: no se insertó registro válido de FACT_CONSUMO_INSUMO';
    END IF;

    RAISE NOTICE
        'OK 1: registro válido y trazabilidad de insumo aceptados.';
END
$$;

-- ============================================================
-- 2. DUPLICIDAD DE CONSUMO_ID
-- ============================================================

DO $$
BEGIN
    BEGIN
        INSERT INTO dw.fact_consumo_insumo (
            consumo_fact_key,
            fecha_consumo_key,
            producto_key,
            insumo_key,
            centro_costo_key,
            area_key,
            numero_orden,
            consumo_id,
            insumo_codigo_origen,
            cantidad_planificada,
            cantidad_consumida
        )
        VALUES (
            920002,
            20260802,
            0,
            0,
            0,
            0,
            'TEST-OP-002',
            930001,
            'INS-1002',
            250.00,
            240.00
        );

        RAISE EXCEPTION
            'TEST FAIL: se permitió duplicar consumo_id';

    EXCEPTION
        WHEN unique_violation THEN
            RAISE NOTICE
                'OK 2: duplicidad de consumo_id rechazada.';
    END;
END
$$;

-- ============================================================
-- 3. CANTIDAD PLANIFICADA NEGATIVA
-- ============================================================

DO $$
BEGIN
    BEGIN
        INSERT INTO dw.fact_consumo_insumo (
            consumo_fact_key,
            fecha_consumo_key,
            producto_key,
            insumo_key,
            centro_costo_key,
            area_key,
            numero_orden,
            consumo_id,
            insumo_codigo_origen,
            cantidad_planificada,
            cantidad_consumida
        )
        VALUES (
            920003,
            20260803,
            0,
            0,
            0,
            0,
            'TEST-OP-003',
            930003,
            'INS-1003',
            -1.00,
            0.00
        );

        RAISE EXCEPTION
            'TEST FAIL: se permitió cantidad_planificada negativa';

    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE
                'OK 3: cantidad_planificada negativa rechazada.';
    END;
END
$$;

-- ============================================================
-- 4. CANTIDAD CONSUMIDA NEGATIVA
-- ============================================================

DO $$
BEGIN
    BEGIN
        INSERT INTO dw.fact_consumo_insumo (
            consumo_fact_key,
            fecha_consumo_key,
            producto_key,
            insumo_key,
            centro_costo_key,
            area_key,
            numero_orden,
            consumo_id,
            insumo_codigo_origen,
            cantidad_planificada,
            cantidad_consumida
        )
        VALUES (
            920004,
            20260804,
            0,
            0,
            0,
            0,
            'TEST-OP-004',
            930004,
            'INS-1004',
            100.00,
            -1.00
        );

        RAISE EXCEPTION
            'TEST FAIL: se permitió cantidad_consumida negativa';

    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE
                'OK 4: cantidad_consumida negativa rechazada.';
    END;
END
$$;

-- ============================================================
-- 5. SOBRECONSUMO VÁLIDO
-- ============================================================

INSERT INTO dw.fact_consumo_insumo (
    consumo_fact_key,
    fecha_consumo_key,
    producto_key,
    insumo_key,
    centro_costo_key,
    area_key,
    numero_orden,
    consumo_id,
    insumo_codigo_origen,
    cantidad_planificada,
    cantidad_consumida
)
VALUES (
    920005,
    20260805,
    0,
    0,
    0,
    0,
    'TEST-OP-005',
    930005,
    'INS-1005',
    100.00,
    110.00
);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM dw.fact_consumo_insumo
        WHERE consumo_id = 930005
          AND cantidad_planificada = 100.00
          AND cantidad_consumida = 110.00
          AND desviacion = 10.00
    ) THEN
        RAISE EXCEPTION
            'TEST FAIL: el sobreconsumo válido no quedó registrado correctamente';
    END IF;

    RAISE NOTICE
        'OK 5: sobreconsumo aceptado y desviación positiva calculada.';
END
$$;

-- ============================================================
-- 6. FK DE INSUMO INEXISTENTE
-- ============================================================

DO $$
BEGIN
    BEGIN
        INSERT INTO dw.fact_consumo_insumo (
            consumo_fact_key,
            fecha_consumo_key,
            producto_key,
            insumo_key,
            centro_costo_key,
            area_key,
            numero_orden,
            consumo_id,
            insumo_codigo_origen,
            cantidad_planificada,
            cantidad_consumida
        )
        VALUES (
            920006,
            20260806,
            0,
            999999,
            0,
            0,
            'TEST-OP-006',
            930006,
            'INS-NO-MAP',
            100.00,
            90.00
        );

        RAISE EXCEPTION
            'TEST FAIL: se permitió insumo_key inexistente';

    EXCEPTION
        WHEN foreign_key_violation THEN
            RAISE NOTICE
                'OK 6: insumo_key inexistente rechazado.';
    END;
END
$$;

-- ============================================================
-- 7. FK DE PRODUCTO INEXISTENTE
-- ============================================================

DO $$
BEGIN
    BEGIN
        INSERT INTO dw.fact_consumo_insumo (
            consumo_fact_key,
            fecha_consumo_key,
            producto_key,
            insumo_key,
            centro_costo_key,
            area_key,
            numero_orden,
            consumo_id,
            insumo_codigo_origen,
            cantidad_planificada,
            cantidad_consumida
        )
        VALUES (
            920007,
            20260807,
            999999,
            0,
            0,
            0,
            'TEST-OP-007',
            930007,
            'INS-1007',
            100.00,
            90.00
        );

        RAISE EXCEPTION
            'TEST FAIL: se permitió producto_key inexistente';

    EXCEPTION
        WHEN foreign_key_violation THEN
            RAISE NOTICE
                'OK 7: producto_key inexistente rechazado.';
    END;
END
$$;

-- ============================================================
-- 8. FK DE CENTRO DE COSTO INEXISTENTE
-- ============================================================

DO $$
BEGIN
    BEGIN
        INSERT INTO dw.fact_consumo_insumo (
            consumo_fact_key,
            fecha_consumo_key,
            producto_key,
            insumo_key,
            centro_costo_key,
            area_key,
            numero_orden,
            consumo_id,
            insumo_codigo_origen,
            cantidad_planificada,
            cantidad_consumida
        )
        VALUES (
            920008,
            20260808,
            0,
            0,
            999999,
            0,
            'TEST-OP-008',
            930008,
            'INS-1008',
            100.00,
            90.00
        );

        RAISE EXCEPTION
            'TEST FAIL: se permitió centro_costo_key inexistente';

    EXCEPTION
        WHEN foreign_key_violation THEN
            RAISE NOTICE
                'OK 8: centro_costo_key inexistente rechazado.';
    END;
END
$$;

DO $$
BEGIN
    RAISE NOTICE
        'TEST OK: reglas funcionales de FACT_CONSUMO_INSUMO verificadas.';
END
$$;

ROLLBACK;
