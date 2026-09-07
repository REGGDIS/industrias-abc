-- =====================================================================
-- ETL Asistencia 0.1 · Staging (limpieza) · tabla: trabajador
-- Dominio: Control de Asistencia (MySQL) · Responsable: Esteban Osses
--
-- Conserva trabajador_id como identificador local de trazabilidad.
-- El RUT solo se limpia superficialmente aquí; su normalización para
-- homologación con RRHH corresponde al ETL Core.
-- Origen: stg_asistencia_trabajador_raw, poblado por la extracción.
-- =====================================================================

SELECT
    trabajador_id,
    TRIM(rut) AS rut,
    UPPER(TRIM(nombre)) AS nombre,
    UPPER(TRIM(apellido)) AS apellido,
    fecha_ingreso
FROM stg_asistencia_trabajador_raw;
