-- ============================================================
-- Industrias ABC - Data Warehouse
-- Test: test_001_esquema_dw.sql
-- Objetivo:
--   Verificar que exista el esquema principal dw.
-- Motor:
--   PostgreSQL
-- ============================================================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.schemata
        WHERE schema_name = 'dw'
    ) THEN
        RAISE EXCEPTION
            'TEST FALLIDO: el esquema dw no existe.';
    END IF;
END
$$;

SELECT
    'TEST OK: esquema dw existente.' AS resultado;
