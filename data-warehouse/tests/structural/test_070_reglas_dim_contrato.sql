-- ============================================================
-- Industrias ABC - Data Warehouse
-- Test: test_070_reglas_dim_contrato.sql
-- Objetivo:
--   Verificar funcionalmente las reglas de negocio y
--   restricciones críticas de DIM_CONTRATO.
--
-- Motor:
--   PostgreSQL
--
-- Esquema:
--   dw
--
-- Estrategia:
--   Todas las pruebas se ejecutan dentro de una transacción
--   y finalizan con ROLLBACK para no contaminar el DW.
-- ============================================================

\set ON_ERROR_STOP on

BEGIN;

-- ============================================================
-- 1. CONTRATO INDEFINIDO VÁLIDO
-- ============================================================

INSERT INTO dw.dim_contrato (
    contrato_key,
    numero_contrato,
    empleado_key,
    cargo_key,
    tipo_contrato,
    fecha_inicio,
    fecha_termino,
    jornada,
    sueldo_base_contractual,
    cargo_contrato,
    estado_contrato
)
VALUES (
    910001,
    'TEST-CONTRATO-001',
    0,
    0,
    'INDEFINIDO',
    DATE '2026-01-01',
    NULL,
    'COMPLETA',
    750000,
    'Cargo prueba',
    'VIGENTE'
);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM dw.dim_contrato
        WHERE contrato_key = 910001
          AND numero_contrato = 'TEST-CONTRATO-001'
    ) THEN
        RAISE EXCEPTION
            'TEST FAIL: no se insertó contrato indefinido válido';
    END IF;

    RAISE NOTICE
        'OK 1: contrato indefinido válido aceptado.';
END
$$;

-- ============================================================
-- 2. CONTRATO PLAZO FIJO VÁLIDO
-- ============================================================

INSERT INTO dw.dim_contrato (
    contrato_key,
    numero_contrato,
    empleado_key,
    cargo_key,
    tipo_contrato,
    fecha_inicio,
    fecha_termino,
    jornada,
    sueldo_base_contractual,
    cargo_contrato,
    estado_contrato
)
VALUES (
    910002,
    'TEST-CONTRATO-002',
    0,
    0,
    'PLAZO_FIJO',
    DATE '2026-01-01',
    DATE '2026-12-31',
    'COMPLETA',
    800000,
    'Cargo prueba',
    'VIGENTE'
);

DO $$
BEGIN
    RAISE NOTICE
        'OK 2: contrato a plazo fijo válido aceptado.';
END
$$;

-- ============================================================
-- 3. BUSINESS KEY DUPLICADA
-- Debe rechazarse numero_contrato repetido.
-- ============================================================

DO $$
BEGIN
    BEGIN
        INSERT INTO dw.dim_contrato (
            contrato_key,
            numero_contrato,
            empleado_key,
            cargo_key,
            tipo_contrato,
            fecha_inicio,
            jornada,
            sueldo_base_contractual,
            cargo_contrato,
            estado_contrato
        )
        VALUES (
            910003,
            'TEST-CONTRATO-001',
            0,
            0,
            'INDEFINIDO',
            DATE '2026-02-01',
            'COMPLETA',
            700000,
            'Cargo duplicado',
            'VIGENTE'
        );

        RAISE EXCEPTION
            'TEST FAIL: se permitió numero_contrato duplicado';

    EXCEPTION
        WHEN unique_violation THEN
            RAISE NOTICE
                'OK 3: business key duplicada rechazada.';
    END;
END
$$;

-- ============================================================
-- 4. SUELDO NEGATIVO
-- ============================================================

DO $$
BEGIN
    BEGIN
        INSERT INTO dw.dim_contrato (
            contrato_key,
            numero_contrato,
            empleado_key,
            cargo_key,
            tipo_contrato,
            fecha_inicio,
            jornada,
            sueldo_base_contractual,
            cargo_contrato,
            estado_contrato
        )
        VALUES (
            910004,
            'TEST-CONTRATO-004',
            0,
            0,
            'INDEFINIDO',
            DATE '2026-01-01',
            'COMPLETA',
            -1,
            'Cargo prueba',
            'VIGENTE'
        );

        RAISE EXCEPTION
            'TEST FAIL: se permitió sueldo contractual negativo';

    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE
                'OK 4: sueldo contractual negativo rechazado.';
    END;
