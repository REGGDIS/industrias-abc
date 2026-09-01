/* ============================================================================
   staging / concepto_pago.sql
   Dominio:  Contratos y Remuneraciones
   ----------------------------------------------------------------------------
   SUPUESTO DE FIXTURE (documentado, no creado en esta tarea):
   Este script asume una tabla RAW/fixture temporal llamada
   stg_contratos_remuneraciones_concepto_pago_raw, con las mismas columnas
   que produce etl/sql/extract/contratos_remuneraciones/concepto_pago.sql:
     (concepto_id, codigo, descripcion, tipo, afecta_imponible)
   La creación estandarizada de tablas RAW corresponde a ETL Core y NO se
   implementa aquí.
   ----------------------------------------------------------------------------
   Reglas de limpieza aplicadas (sin homologar con catálogos externos):
   - LTRIM/RTRIM + UPPER sobre codigo y tipo (se compararán más adelante).
   - LTRIM/RTRIM sobre descripcion, sin alterar su significado ni mayúsculas
     (es texto legible para reportes, no un código de comparación).
   - afecta_imponible se conserva como BIT (0/1), sin transformar.
   - concepto_id se conserva como identificador local.
   ============================================================================ */
SELECT
    concepto_id,
    UPPER(LTRIM(RTRIM(codigo))) AS codigo,
    LTRIM(RTRIM(descripcion))   AS descripcion,
    UPPER(LTRIM(RTRIM(tipo)))   AS tipo,
    afecta_imponible
FROM stg_contratos_remuneraciones_concepto_pago_raw;
