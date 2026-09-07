-- =====================================================================
-- ETL Asistencia 0.1 · Staging (limpieza) · tabla: turnos
-- Dominio: Control de Asistencia (MySQL) · Responsable: Esteban Osses
--
-- Conserva turno_id como identificador local de trazabilidad y normaliza
-- únicamente el nombre del turno.
-- Origen: stg_asistencia_turnos_raw, poblado por la extracción.
-- =====================================================================

SELECT
    turno_id,
    UPPER(TRIM(nombre_turno)) AS nombre_turno,
    hora_inicio,
    hora_fin,
    horas_jornada
FROM stg_asistencia_turnos_raw;
