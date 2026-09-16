-- ============================================================
-- Industrias ABC - Data Warehouse
-- Test: test_090_reglas_fact_remuneraciones.sql
-- Objetivo:
--   Verificar funcionalmente las reglas críticas de
--   FACT_REMUNERACIONES.
--
-- Motor:
--   PostgreSQL
--
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

INSERT INTO dw.fact_remuneraciones (
    remuneracion_fact_key,
    fecha_key,
    empleado_key,
    area_key,
    cargo_key,
    centro_costo_key,
    contrato_key,
    periodo,
    sueldo_base,
    horas_extras,
    sueldo_imponible,
    sueldo_liquido,
    costo_empresa,
    total_haberes,
    total_descuentos,
    total_aportes,
    cantidad_registros
)
VALUES (
    920001,
    20260801,
    0,
    0,
    0,
    0,
    0,
    '2026-08',
    750000,
    10,
    850000,
    700000,
    980000,
    900000,
    200000,
    80000,
    1
);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM dw.fact_remuneraciones
        WHERE remuneracion_fact_key = 920001
          AND empleado_key = 0
          AND periodo = '2026-08'
    ) THEN
        RAISE EXCEPTION
            'TEST FAIL: no se insertó registro válido de FACT_REMUNERACIONES';
    END IF;

    RAISE NOTICE
        'OK 1: registro válido de remuneraciones aceptado.';
END
$$;

-- ============================================================
-- 2. DUPLICIDAD DEL GRANO EMPLEADO + PERÍODO
-- ============================================================

DO $$
BEGIN
    BEGIN
        INSERT INTO dw.fact_remuneraciones (
            remuneracion_fact_key,
            fecha_key,
            empleado_key,
            area_key,
            cargo_key,
            centro_costo_key,
            contrato_key,
            periodo,
            sueldo_base,
            horas_extras,
            sueldo_imponible,
            sueldo_liquido,
            costo_empresa,
            total_haberes,
            total_descuentos,
            total_aportes,
            cantidad_registros
        )
        VALUES (
            920002,
            20260801,
            0,
            0,
            0,
            0,
            0,
            '2026-08',
            700000,
            0,
            700000,
            600000,
            800000,
            700000,
            100000,
            50000,
            1
        );

        RAISE EXCEPTION
            'TEST FAIL: se permitió duplicar empleado + período';

    EXCEPTION
        WHEN unique_violation THEN
            RAISE NOTICE
                'OK 2: duplicidad empleado + período rechazada.';
    END;
END
$$;

-- ============================================================
-- 3. PERÍODO INVÁLIDO
-- ============================================================

DO $$
BEGIN
    BEGIN
        INSERT INTO dw.fact_remuneraciones (
            remuneracion_fact_key,
            fecha_key,
            empleado_key,
            area_key,
            cargo_key,
            centro_costo_key,
            contrato_key,
            periodo,
            sueldo_base,
            horas_extras,
            sueldo_imponible,
            sueldo_liquido,
            costo_empresa,
            total_haberes,
            total_descuentos,
            total_aportes,
            cantidad_registros
        )
        VALUES (
            920003,
            20260801,
            0,
            0,
            0,
            0,
            0,
            '2026-13',
            700000,
            0,
            700000,
            600000,
            800000,
            700000,
            100000,
            50000,
            1
        );

        RAISE EXCEPTION
            'TEST FAIL: se permitió período inválido';

    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE
                'OK 3: período inválido rechazado.';
    END;
END
$$;

-- ============================================================
-- 4. SUELDO BASE NEGATIVO
-- ============================================================

DO $$
BEGIN
    BEGIN
        INSERT INTO dw.fact_remuneraciones (
            remuneracion_fact_key,
            fecha_key,
            empleado_key,
            area_key,
            cargo_key,
            centro_costo_key,
            contrato_key,
            periodo,
            sueldo_base,
            horas_extras,
            sueldo_imponible,
            sueldo_liquido,
            costo_empresa,
            total_haberes,
            total_descuentos,
            total_aportes,
            cantidad_registros
        )
        VALUES (
            920004,
            20260901,
            0,
            0,
            0,
            0,
            0,
            '2026-09',
            -1,
            0,
            700000,
            600000,
            800000,
            700000,
            100000,
            50000,
            1
        );

        RAISE EXCEPTION
            'TEST FAIL: se permitió sueldo_base negativo';

    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE
                'OK 4: sueldo_base negativo rechazado.';
    END;
