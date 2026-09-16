/* ============================================================================
   extract / contrato.sql
   Dominio:  Contratos y Remuneraciones
   Fuente:   sources/contratos-remuneraciones-sqlserver/sql/schema.sql (dbo.Contrato)
   Motor:    SQL Server
   ----------------------------------------------------------------------------
   Extracción transparente: campos físicos exactos, sin limpieza, sin
   homologación y sin SELECT *. Se conservan contrato_id y empleado_id como
   identificadores locales de trazabilidad.
   ============================================================================ */
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
