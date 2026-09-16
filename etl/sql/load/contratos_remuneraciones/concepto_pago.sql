/* ============================================================================
   load / concepto_pago.sql — Landing RAW
   Dominio: Contratos y Remuneraciones
   Motor: SQL Server
   ----------------------------------------------------------------------------
   Materializa dbo.ConceptoPago en una tabla RAW física.
   No limpia ni homologa datos.
   ============================================================================ */

USE ContratosRemuneraciones_ABC;
GO

IF SCHEMA_ID(N'raw') IS NULL
    EXEC('CREATE SCHEMA raw');
GO

IF OBJECT_ID(N'raw.contratos_remuneraciones_concepto_pago', N'U') IS NULL
BEGIN
    CREATE TABLE raw.contratos_remuneraciones_concepto_pago (
        concepto_id       INT           NULL,
        codigo            VARCHAR(15)   NULL,
        descripcion       NVARCHAR(100) NULL,
        tipo              VARCHAR(10)   NULL,
        afecta_imponible  BIT           NULL,
        raw_loaded_at     DATETIME2     NOT NULL
            CONSTRAINT DF_raw_cr_concepto_pago_loaded_at
            DEFAULT (SYSUTCDATETIME())
    );
END
GO

TRUNCATE TABLE raw.contratos_remuneraciones_concepto_pago;
GO

INSERT INTO raw.contratos_remuneraciones_concepto_pago
    (concepto_id, codigo, descripcion, tipo, afecta_imponible)
SELECT
    concepto_id,
    codigo,
    descripcion,
    tipo,
    afecta_imponible
FROM dbo.ConceptoPago;
GO
