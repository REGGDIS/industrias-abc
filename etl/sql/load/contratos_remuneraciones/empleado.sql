/* ============================================================================
   load / empleado.sql — Landing RAW
   Dominio:  Contratos y Remuneraciones
   Motor:    SQL Server
   Encargo:  Contratos/Remuneraciones 0.2
   ----------------------------------------------------------------------------
   Materializa la extracción de Empleado (misma fuente que
   etl/sql/extract/contratos_remuneraciones/empleado.sql: dbo.Empleado) en
   una tabla RAW física. El staging (etl/sql/staging/contratos_remuneraciones/
   empleado.sql) debe leer desde esta tabla, NUNCA directo desde
   dbo.Empleado, cumpliendo el flujo RAW → CLEAN/STAGING exigido por el
   Encargo 0.2.
   No se limpia ni transforma nada aquí: es una copia cruda con timestamp
   de carga. Reproducible: puede ejecutarse varias veces (TRUNCATE + INSERT).
   ============================================================================ */
USE ContratosRemuneraciones_ABC;
GO

IF SCHEMA_ID(N'raw') IS NULL EXEC('CREATE SCHEMA raw');
GO

IF OBJECT_ID(N'raw.contratos_remuneraciones_empleado', N'U') IS NULL
BEGIN
    CREATE TABLE raw.contratos_remuneraciones_empleado (
        empleado_id         VARCHAR(10)     NULL,
        rut_referencia      VARCHAR(15)     NULL,
        nombre_completo     NVARCHAR(150)   NULL,
        codigo_area_ref     VARCHAR(10)     NULL,
        codigo_cargo_ref    VARCHAR(10)     NULL,
        fecha_ingreso_ref   DATE            NULL,
        raw_loaded_at       DATETIME2       NOT NULL
            CONSTRAINT DF_raw_cr_empleado_loaded_at DEFAULT (SYSUTCDATETIME())
    );
END
GO

TRUNCATE TABLE raw.contratos_remuneraciones_empleado;
GO

INSERT INTO raw.contratos_remuneraciones_empleado
    (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref)
SELECT
    empleado_id,
    rut_referencia,
    nombre_completo,
    codigo_area_ref,
    codigo_cargo_ref,
    fecha_ingreso_ref
FROM dbo.Empleado;
GO
