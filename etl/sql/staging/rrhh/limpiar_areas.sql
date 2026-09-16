SELECT
    area_id,
    UPPER(TRIM(codigo_area)) AS codigo_area,
    UPPER(TRIM(nombre_area)) AS nombre_area,
    NULLIF(UPPER(TRIM(gerencia)), '') AS gerencia,
    centro_costo_id
FROM stg_rrhh_areas_raw;