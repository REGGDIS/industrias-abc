/* ============================================================================
   load / liquidacion.sql — Landing RAW
   Dominio:  Contratos y Remuneraciones
   Motor:    SQL Server
   Encargo:  Contratos/Remuneraciones 0.2
   ----------------------------------------------------------------------------
   Materializa la extracción de Liquidación (fuente: dbo.Liquidacion) en una
   tabla RAW física. El staging debe leer desde
   raw.contratos_remuneraciones_liquidacion, nunca directo desde
   dbo.Liquidacion.
   ============================================================================ */
USE ContratosRemuneraciones_ABC;
GO

IF SCHEMA_ID(N'raw') IS NULL EXEC('CREATE SCHEMA raw');
GO

IF OBJECT_ID(N'raw.contratos_remuneraciones_liquidacion', N'U') IS NULL
BEGIN
    CREATE TABLE raw.contratos_remuneraciones_liquidacion (
        liquidacion_id      INT             NULL,
        empleado_id         VARCHAR(10)     NULL,
        contrato_id         INT             NULL,
        periodo             CHAR(7)         NULL,
        sueldo_base         DECIMAL(12,2)   NULL,
        horas_extras        DECIMAL(6,2)    NULL,
        sueldo_imponible    DECIMAL(12,2)   NULL,
        sueldo_liquido      DECIMAL(12,2)   NULL,
        costo_empresa       DECIMAL(12,2)   NULL,
        raw_loaded_at       DATETIME2       NOT NULL
            CONSTRAINT DF_raw_cr_liquidacion_loaded_at DEFAULT (SYSUTCDATETIME())
    );
END
GO

TRUNCATE TABLE raw.contratos_remuneraciones_liquidacion;
GO

INSERT INTO raw.contratos_remuneraciones_liquidacion
    (liquidacion_id, empleado_id, contrato_id, periodo, sueldo_base,
     horas_extras, sueldo_imponible, sueldo_liquido, costo_empresa)
SELECT
    liquidacion_id,
    empleado_id,
    contrato_id,
    periodo,
    sueldo_base,
    horas_extras,
    sueldo_imponible,
    sueldo_liquido,
    costo_empresa
FROM dbo.Liquidacion;
GO
