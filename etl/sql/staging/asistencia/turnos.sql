SELECT
    turno_id,
    UPPER(TRIM(nombre_turno)) AS nombre_turno,
    hora_inicio,
    hora_fin,
    horas_jornada
FROM turnos;