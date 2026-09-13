-- ============================================================
-- Industrias ABC - Data Warehouse
-- Test: test_271_reglas_fact_produccion.sql
-- Objetivo:
--   Verificar funcionalmente las reglas críticas de
--   FACT_PRODUCCION.
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

INSERT INTO dw.fact_produccion (
    produccion_fact_key,
    fecha_inicio_key,
    fecha_termino_key,
    producto_key,
    centro_costo_key,
    area_key,
    numero_orden,
    cantidad_planificada,
    cantidad_producida,
    cantidad_rechazada,
    estado
)
VALUES (
    920001,
    20260801,
    20260810,
    0,
    0,
    0,
    'TEST-OP-001',
    500.00,
    480.00,
    20.00,
    'TERMINADA'
);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM dw.fact_produccion
        WHERE produccion_fact_key = 920001
          AND numero_orden = 'TEST-OP-001'
    ) THEN
        RAISE EXCEPTION
            'TEST FAIL: no se insertó registro válido de FACT_PRODUCCION';
    END IF;

    RAISE NOTICE
        'OK 1: registro válido de FACT_PRODUCCION aceptado.';
END
$$;

-- ============================================================
-- 2. DUPLICIDAD DEL GRANO: NUMERO DE ORDEN
-- ============================================================

DO $$
BEGIN
    BEGIN
        INSERT INTO dw.fact_produccion (
            produccion_fact_key,
            fecha_inicio_key,
            fecha_termino_key,
            producto_key,
            centro_costo_key,
            area_key,
            numero_orden,
            cantidad_planificada,
            cantidad_producida,
            cantidad_rechazada,
            estado
        )
        VALUES (
            920002,
            20260801,
            20260810,
            0,
            0,
            0,
            'TEST-OP-001',
            400.00,
            390.00,
            10.00,
            'TERMINADA'
        );

        RAISE EXCEPTION
            'TEST FAIL: se permitió duplicar numero_orden';

    EXCEPTION
        WHEN unique_violation THEN
            RAISE NOTICE
                'OK 2: duplicidad de numero_orden rechazada.';
    END;
END
$$;

-- ============================================================
-- 3. CANTIDAD PLANIFICADA NEGATIVA
-- ============================================================

DO $$
BEGIN
    BEGIN
        INSERT INTO dw.fact_produccion (
            produccion_fact_key,
            fecha_inicio_key,
            fecha_termino_key,
            producto_key,
            centro_costo_key,
            area_key,
            numero_orden,
            cantidad_planificada,
            cantidad_producida,
            cantidad_rechazada,
            estado
        )
        VALUES (
            920003,
            20260801,
            20260810,
            0,
            0,
            0,
            'TEST-OP-002',
            -1.00,
            10.00,
            0.00,
            'TERMINADA'
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
-- 4. CANTIDAD PRODUCIDA NEGATIVA
-- ============================================================

DO $$
BEGIN
    BEGIN
        INSERT INTO dw.fact_produccion (
            produccion_fact_key,
            fecha_inicio_key,
            fecha_termino_key,
            producto_key,
            centro_costo_key,
            area_key,
            numero_orden,
            cantidad_planificada,
            cantidad_producida,
            cantidad_rechazada,
            estado
        )
        VALUES (
            920004,
            20260801,
            20260810,
            0,
            0,
            0,
            'TEST-OP-003',
            100.00,
            -1.00,
            0.00,
            'TERMINADA'
        );

        RAISE EXCEPTION
            'TEST FAIL: se permitió cantidad_producida negativa';

    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE
                'OK 4: cantidad_producida negativa rechazada.';
    END;
END
$$;

-- ============================================================
-- 5. CANTIDAD RECHAZADA NEGATIVA
-- ============================================================

DO $$
BEGIN
    BEGIN
        INSERT INTO dw.fact_produccion (
            produccion_fact_key,
            fecha_inicio_key,
            fecha_termino_key,
            producto_key,
            centro_costo_key,
            area_key,
            numero_orden,
            cantidad_planificada,
            cantidad_producida,
            cantidad_rechazada,
            estado
        )
        VALUES (
            920005,
            20260801,
            20260810,
            0,
            0,
            0,
            'TEST-OP-004',
            100.00,
            80.00,
            -1.00,
            'TERMINADA'
        );

        RAISE EXCEPTION
            'TEST FAIL: se permitió cantidad_rechazada negativa';

    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE
                'OK 5: cantidad_rechazada negativa rechazada.';
    END;
END
$$;

-- ============================================================
-- 6. RECHAZADA MAYOR QUE PRODUCIDA
-- ============================================================

DO $$
BEGIN
    BEGIN
        INSERT INTO dw.fact_produccion (
            produccion_fact_key,
            fecha_inicio_key,
            fecha_termino_key,
            producto_key,
            centro_costo_key,
            area_key,
            numero_orden,
            cantidad_planificada,
            cantidad_producida,
            cantidad_rechazada,
            estado
        )
        VALUES (
            920006,
            20260801,
            20260810,
            0,
            0,
            0,
            'TEST-OP-005',
            100.00,
            20.00,
            25.00,
            'TERMINADA'
        );

        RAISE EXCEPTION
            'TEST FAIL: se permitió cantidad_rechazada superior a cantidad_producida';

    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE
                'OK 6: cantidad_rechazada superior a cantidad_producida rechazada.';
    END;
END
$$;

-- ============================================================
-- 7. ORDEN ABIERTA USA FECHA_TERMINO_KEY = 0
-- ============================================================

INSERT INTO dw.fact_produccion (
    produccion_fact_key,
    fecha_inicio_key,
    fecha_termino_key,
    producto_key,
    centro_costo_key,
    area_key,
    numero_orden,
    cantidad_planificada,
    cantidad_producida,
    cantidad_rechazada,
    estado
)
VALUES (
    920007,
    20260801,
    0,
    0,
    0,
    0,
    'TEST-OP-006',
    100.00,
    50.00,
    0.00,
    'EN_PROCESO'
);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM dw.fact_produccion
        WHERE produccion_fact_key = 920007
          AND fecha_termino_key = 0
    ) THEN
        RAISE EXCEPTION
            'TEST FAIL: orden abierta no usó fecha_termino_key = 0';
    END IF;

    RAISE NOTICE
        'OK 7: orden abierta usa fecha_termino_key = 0.';
