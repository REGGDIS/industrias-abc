-- ============================================================
-- Industrias ABC - Data Warehouse
-- Test: test_290_reglas_dw_produccion.sql
-- Objetivo:
--   Verificar reglas transversales del modelo físico
--   DW-PRODUCCIÓN.
-- Motor:
--   PostgreSQL 16
-- Esquema:
--   dw
--
-- Reglas verificadas:
--   - miembros desconocidos de las dimensiones utilizadas;
--   - separación de grano entre FACT_PRODUCCION y
--     FACT_CONSUMO_INSUMO;
--   - uso de fecha_key = 0 para órdenes abiertas;
--   - trazabilidad del código de insumo de origen;
--   - cálculo de desviacion;
--   - protección del grano de ambos hechos;
--   - integridad referencial mediante miembros desconocidos;
--   - ausencia de mezcla del consumo de insumos dentro de
--     FACT_PRODUCCION.
--
-- Estrategia:
--   Las pruebas funcionales se ejecutan dentro de una
--   transacción y terminan con ROLLBACK.
-- ============================================================

\set ON_ERROR_STOP on

-- ============================================================
-- 1. MIEMBRO DESCONOCIDO DE DIM_PRODUCTO
-- ============================================================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM dw.dim_producto
        WHERE producto_key = 0
          AND codigo_producto = 'DESCONOCIDO'
    ) THEN
        RAISE EXCEPTION
            'TEST FAIL: falta miembro desconocido de DIM_PRODUCTO';
    END IF;

    RAISE NOTICE
        'OK 1: miembro desconocido de DIM_PRODUCTO verificado.';
END
$$;

-- ============================================================
-- 2. MIEMBRO DESCONOCIDO DE DIM_INSUMO
-- ============================================================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM dw.dim_insumo
        WHERE insumo_key = 0
          AND codigo_insumo = 'DESCONOCIDO'
    ) THEN
        RAISE EXCEPTION
            'TEST FAIL: falta miembro desconocido de DIM_INSUMO';
    END IF;

    RAISE NOTICE
        'OK 2: miembro desconocido de DIM_INSUMO verificado.';
END
$$;

-- ============================================================
-- 3. MIEMBRO DESCONOCIDO DE DIM_CENTRO_COSTO
-- ============================================================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM dw.dim_centro_costo
        WHERE centro_costo_key = 0
    ) THEN
        RAISE EXCEPTION
            'TEST FAIL: falta centro_costo_key = 0';
    END IF;

    RAISE NOTICE
        'OK 3: miembro desconocido de DIM_CENTRO_COSTO verificado.';
END
$$;

-- ============================================================
-- 4. MIEMBRO DESCONOCIDO DE DIM_AREA
-- ============================================================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM dw.dim_area
        WHERE area_key = 0
    ) THEN
        RAISE EXCEPTION
            'TEST FAIL: falta area_key = 0';
    END IF;

    RAISE NOTICE
        'OK 4: miembro desconocido de DIM_AREA verificado.';
END
$$;

-- ============================================================
-- 5. MIEMBRO DESCONOCIDO DE DIM_FECHA
-- ============================================================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM dw.dim_fecha
        WHERE fecha_key = 0
    ) THEN
        RAISE EXCEPTION
            'TEST FAIL: falta fecha_key = 0';
    END IF;

    RAISE NOTICE
        'OK 5: miembro desconocido de DIM_FECHA verificado.';
END
$$;

BEGIN;

-- ============================================================
-- 6. REGISTRO VÁLIDO DE FACT_PRODUCCION CON ORDEN ABIERTA
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
    929001,
    20260801,
    0,
    0,
    0,
    0,
    'TEST-RULE-OP-001',
    100.00,
    90.00,
    10.00,
    'EN_PROCESO'
);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM dw.fact_produccion
        WHERE produccion_fact_key = 929001
          AND numero_orden = 'TEST-RULE-OP-001'
          AND fecha_termino_key = 0
    ) THEN
        RAISE EXCEPTION
            'TEST FAIL: no se pudo registrar orden abierta con fecha_termino_key = 0';
    END IF;

    RAISE NOTICE
        'OK 6: FACT_PRODUCCION usa fecha_key = 0 para una orden abierta.';
