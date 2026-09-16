SELECT
    centro_costo_id,
    UPPER(TRIM(codigo_centro_costo)) AS codigo_centro_costo,
    UPPER(TRIM(nombre_centro_costo)) AS nombre_centro_costo
FROM stg_rrhh_centros_costo_raw;