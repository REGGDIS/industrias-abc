INSERT INTO dw.dim_cargo (
    codigo_cargo,
    nombre_cargo,
    nivel,
    sueldo_base_referencial
)
VALUES (
    %(codigo_cargo)s,
    %(nombre_cargo)s,
    %(nivel)s,
    %(sueldo_base_referencial)s
)
ON CONFLICT (codigo_cargo)
DO UPDATE SET
    nombre_cargo = EXCLUDED.nombre_cargo,
    nivel = EXCLUDED.nivel,
    sueldo_base_referencial = EXCLUDED.sueldo_base_referencial
WHERE
    dw.dim_cargo.cargo_key <> 0
    AND dw.dim_cargo.codigo_cargo <> 'DESCONOCIDO'
    AND (
        dw.dim_cargo.nombre_cargo
            IS DISTINCT FROM EXCLUDED.nombre_cargo
        OR
        dw.dim_cargo.nivel
            IS DISTINCT FROM EXCLUDED.nivel
        OR
        dw.dim_cargo.sueldo_base_referencial
            IS DISTINCT FROM EXCLUDED.sueldo_base_referencial
    );