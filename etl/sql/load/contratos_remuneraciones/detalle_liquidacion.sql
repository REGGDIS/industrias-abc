/* ============================================================================
   load / detalle_liquidacion.sql — Landing RAW
   Dominio: Contratos y Remuneraciones
   Motor: SQL Server
   ----------------------------------------------------------------------------
   Materializa dbo.DetalleLiquidacion en una tabla RAW física.
   No limpia ni transforma datos.
   ============================================================================ */

USE ContratosRemuneraciones_ABC;
GO

IF SCHEMA_ID(N'raw') IS NULL
    EXEC('CREATE SCHEMA raw');
GO

IF OBJECT_ID(N'raw.contratos_remuneraciones_detalle_liquidacion', N'U') IS NULL
BEGIN
    CREATE TABLE raw.contratos_remuneraciones_detalle_liquidacion (
        detalle_id       INT           NULL,
        liquidacion_id   INT           NULL,
        concepto_id      INT           NULL,
        monto            DECIMAL(12,2) NULL,
        raw_loaded_at    DATETIME2     NOT NULL
            CONSTRAINT DF_raw_cr_detalle_liquidacion_loaded_at
            DEFAULT (SYSUTCDATETIME())
    );
END
GO

TRUNCATE TABLE raw.contratos_remuneraciones_detalle_liquidacion;
GO

INSERT INTO raw.contratos_remuneraciones_detalle_liquidacion
    (detalle_id, liquidacion_id, concepto_id, monto)
SELECT
    detalle_id,
    liquidacion_id,
    concepto_id,
    monto
FROM dbo.DetalleLiquidacion;
GO
