/* ============================================================================
   staging / liquidacion.sql
   Dominio:  Contratos y Remuneraciones
   ----------------------------------------------------------------------------
   SUPUESTO DE FIXTURE (documentado, no creado en esta tarea):
   Este script asume una tabla RAW/fixture temporal llamada
   stg_contratos_remuneraciones_liquidacion_raw, con las mismas columnas que
   produce etl/sql/extract/contratos_remuneraciones/liquidacion.sql:
     (liquidacion_id, empleado_id, contrato_id, periodo, sueldo_base,
      horas_extras, sueldo_imponible, sueldo_liquido, costo_empresa)
   La creación estandarizada de tablas RAW corresponde a ETL Core y NO se
   implementa aquí.
   ----------------------------------------------------------------------------
   Reglas de limpieza aplicadas (sin recalcular montos):
   - LTRIM/RTRIM sobre periodo, sin alterar la semántica YYYY-MM (no se
     reformatea ni se separa en año/mes; eso corresponde a una futura
     dimensión de tiempo en ETL Core).
   - Todos los montos y horas extra se conservan en su precisión original;
     no se recalcula sueldo_imponible, sueldo_liquido ni costo_empresa aquí.
   - liquidacion_id, empleado_id y contrato_id se conservan como
     identificadores locales de trazabilidad.
   ============================================================================ */
SELECT
    liquidacion_id,
    empleado_id,
    contrato_id,
    LTRIM(RTRIM(periodo)) AS periodo,
    sueldo_base,
    horas_extras,
    sueldo_imponible,
    sueldo_liquido,
    costo_empresa
FROM stg_contratos_remuneraciones_liquidacion_raw;
