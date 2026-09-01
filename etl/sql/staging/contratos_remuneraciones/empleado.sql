/* ============================================================================
   staging / empleado.sql
   Dominio:  Contratos y Remuneraciones
   ----------------------------------------------------------------------------
   SUPUESTO DE FIXTURE (documentado, no creado en esta tarea):
   Este script asume una tabla RAW/fixture temporal llamada
   stg_contratos_remuneraciones_empleado_raw, con las mismas columnas que
   produce etl/sql/extract/contratos_remuneraciones/empleado.sql:
     (empleado_id, rut_referencia, nombre_completo, codigo_area_ref,
      codigo_cargo_ref, fecha_ingreso_ref)
   La creación estandarizada de tablas RAW corresponde a ETL Core y NO se
   implementa aquí.
   ----------------------------------------------------------------------------
   Reglas de limpieza aplicadas (sin homologar, sin inventar equivalencias):
   - LTRIM/RTRIM sobre texto.
   - UPPER sobre códigos que se comparan más adelante (área, cargo).
   - NULLIF para convertir cadenas vacías en NULL.
   - rut_referencia_normalizado: representación candidata sin puntos ni
     guion, en mayúsculas, SOLO para facilitar una futura comparación en
     ETL Core. No implica declarar un match definitivo con RRHH/Asistencia.
   - empleado_id se conserva tal cual, como referencia local del dominio.
   ============================================================================ */
SELECT
    empleado_id,
    LTRIM(RTRIM(rut_referencia))                                            AS rut_referencia,
    UPPER(REPLACE(REPLACE(LTRIM(RTRIM(rut_referencia)), '.', ''), '-', '')) AS rut_referencia_normalizado,
    LTRIM(RTRIM(nombre_completo))                                           AS nombre_completo,
    NULLIF(UPPER(LTRIM(RTRIM(codigo_area_ref))), '')                        AS codigo_area_ref,
    NULLIF(UPPER(LTRIM(RTRIM(codigo_cargo_ref))), '')                       AS codigo_cargo_ref,
    fecha_ingreso_ref
FROM stg_contratos_remuneraciones_empleado_raw;
