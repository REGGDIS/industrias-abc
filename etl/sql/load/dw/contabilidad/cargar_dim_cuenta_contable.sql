INSERT INTO dw.dim_cuenta_contable (
    codigo_cuenta,
    nombre_cuenta,
    tipo_cuenta,
    grupo,
    nivel,
    codigo_cuenta_padre,
    estado
)
VALUES (
    %(codigo_cuenta)s,
    %(nombre_cuenta)s,
    %(tipo_cuenta)s,
    %(grupo)s,
    %(nivel)s,
    %(codigo_cuenta_padre)s,
    %(estado)s
)
ON CONFLICT (codigo_cuenta)
DO UPDATE SET
    nombre_cuenta = EXCLUDED.nombre_cuenta,
    tipo_cuenta = EXCLUDED.tipo_cuenta,
    grupo = EXCLUDED.grupo,
    nivel = EXCLUDED.nivel,
    codigo_cuenta_padre = EXCLUDED.codigo_cuenta_padre,
    estado = EXCLUDED.estado;
