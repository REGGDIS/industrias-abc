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
FROM asistencia;