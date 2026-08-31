DROP TABLE IF EXISTS stg_rrhh_cargos_raw;

CREATE TABLE stg_rrhh_cargos_raw (
    cargo_id INTEGER,
    codigo_cargo VARCHAR(50),
    nombre_cargo VARCHAR(150),
    nivel VARCHAR(50),
    sueldo_base_referencial NUMERIC
);