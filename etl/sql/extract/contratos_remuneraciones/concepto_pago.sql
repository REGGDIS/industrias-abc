/* ============================================================================
   extract / concepto_pago.sql
   Dominio:  Contratos y Remuneraciones
   Fuente:   sources/contratos-remuneraciones-sqlserver/sql/schema.sql (dbo.ConceptoPago)
   Motor:    SQL Server
   ----------------------------------------------------------------------------
   Extracción transparente: campos físicos exactos, sin limpieza, sin
   homologación y sin SELECT *. Se conserva concepto_id como identificador
   local de trazabilidad.
   ============================================================================ */
SELECT
    concepto_id,
    codigo,
    descripcion,
    tipo,
    afecta_imponible
FROM dbo.ConceptoPago;
