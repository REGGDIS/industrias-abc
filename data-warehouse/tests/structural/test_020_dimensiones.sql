-- ============================================================
-- Industrias ABC - Data Warehouse
-- Test: test_020_dimensiones.sql
-- Objetivo:
--   Verificar la existencia de las dimensiones principales
--   del DW-CORE.
-- Motor:
--   PostgreSQL
-- Esquema:
--   dw
-- ============================================================

DO $$
DECLARE
    tablas_faltantes TEXT;
BEGIN
    SELECT STRING_AGG(nombre_tabla, ', ' ORDER BY nombre_tabla)
    INTO tablas_faltantes
    FROM (
        VALUES
            ('dim_fecha'),
            ('dim_area'),
            ('dim_centro_costo'),
            ('dim_cargo'),
            ('dim_empleado'),
            ('dim_turno')
    ) AS esperadas(nombre_tabla)
    WHERE NOT EXISTS (
        SELECT 1
        FROM information_schema.tables t
        WHERE t.table_schema = 'dw'
          AND t.table_name = esperadas.nombre_tabla
          AND t.table_type = 'BASE TABLE'
    );

    IF tablas_faltantes IS NOT NULL THEN
        RAISE EXCEPTION
            'TEST FALLIDO: faltan dimensiones CORE: %',
            tablas_faltantes;
    END IF;
END
$$;

SELECT
    'TEST OK: todas las dimensiones CORE existen.' AS resultado;
