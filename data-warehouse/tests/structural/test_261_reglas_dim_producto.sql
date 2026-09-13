-- ============================================================
-- Industrias ABC - Data Warehouse
-- Test: test_261_reglas_dim_producto.sql
-- Objetivo:
--   Verificar funcionalmente las reglas críticas de
--   DIM_PRODUCTO.
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
-- 1. PRODUCTO VÁLIDO
-- ============================================================

INSERT INTO dw.dim_producto (
    producto_key,
    codigo_producto,
    nombre_producto,
    categoria,
    unidad_medida
)
VALUES (
    920001,
    'TEST-PROD-001',
    'Producto de prueba',
    'PRUEBA',
    'UNIDAD'
);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM dw.dim_producto
        WHERE producto_key = 920001
          AND codigo_producto = 'TEST-PROD-001'
    ) THEN
        RAISE EXCEPTION
            'TEST FAIL: no se insertó producto válido';
    END IF;

    RAISE NOTICE
        'OK 1: producto válido aceptado.';
END
$$;

-- ============================================================
-- 2. BUSINESS KEY DUPLICADA
-- ============================================================

DO $$
BEGIN
    BEGIN
        INSERT INTO dw.dim_producto (
            producto_key,
            codigo_producto,
            nombre_producto,
            categoria,
            unidad_medida
        )
        VALUES (
            920002,
            'TEST-PROD-001',
            'Producto duplicado',
            'PRUEBA',
            'UNIDAD'
        );

        RAISE EXCEPTION
            'TEST FAIL: se permitió duplicar codigo_producto';

    EXCEPTION
        WHEN unique_violation THEN
            RAISE NOTICE
                'OK 2: duplicidad de codigo_producto rechazada.';
    END;
END
$$;

-- ============================================================
-- 3. CLAVE NEGATIVA
-- ============================================================

DO $$
BEGIN
    BEGIN
        INSERT INTO dw.dim_producto (
            producto_key,
            codigo_producto,
            nombre_producto,
            categoria,
            unidad_medida
        )
        VALUES (
            -1,
            'TEST-PROD-002',
            'Producto inválido',
            'PRUEBA',
            'UNIDAD'
        );

        RAISE EXCEPTION
            'TEST FAIL: se permitió producto_key negativa';

    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE
                'OK 3: producto_key negativa rechazada.';
    END;
END
$$;

-- ============================================================
-- 4. REGISTRO REAL CON CÓDIGO DESCONOCIDO
-- ============================================================

DO $$
BEGIN
    BEGIN
        INSERT INTO dw.dim_producto (
            producto_key,
            codigo_producto,
            nombre_producto,
            categoria,
            unidad_medida
        )
        VALUES (
            920003,
            'DESCONOCIDO',
            'Producto inválido',
            'PRUEBA',
            'UNIDAD'
        );

        RAISE EXCEPTION
            'TEST FAIL: se permitió codigo_producto DESCONOCIDO con producto_key distinta de 0';

    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE
                'OK 4: codigo_producto DESCONOCIDO restringido al miembro 0.';
    END;
END
$$;

-- ============================================================
-- 5. MIEMBRO DESCONOCIDO CON CLAVE DISTINTA DE 0
-- ============================================================

DO $$
BEGIN
    BEGIN
        INSERT INTO dw.dim_producto (
            producto_key,
            codigo_producto,
            nombre_producto,
            categoria,
            unidad_medida
        )
        VALUES (
            920004,
            'DESCONOCIDO',
            'No informado',
            'DESCONOCIDO',
            'DESCONOCIDO'
        );

        RAISE EXCEPTION
            'TEST FAIL: se permitió duplicar el miembro desconocido';

    EXCEPTION
        WHEN unique_violation THEN
            RAISE NOTICE
                'OK 5: miembro desconocido no duplicable por business key.';
        WHEN check_violation THEN
            RAISE NOTICE
                'OK 5: miembro desconocido restringido a producto_key = 0.';
    END;
END
$$;

-- ============================================================
-- 6. VERIFICACIÓN DEL MIEMBRO DESCONOCIDO
-- ============================================================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM dw.dim_producto
        WHERE producto_key = 0
          AND codigo_producto = 'DESCONOCIDO'
          AND nombre_producto = 'No informado'
          AND categoria = 'DESCONOCIDO'
          AND unidad_medida = 'DESCONOCIDO'
    ) THEN
        RAISE EXCEPTION
            'TEST FAIL: miembro desconocido de DIM_PRODUCTO inconsistente';
    END IF;

    RAISE NOTICE
        'OK 6: miembro desconocido de DIM_PRODUCTO verificado.';
END
$$;

DO $$
BEGIN
    RAISE NOTICE
        'TEST OK: reglas funcionales de DIM_PRODUCTO verificadas.';
END
$$;

ROLLBACK;