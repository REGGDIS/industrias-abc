/* ============================================================================
   staging / contrato.sql
   Dominio:  Contratos y Remuneraciones
   ----------------------------------------------------------------------------
   SUPUESTO DE FIXTURE (documentado, no creado en esta tarea):
   Este script asume una tabla RAW/fixture temporal llamada
   stg_contratos_remuneraciones_contrato_raw, con las mismas columnas que
   produce etl/sql/extract/contratos_remuneraciones/contrato.sql:
     (contrato_id, empleado_id, numero_contrato, tipo_contrato, fecha_inicio,
      fecha_termino, jornada, sueldo_base, cargo_contrato, estado)
   La creación estandarizada de tablas RAW corresponde a ETL Core y NO se
   implementa aquí.
   ----------------------------------------------------------------------------
   Reglas de limpieza aplicadas (sin recalcular montos, sin homologar):
   - LTRIM/RTRIM + UPPER sobre numero_contrato, tipo_contrato, jornada,
     estado (se compararán/filtrarán más adelante).
   - LTRIM/RTRIM sobre cargo_contrato (texto libre, no se fuerza mayúscula
     para no perder legibilidad del nombre de cargo).
   - fecha_inicio / fecha_termino se conservan como DATE, sin transformar.
   - sueldo_base se conserva sin redondear ni recalcular.
   - contrato_id y empleado_id se conservan como identificadores locales.
   ============================================================================ */
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
    UPPER(LTRIM(RTRIM(estado)))          AS estado
FROM stg_contratos_remuneraciones_contrato_raw;
