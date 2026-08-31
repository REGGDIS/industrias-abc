SELECT
    cargo_id,
    UPPER(TRIM(codigo_cargo)) AS codigo_cargo,
    UPPER(TRIM(nombre_cargo)) AS nombre_cargo,
    NULLIF(UPPER(TRIM(nivel)), '') AS nivel,
    sueldo_base_referencial
FROM stg_rrhh_cargos_raw;