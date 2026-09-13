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
          AND cantidad_planificada = 500.00
          AND cantidad_consumida = 495.00
          AND desviacion = -5.00
    ) THEN
        RAISE EXCEPTION
            'TEST FAIL: no se insertó registro válido de FACT_CONSUMO_INSUMO';
    END IF;

    RAISE NOTICE
        'OK 1: registro válido de FACT_CONSUMO_INSUMO aceptado.';
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
-- 5. CONSUMIDA MAYOR QUE PLANIFICADA
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
            100.00,
            101.00
        );

        RAISE EXCEPTION
            'TEST FAIL: se permitió cantidad_consumida superior a cantidad_planificada';

    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE
                'OK 5: cantidad_consumida superior a cantidad_planificada rechazada.';
    END;
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