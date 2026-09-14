INSERT INTO dw.dim_contrato (
    numero_contrato,
    empleado_key,
    cargo_key,
    tipo_contrato,
    fecha_inicio,
    fecha_termino,
    jornada,
    sueldo_base_contractual,
    cargo_contrato,
    estado_contrato
)
VALUES (
    %(numero_contrato)s,
    %(empleado_key)s,
    %(cargo_key)s,
    %(tipo_contrato)s,
    %(fecha_inicio)s,
    %(fecha_termino)s,
    %(jornada)s,
    %(sueldo_base_contractual)s,
    %(cargo_contrato)s,
    %(estado_contrato)s
)
ON CONFLICT (numero_contrato) DO UPDATE SET
    empleado_key = EXCLUDED.empleado_key,
    cargo_key = EXCLUDED.cargo_key,
    tipo_contrato = EXCLUDED.tipo_contrato,
    fecha_inicio = EXCLUDED.fecha_inicio,
    fecha_termino = EXCLUDED.fecha_termino,
    jornada = EXCLUDED.jornada,
    sueldo_base_contractual = EXCLUDED.sueldo_base_contractual,
    cargo_contrato = EXCLUDED.cargo_contrato,
    estado_contrato = EXCLUDED.estado_contrato;
