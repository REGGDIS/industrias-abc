DROP TABLE IF EXISTS stg_rrhh_areas_raw;

CREATE TABLE stg_rrhh_areas_raw (
    area_id INTEGER,
    codigo_area VARCHAR(50),
    nombre_area VARCHAR(150),
    gerencia VARCHAR(150),
    centro_costo_id INTEGER
);