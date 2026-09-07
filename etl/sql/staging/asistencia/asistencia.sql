-- =====================================================================
-- ETL Asistencia 0.1 · Staging (limpieza) · tabla: asistencia
-- Dominio: Control de Asistencia (MySQL) · Responsable: Esteban Osses
--
-- Conserva los IDs locales como trazabilidad. La homologación de trabajador
-- con RRHH se resuelve posteriormente en ETL Core mediante RUT normalizado.
-- Origen: stg_asistencia_asistencia_raw, poblado por la extracción.
-- =====================================================================

SELECT
    asistencia_id,
    trabajador_id,
    turno_id,
    fecha,
    hora_entrada,
    hora_salida,
    horas_trabajadas,
    horas_normales,
    horas_extras,
    atraso_minutos,
    ausentismo,
    UPPER(TRIM(estado)) AS estado
FROM stg_asistencia_asistencia_raw;