END
$$;

-- ============================================================
-- 8. FECHA_TERMINO_KEY NULL DEBE FALLAR
-- ============================================================

DO $$
BEGIN
    BEGIN
        INSERT INTO dw.fact_produccion (
            produccion_fact_key,
            fecha_inicio_key,
            fecha_termino_key,
            producto_key,
            centro_costo_key,
            area_key,
            numero_orden,
            cantidad_planificada,
            cantidad_producida,
            cantidad_rechazada,
            estado
        )
        VALUES (
            920008,
            20260801,
            NULL,
            0,
            0,
            0,
            'TEST-OP-007',
            100.00,
            50.00,
            0.00,
            'EN_PROCESO'
        );

        RAISE EXCEPTION
            'TEST FAIL: se permitió fecha_termino_key NULL';

    EXCEPTION
        WHEN not_null_violation THEN
            RAISE NOTICE
                'OK 8: fecha_termino_key NULL rechazada.';
    END;
END
$$;

-- ============================================================
-- 9. FK DE PRODUCTO INEXISTENTE
-- ============================================================

DO $$
BEGIN
    BEGIN
        INSERT INTO dw.fact_produccion (
            produccion_fact_key,
            fecha_inicio_key,
            fecha_termino_key,
            producto_key,
            centro_costo_key,
            area_key,
            numero_orden,
            cantidad_planificada,
            cantidad_producida,
            cantidad_rechazada,
            estado
        )
        VALUES (
            920009,
            20260801,
            20260810,
            999999,
            0,
            0,
            'TEST-OP-008',
            100.00,
            90.00,
            10.00,
            'TERMINADA'
        );

        RAISE EXCEPTION
            'TEST FAIL: se permitió producto_key inexistente';

    EXCEPTION
        WHEN foreign_key_violation THEN
            RAISE NOTICE
                'OK 9: producto_key inexistente rechazado.';
    END;
END
$$;

-- ============================================================
-- 10. FK DE CENTRO DE COSTO INEXISTENTE
-- ============================================================

DO $$
BEGIN
    BEGIN
        INSERT INTO dw.fact_produccion (
            produccion_fact_key,
            fecha_inicio_key,
            fecha_termino_key,
            producto_key,
            centro_costo_key,
            area_key,
            numero_orden,
            cantidad_planificada,
            cantidad_producida,
            cantidad_rechazada,
            estado
        )
        VALUES (
            920010,
            20260801,
            20260810,
            0,
            999999,
            0,
            'TEST-OP-009',
            100.00,
            90.00,
            10.00,
            'TERMINADA'
        );

        RAISE EXCEPTION
            'TEST FAIL: se permitió centro_costo_key inexistente';

    EXCEPTION
        WHEN foreign_key_violation THEN
            RAISE NOTICE
                'OK 10: centro_costo_key inexistente rechazado.';
    END;
END
$$;

DO $$
BEGIN
    RAISE NOTICE
        'TEST OK: reglas funcionales de FACT_PRODUCCION verificadas.';
END
$$;

ROLLBACK;
