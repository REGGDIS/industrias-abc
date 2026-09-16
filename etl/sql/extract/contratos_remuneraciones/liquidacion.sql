/* ============================================================================
   extract / liquidacion.sql
   Dominio:  Contratos y Remuneraciones
   Fuente:   sources/contratos-remuneraciones-sqlserver/sql/schema.sql (dbo.Liquidacion)
   Motor:    SQL Server
   ----------------------------------------------------------------------------
   Extracción transparente: campos físicos exactos, sin limpieza, sin
   homologación y sin SELECT *. Se conservan liquidacion_id, empleado_id y
   contrato_id como identificadores locales de trazabilidad. No se recalcula
   sueldo_imponible, sueldo_liquido ni costo_empresa en esta etapa.
   ============================================================================ */
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
