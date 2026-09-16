DROP TABLE IF EXISTS stg_rrhh_centros_costo_raw;

CREATE TABLE stg_rrhh_centros_costo_raw (
    centro_costo_id INTEGER,
    codigo_centro_costo VARCHAR(50),
    nombre_centro_costo VARCHAR(150)
);