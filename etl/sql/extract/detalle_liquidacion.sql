/* ============================================================================
   extract / detalle_liquidacion.sql
   Dominio:  Contratos y Remuneraciones
   Fuente:   sources/contratos-remuneraciones-sqlserver/sql/schema.sql (dbo.DetalleLiquidacion)
   Motor:    SQL Server
   ----------------------------------------------------------------------------
   Extracción transparente: campos físicos exactos, sin limpieza, sin
   homologación y sin SELECT *. Se conservan detalle_id, liquidacion_id y
   concepto_id como identificadores locales de trazabilidad. monto se
   conserva sin redondeo ni cambio de signo.
   ============================================================================ */
SELECT
    detalle_id,
    liquidacion_id,
    concepto_id,
    monto
FROM dbo.DetalleLiquidacion;
