/* ============================================================================
   load / contrato.sql — Landing RAW
   Dominio:  Contratos y Remuneraciones
   Motor:    SQL Server
   Encargo:  Contratos/Remuneraciones 0.2
   ----------------------------------------------------------------------------
   Materializa la extracción de Contrato (fuente: dbo.Contrato) en una tabla
   RAW física. El staging debe leer desde raw.contratos_remuneraciones_contrato,
   nunca directo desde dbo.Contrato.
   ============================================================================ */
USE ContratosRemuneraciones_ABC;
GO

IF SCHEMA_ID(N'raw') IS NULL EXEC('CREATE SCHEMA raw');
GO

IF OBJECT_ID(N'raw.contratos_remuneraciones_contrato', N'U') IS NULL
BEGIN
    CREATE TABLE raw.contratos_remuneraciones_contrato (
        contrato_id         INT             NULL,
        empleado_id         VARCHAR(10)     NULL,
        numero_contrato     VARCHAR(20)     NULL,
        tipo_contrato       VARCHAR(20)     NULL,
        fecha_inicio        DATE            NULL,
        fecha_termino       DATE            NULL,
        jornada             VARCHAR(30)     NULL,
        sueldo_base         DECIMAL(12,2)   NULL,
        cargo_contrato      VARCHAR(60)     NULL,
        estado              VARCHAR(15)     NULL,
        raw_loaded_at       DATETIME2       NOT NULL
            CONSTRAINT DF_raw_cr_contrato_loaded_at DEFAULT (SYSUTCDATETIME())
    );
END
GO

TRUNCATE TABLE raw.contratos_remuneraciones_contrato;
GO

INSERT INTO raw.contratos_remuneraciones_contrato
    (contrato_id, empleado_id, numero_contrato, tipo_contrato, fecha_inicio,
     fecha_termino, jornada, sueldo_base, cargo_contrato, estado)
SELECT
    contrato_id,
    empleado_id,
    numero_contrato,
    tipo_contrato,
    fecha_inicio,
    fecha_termino,
    jornada,
    sueldo_base,
    cargo_contrato,
    estado
FROM dbo.Contrato;
GO
