/* ============================================================================
   staging / contrato.sql — CLEAN/STAGING (v0.2)
   Dominio:  Contratos y Remuneraciones
   Motor:    SQL Server
   Encargo:  Contratos/Remuneraciones 0.2
   ----------------------------------------------------------------------------
   Lee desde raw.contratos_remuneraciones_contrato. NO lee directo desde
   dbo.Contrato.
   ----------------------------------------------------------------------------
   Reglas de limpieza aplicadas (superficiales y seguras):
   - LTRIM/RTRIM + UPPER sobre numero_contrato, tipo_contrato, jornada,
     estado.
   - LTRIM/RTRIM sobre cargo_contrato (texto libre, se conserva legible).
   - fecha_inicio / fecha_termino / sueldo_base se conservan sin alterar su
     significado (no se recalculan, no se reformatean).
   - contrato_vencido: columna DERIVADA (no altera 'estado'), en 1 cuando el
     contrato tiene fecha_termino en el pasado pero sigue marcado VIGENTE.
     Es la señal de WARNING que pide el Encargo 0.2 (sección 3): "Contrato
     vencido — debe ser identificable — WARNING o estado derivado". No se
     fuerza el cambio de 'estado' aquí; eso requeriría una decisión de
     negocio fuera del alcance de esta iteración.
   ============================================================================ */
USE ContratosRemuneraciones_ABC;
GO

IF SCHEMA_ID(N'staging') IS NULL EXEC('CREATE SCHEMA staging');
GO

CREATE OR ALTER VIEW staging.contratos_remuneraciones_contrato AS
SELECT
    contrato_id,
    empleado_id,
    UPPER(LTRIM(RTRIM(numero_contrato))) AS numero_contrato,
    UPPER(LTRIM(RTRIM(tipo_contrato)))   AS tipo_contrato,
    fecha_inicio,
    fecha_termino,
    UPPER(LTRIM(RTRIM(jornada)))         AS jornada,
    sueldo_base,
    LTRIM(RTRIM(cargo_contrato))         AS cargo_contrato,
    UPPER(LTRIM(RTRIM(estado)))          AS estado,
    CASE
        WHEN fecha_termino IS NOT NULL
             AND fecha_termino < CAST(SYSUTCDATETIME() AS DATE)
             AND UPPER(LTRIM(RTRIM(estado))) = 'VIGENTE'
        THEN 1 ELSE 0
    END AS contrato_vencido,
    raw_loaded_at
FROM raw.contratos_remuneraciones_contrato;
GO
