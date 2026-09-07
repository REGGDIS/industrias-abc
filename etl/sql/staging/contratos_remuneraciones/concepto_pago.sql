/* ============================================================================
   staging / concepto_pago.sql — CLEAN/STAGING
   Dominio: Contratos y Remuneraciones
   Motor: SQL Server
   ============================================================================ */

USE ContratosRemuneraciones_ABC;
GO

IF SCHEMA_ID(N'staging') IS NULL
    EXEC('CREATE SCHEMA staging');
GO

CREATE OR ALTER VIEW staging.contratos_remuneraciones_concepto_pago AS
SELECT
    concepto_id,
    UPPER(LTRIM(RTRIM(codigo))) AS codigo,
    LTRIM(RTRIM(descripcion)) AS descripcion,
    UPPER(LTRIM(RTRIM(tipo))) AS tipo,
    afecta_imponible,
    raw_loaded_at
FROM raw.contratos_remuneraciones_concepto_pago;
GO
