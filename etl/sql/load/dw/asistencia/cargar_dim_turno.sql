-- ============================================================
-- Industrias ABC - Data Warehouse
-- ETL Asistencia - Carga DIM_TURNO
-- ============================================================

INSERT INTO dw.dim_turno (
    turno_bk,
    nombre_turno,
    hora_inicio,
    hora_fin,
    horas_jornada
)
SELECT DISTINCT
    UPPER(TRIM(nombre_turno))
        || '|'
        || hora_inicio::TEXT
        || '|'
        || hora_fin::TEXT AS turno_bk,
    UPPER(TRIM(nombre_turno)) AS nombre_turno,
    hora_inicio,
    hora_fin,
    horas_jornada
FROM stg_asistencia_turnos_clean
WHERE turno_id IS NOT NULL
  AND nombre_turno IS NOT NULL
  AND TRIM(nombre_turno) <> ''
  AND hora_inicio IS NOT NULL
  AND hora_fin IS NOT NULL
  AND horas_jornada > 0
ON CONFLICT (turno_bk) DO UPDATE
SET
    nombre_turno = EXCLUDED.nombre_turno,
    hora_inicio = EXCLUDED.hora_inicio,
    hora_fin = EXCLUDED.hora_fin,
    horas_jornada = EXCLUDED.horas_jornada;