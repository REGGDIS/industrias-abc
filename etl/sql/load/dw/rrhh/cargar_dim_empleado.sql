INSERT INTO dw.dim_empleado (
    rut_normalizado,
    nombres,
    apellido_paterno,
    apellido_materno,
    fecha_nacimiento,
    fecha_ingreso,
    fecha_salida,
    area_key,
    cargo_key,
    centro_costo_key,
    estado_laboral,
    sexo,
    nacionalidad,
    fecha_desde,
    fecha_hasta,
    es_actual,
    contexto_historico_estimado
)
VALUES (
    %(rut_normalizado)s,
    %(nombres)s,
    %(apellido_paterno)s,
    %(apellido_materno)s,
    %(fecha_nacimiento)s,
    %(fecha_ingreso)s,
    %(fecha_salida)s,
    %(area_key)s,
    %(cargo_key)s,
    %(centro_costo_key)s,
    %(estado_laboral)s,
    %(sexo)s,
    %(nacionalidad)s,
    %(fecha_desde)s,
    %(fecha_hasta)s,
    %(es_actual)s,
    %(contexto_historico_estimado)s
)
ON CONFLICT (rut_normalizado, fecha_desde)
DO UPDATE SET
    nombres = EXCLUDED.nombres,
    apellido_paterno = EXCLUDED.apellido_paterno,
    apellido_materno = EXCLUDED.apellido_materno,
    fecha_nacimiento = EXCLUDED.fecha_nacimiento,
    fecha_ingreso = EXCLUDED.fecha_ingreso,
    fecha_salida = EXCLUDED.fecha_salida,
    area_key = EXCLUDED.area_key,
    cargo_key = EXCLUDED.cargo_key,
    centro_costo_key = EXCLUDED.centro_costo_key,
    estado_laboral = EXCLUDED.estado_laboral,
    sexo = EXCLUDED.sexo,
    nacionalidad = EXCLUDED.nacionalidad,
    fecha_hasta = EXCLUDED.fecha_hasta,
    es_actual = EXCLUDED.es_actual,
    contexto_historico_estimado = EXCLUDED.contexto_historico_estimado
WHERE
    dw.dim_empleado.empleado_key <> 0;