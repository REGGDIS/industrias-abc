/* ============================================================================
   staging / empleado.sql — CLEAN/STAGING (v0.2)
   Dominio:  Contratos y Remuneraciones
   Motor:    SQL Server
   Encargo:  Contratos/Remuneraciones 0.2
   ----------------------------------------------------------------------------
   Lee desde raw.contratos_remuneraciones_empleado (creada por
   etl/sql/load/contratos_remuneraciones/empleado.sql). NO lee directo desde
   dbo.Empleado — cumple el flujo RAW → CLEAN/STAGING exigido por el Encargo
   0.2. Se materializa como VISTA persistente en el esquema staging, para
   que etl/validate/contratos_remuneraciones.py pueda consultarla igual que
   cualquier otra tabla.
   ----------------------------------------------------------------------------
   Reglas de limpieza aplicadas (superficiales y seguras, sin homologar):
   - LTRIM/RTRIM sobre texto.
   - UPPER + NULLIF sobre códigos de área/cargo (cadena vacía → NULL).
   - rut_referencia_normalizado: candidato de homologación (sin puntos ni
     guion, en mayúsculas) — NO es una homologación definitiva con RRHH;
     esa decisión la toma ETL Core.
   - empleado_id se conserva sin cambios, como identificador local de
     trazabilidad.
   - fecha_ingreso_ref se conserva como DATE, sin transformar.
   ============================================================================ */
USE ContratosRemuneraciones_ABC;
GO

IF SCHEMA_ID(N'staging') IS NULL EXEC('CREATE SCHEMA staging');
GO

CREATE OR ALTER VIEW staging.contratos_remuneraciones_empleado AS
SELECT
    empleado_id,
    LTRIM(RTRIM(rut_referencia))                                            AS rut_referencia,
    UPPER(REPLACE(REPLACE(LTRIM(RTRIM(rut_referencia)), '.', ''), '-', '')) AS rut_referencia_normalizado,
    LTRIM(RTRIM(nombre_completo))                                           AS nombre_completo,
    NULLIF(UPPER(LTRIM(RTRIM(codigo_area_ref))), '')                        AS codigo_area_ref,
    NULLIF(UPPER(LTRIM(RTRIM(codigo_cargo_ref))), '')                       AS codigo_cargo_ref,
    fecha_ingreso_ref,
    raw_loaded_at
FROM raw.contratos_remuneraciones_empleado;
GO
