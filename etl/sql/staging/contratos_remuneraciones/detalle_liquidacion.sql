/* ============================================================================
   staging / detalle_liquidacion.sql — CLEAN/STAGING
   Dominio: Contratos y Remuneraciones
   Motor: SQL Server
   ============================================================================ */

USE ContratosRemuneraciones_ABC;
GO

IF SCHEMA_ID(N'staging') IS NULL
    EXEC('CREATE SCHEMA staging');
GO

CREATE OR ALTER VIEW staging.contratos_remuneraciones_detalle_liquidacion AS
SELECT
    detalle_id,
    liquidacion_id,
    concepto_id,
    monto,
    raw_loaded_at
FROM raw.contratos_remuneraciones_detalle_liquidacion;
GO