END
$$;

-- ============================================================
-- 5. HORAS EXTRAS NEGATIVAS
-- ============================================================

DO $$
BEGIN
    BEGIN
        INSERT INTO dw.fact_remuneraciones (
            remuneracion_fact_key,
            fecha_key,
            empleado_key,
            area_key,
            cargo_key,
            centro_costo_key,
            contrato_key,
            periodo,
            sueldo_base,
            horas_extras,
            sueldo_imponible,
            sueldo_liquido,
            costo_empresa,
            total_haberes,
            total_descuentos,
            total_aportes,
            cantidad_registros
        )
        VALUES (
            920005,
            20260901,
            0,
            0,
            0,
            0,
            0,
            '2026-09',
            700000,
            -1,
            700000,
            600000,
            800000,
            700000,
            100000,
            50000,
            1
        );

        RAISE EXCEPTION
            'TEST FAIL: se permitieron horas_extras negativas';

    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE
                'OK 5: horas_extras negativas rechazadas.';
    END;
END
$$;

-- ============================================================
-- 6. TOTAL DESCUENTOS NEGATIVO
-- ============================================================

DO $$
BEGIN
    BEGIN
        INSERT INTO dw.fact_remuneraciones (
            remuneracion_fact_key,
            fecha_key,
            empleado_key,
            area_key,
            cargo_key,
            centro_costo_key,
            contrato_key,
            periodo,
            sueldo_base,
            horas_extras,
            sueldo_imponible,
            sueldo_liquido,
            costo_empresa,
            total_haberes,
            total_descuentos,
            total_aportes,
            cantidad_registros
        )
        VALUES (
            920006,
            20260901,
            0,
            0,
            0,
            0,
            0,
            '2026-09',
            700000,
            0,
            700000,
            600000,
            800000,
            700000,
            -1,
            50000,
            1
        );

        RAISE EXCEPTION
            'TEST FAIL: se permitió total_descuentos negativo';

    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE
                'OK 6: total_descuentos negativo rechazado.';
    END;
END
$$;

-- ============================================================
-- 7. CANTIDAD_REGISTROS DISTINTA DE 1
-- ============================================================

DO $$
BEGIN
    BEGIN
        INSERT INTO dw.fact_remuneraciones (
            remuneracion_fact_key,
            fecha_key,
            empleado_key,
            area_key,
            cargo_key,
            centro_costo_key,
            contrato_key,
            periodo,
            sueldo_base,
            horas_extras,
            sueldo_imponible,
            sueldo_liquido,
            costo_empresa,
            total_haberes,
            total_descuentos,
            total_aportes,
            cantidad_registros
        )
        VALUES (
            920007,
            20260901,
            0,
            0,
            0,
            0,
            0,
            '2026-09',
            700000,
            0,
            700000,
            600000,
            800000,
            700000,
            100000,
            50000,
            2
        );

        RAISE EXCEPTION
            'TEST FAIL: se permitió cantidad_registros distinta de 1';

    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE
                'OK 7: cantidad_registros distinta de 1 rechazada.';
    END;
END
$$;

-- ============================================================
-- 8. FK DE CONTRATO INEXISTENTE
-- ============================================================

DO $$
BEGIN
    BEGIN
        INSERT INTO dw.fact_remuneraciones (
            remuneracion_fact_key,
            fecha_key,
            empleado_key,
            area_key,
            cargo_key,
            centro_costo_key,
            contrato_key,
            periodo,
            sueldo_base,
            horas_extras,
            sueldo_imponible,
            sueldo_liquido,
            costo_empresa,
            total_haberes,
            total_descuentos,
            total_aportes,
            cantidad_registros
        )
        VALUES (
            920008,
            20260901,
            0,
            0,
            0,
            0,
            999999,
            '2026-09',
            700000,
            0,
            700000,
            600000,
            800000,
            700000,
            100000,
            50000,
            1
        );

        RAISE EXCEPTION
            'TEST FAIL: se permitió contrato_key inexistente';

    EXCEPTION
        WHEN foreign_key_violation THEN
            RAISE NOTICE
                'OK 8: contrato_key inexistente rechazado.';
    END;
END
$$;

DO $$
BEGIN
    RAISE NOTICE
        'TEST OK: reglas funcionales de FACT_REMUNERACIONES verificadas.';
END
$$;

ROLLBACK;