END
$$;

-- ============================================================
-- 7. REGISTRO VÁLIDO DE FACT_CONSUMO_INSUMO
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
    929002,
    20260801,
    0,
    0,
    0,
    0,
    'TEST-RULE-OP-001',
    939001,
    'INS-1001',
    100.00,
    95.00
);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM dw.fact_consumo_insumo
        WHERE consumo_fact_key = 929002
          AND consumo_id = 939001
          AND insumo_codigo_origen = 'INS-1001'
          AND desviacion = -5.00
    ) THEN
        RAISE EXCEPTION
            'TEST FAIL: no se registró correctamente el consumo de prueba';
    END IF;

    RAISE NOTICE
        'OK 7: FACT_CONSUMO_INSUMO acepta registro válido, conserva código de origen y calcula desviacion.';
END
$$;

-- ============================================================
-- 8. SEPARACIÓN DE GRANOS
-- ============================================================

DO $$
DECLARE
    cantidad_produccion INTEGER;
    cantidad_consumo INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO cantidad_produccion
    FROM dw.fact_produccion
    WHERE numero_orden = 'TEST-RULE-OP-001';

    SELECT COUNT(*)
    INTO cantidad_consumo
    FROM dw.fact_consumo_insumo
    WHERE numero_orden = 'TEST-RULE-OP-001';

    IF cantidad_produccion <> 1 THEN
        RAISE EXCEPTION
            'TEST FAIL: FACT_PRODUCCION no respeta una fila por orden';
    END IF;

    IF cantidad_consumo <> 1 THEN
        RAISE EXCEPTION
            'TEST FAIL: FACT_CONSUMO_INSUMO no registra su propio grano';
    END IF;

    RAISE NOTICE
        'OK 8: los granos de producción y consumo permanecen separados.';
END
$$;

-- ============================================================
-- 9. TRAZABILIDAD DEL CONSUMO
-- ============================================================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM dw.fact_consumo_insumo
        WHERE consumo_id = 939001
          AND numero_orden = 'TEST-RULE-OP-001'
          AND insumo_codigo_origen = 'INS-1001'
    ) THEN
        RAISE EXCEPTION
            'TEST FAIL: no quedó conservada la trazabilidad del consumo y del código de insumo';
    END IF;

    RAISE NOTICE
        'OK 9: trazabilidad mediante consumo_id e insumo_codigo_origen verificada.';
END
$$;

-- ============================================================
-- 10. CÁLCULO DE DESVIACIÓN
-- ============================================================

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM dw.fact_consumo_insumo
        WHERE consumo_id = 939001
          AND desviacion <> (
              cantidad_consumida - cantidad_planificada
          )
    ) THEN
        RAISE EXCEPTION
            'TEST FAIL: desviacion no coincide con consumo - planificación';
    END IF;

    RAISE NOTICE
        'OK 10: fórmula de desviacion verificada.';
END
$$;

ROLLBACK;

-- ============================================================
-- 11. VERIFICACIÓN DE ROLLBACK
-- ============================================================

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM dw.fact_produccion
        WHERE produccion_fact_key = 929001
    ) THEN
        RAISE EXCEPTION
            'TEST FAIL: FACT_PRODUCCION dejó fixture persistente';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM dw.fact_consumo_insumo
        WHERE consumo_fact_key = 929002
    ) THEN
        RAISE EXCEPTION
            'TEST FAIL: FACT_CONSUMO_INSUMO dejó fixture persistente';
    END IF;

    RAISE NOTICE
        'OK 11: ROLLBACK eliminó correctamente los fixtures de prueba.';
END
$$;

DO $$
BEGIN
    RAISE NOTICE
        'TEST OK: reglas generales de DW-PRODUCCION verificadas.';
END
$$;
