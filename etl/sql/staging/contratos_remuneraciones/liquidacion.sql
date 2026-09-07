/* ============================================================================
   staging / liquidacion.sql — CLEAN/STAGING (v0.2)
   Dominio:  Contratos y Remuneraciones
   Motor:    SQL Server
   Encargo:  Contratos/Remuneraciones 0.2
   ----------------------------------------------------------------------------
   Lee desde raw.contratos_remuneraciones_liquidacion. NO lee directo desde
   dbo.Liquidacion.
   ----------------------------------------------------------------------------
   Reglas de limpieza aplicadas (superficiales y seguras):
   - LTRIM/RTRIM sobre periodo, sin reformatear su semántica YYYY-MM.
   - Todos los montos y horas extra se conservan en su precisión original;
     no se recalcula sueldo_imponible, sueldo_liquido ni costo_empresa aquí.
   - liquidacion_id, empleado_id y contrato_id se conservan como
     identificadores locales de trazabilidad.
   ============================================================================ */
USE ContratosRemuneraciones_ABC;
GO

IF SCHEMA_ID(N'staging') IS NULL EXEC('CREATE SCHEMA staging');
GO

CREATE OR ALTER VIEW staging.contratos_remuneraciones_liquidacion AS
SELECT
    liquidacion_id,
    empleado_id,
    contrato_id,
    LTRIM(RTRIM(periodo)) AS periodo,
    sueldo_base,
    horas_extras,
    sueldo_imponible,
    sueldo_liquido,
    costo_empresa,
    raw_loaded_at
FROM raw.contratos_remuneraciones_liquidacion;
GO