END
$$;

-- ============================================================
-- 5. FECHA TÉRMINO ANTERIOR A FECHA INICIO
-- ============================================================

DO $$
BEGIN
    BEGIN
        INSERT INTO dw.dim_contrato (
            contrato_key,
            numero_contrato,
            empleado_key,
            cargo_key,
            tipo_contrato,
            fecha_inicio,
            fecha_termino,
            jornada,
            sueldo_base_contractual,
            cargo_contrato,
            estado_contrato
        )
        VALUES (
            910005,
            'TEST-CONTRATO-005',
            0,
            0,
            'PLAZO_FIJO',
            DATE '2026-06-01',
            DATE '2026-05-31',
            'COMPLETA',
            700000,
            'Cargo prueba',
            'VIGENTE'
        );

        RAISE EXCEPTION
            'TEST FAIL: se permitió fecha_termino anterior a fecha_inicio';

    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE
                'OK 5: rango de fechas inválido rechazado.';
    END;
END
$$;

-- ============================================================
-- 6. PLAZO FIJO SIN FECHA DE TÉRMINO
-- ============================================================

DO $$
BEGIN
    BEGIN
        INSERT INTO dw.dim_contrato (
            contrato_key,
            numero_contrato,
            empleado_key,
            cargo_key,
            tipo_contrato,
            fecha_inicio,
            fecha_termino,
            jornada,
            sueldo_base_contractual,
            cargo_contrato,
            estado_contrato
        )
        VALUES (
            910006,
            'TEST-CONTRATO-006',
            0,
            0,
            'PLAZO_FIJO',
            DATE '2026-01-01',
            NULL,
            'COMPLETA',
            700000,
            'Cargo prueba',
            'VIGENTE'
        );

        RAISE EXCEPTION
            'TEST FAIL: se permitió PLAZO_FIJO sin fecha_termino';

    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE
                'OK 6: PLAZO_FIJO sin fecha_termino rechazado.';
    END;
END
$$;

-- ============================================================
-- 7. TIPO DE CONTRATO INVÁLIDO
-- ============================================================

DO $$
BEGIN
    BEGIN
        INSERT INTO dw.dim_contrato (
            contrato_key,
            numero_contrato,
            empleado_key,
            cargo_key,
            tipo_contrato,
            fecha_inicio,
            jornada,
            sueldo_base_contractual,
            cargo_contrato,
            estado_contrato
        )
        VALUES (
            910007,
            'TEST-CONTRATO-007',
            0,
            0,
            'HONORARIOS',
            DATE '2026-01-01',
            'COMPLETA',
            700000,
            'Cargo prueba',
            'VIGENTE'
        );

        RAISE EXCEPTION
            'TEST FAIL: se permitió tipo de contrato fuera del dominio';

    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE
                'OK 7: tipo de contrato inválido rechazado.';
    END;
END
$$;

-- ============================================================
-- 8. ESTADO INVÁLIDO
-- ============================================================

DO $$
BEGIN
    BEGIN
        INSERT INTO dw.dim_contrato (
            contrato_key,
            numero_contrato,
            empleado_key,
            cargo_key,
            tipo_contrato,
            fecha_inicio,
            jornada,
            sueldo_base_contractual,
            cargo_contrato,
            estado_contrato
        )
        VALUES (
            910008,
            'TEST-CONTRATO-008',
            0,
            0,
            'INDEFINIDO',
            DATE '2026-01-01',
            'COMPLETA',
            700000,
            'Cargo prueba',
            'SUSPENDIDO'
        );

        RAISE EXCEPTION
            'TEST FAIL: se permitió estado de contrato fuera del dominio';

    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE
                'OK 8: estado de contrato inválido rechazado.';
    END;
END
$$;

DO $$
BEGIN
    RAISE NOTICE
        'TEST OK: reglas funcionales de DIM_CONTRATO verificadas.';
END
$$;

ROLLBACK;