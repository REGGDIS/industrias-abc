/* ============================================================================
   staging / detalle_liquidacion.sql
   Dominio:  Contratos y Remuneraciones
   ----------------------------------------------------------------------------
   SUPUESTO DE FIXTURE (documentado, no creado en esta tarea):
   Este script asume una tabla RAW/fixture temporal llamada
   stg_contratos_remuneraciones_detalle_liquidacion_raw, con las mismas
   columnas que produce
   etl/sql/extract/contratos_remuneraciones/detalle_liquidacion.sql:
     (detalle_id, liquidacion_id, concepto_id, monto)
   La creación estandarizada de tablas RAW corresponde a ETL Core y NO se
   implementa aquí.
   ----------------------------------------------------------------------------
   Reglas de limpieza aplicadas:
   - No hay campos de texto que limpiar en esta entidad.
   - monto se conserva sin redondeo ni cambio de signo.
   - detalle_id, liquidacion_id y concepto_id se conservan como
     identificadores locales de trazabilidad.
   - No se transforma este detalle en una tabla de hechos todavía (eso es
     responsabilidad de ETL Core).
   ============================================================================ */
SELECT
    detalle_id,
    liquidacion_id,
    concepto_id,
    monto
FROM stg_contratos_remuneraciones_detalle_liquidacion_raw;
