\set ON_ERROR_STOP on

BEGIN;

INSERT INTO dw.fact_contabilidad (
    movimiento_id_origen,
    fecha_key,
    cuenta_key,
    area_key,
    centro_costo_key,
    documento_tipo,
    documento_numero,
    descripcion,
    moneda_origen,
    tipo_cambio,
    debe_origen,
    haber_origen,
    debe,
    haber,
    saldo,
    cantidad_registros
)
SELECT
    999999991,
    fecha_key,
    0,
    0,
    0,
    'TEST',
    'TEST-001',
    'Fixture transaccional',
    'CLP',
    1.0000,
    100.00,
    0.00,
    100.00,
    0.00,
    100.00,
    1
FROM dw.dim_fecha
WHERE fecha IS NOT NULL
ORDER BY fecha_key
LIMIT 1;

DO $$
BEGIN
    BEGIN
        INSERT INTO dw.fact_contabilidad (
            movimiento_id_origen,
            fecha_key,
            cuenta_key,
            area_key,
            centro_costo_key,
            documento_tipo,
            documento_numero,
            descripcion,
            moneda_origen,
            tipo_cambio,
            debe_origen,
            haber_origen,
            debe,
            haber,
            saldo,
            cantidad_registros
        )
        SELECT
            999999992,
            fecha_key,
            0,
            0,
            0,
            'TEST',
            'TEST-002',
            'Debe y Haber inválidos',
            'CLP',
            1.0000,
            100.00,
            50.00,
            100.00,
            50.00,
            50.00,
            1
        FROM dw.dim_fecha
        WHERE fecha IS NOT NULL
        ORDER BY fecha_key
        LIMIT 1;

        RAISE EXCEPTION 'La regla Debe/Haber no rechazó un movimiento inválido';
    EXCEPTION
        WHEN check_violation THEN
            NULL;
    END;
END $$;

ROLLBACK;

\echo 'TEST OK: reglas funcionales de FACT_CONTABILIDAD verificadas sin dejar fixtures.'
