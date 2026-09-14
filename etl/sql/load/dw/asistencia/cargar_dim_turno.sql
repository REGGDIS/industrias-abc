-- ============================================================
-- Industrias ABC - Data Warehouse
-- ETL Asistencia - Carga DIM_TURNO
-- Carga parametrizada desde las salidas CLEAN de Asistencia.
-- ============================================================

INSERT INTO dw.dim_turno (
    turno_bk,
    nombre_turno,
    hora_inicio,
    hora_fin,
    horas_jornada
)
VALUES (
    %(turno_bk)s,
    %(nombre_turno)s,
    %(hora_inicio)s,
    %(hora_fin)s,
    %(horas_jornada)s
)
ON CONFLICT (turno_bk) DO UPDATE
SET
    nombre_turno = EXCLUDED.nombre_turno,
    hora_inicio = EXCLUDED.hora_inicio,
    hora_fin = EXCLUDED.hora_fin,
    horas_jornada = EXCLUDED.horas_jornada;
