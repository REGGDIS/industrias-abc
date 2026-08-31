SELECT
    empleado_id,
    UPPER(TRIM(rut)) AS rut,
    UPPER(TRIM(nombres)) AS nombres,
    UPPER(TRIM(apellido_paterno)) AS apellido_paterno,
    NULLIF(UPPER(TRIM(apellido_materno)), '') AS apellido_materno,
    CAST(fecha_nacimiento AS DATE) AS fecha_nacimiento,
    NULLIF(UPPER(TRIM(sexo)), '') AS sexo,
    NULLIF(UPPER(TRIM(nacionalidad)), '') AS nacionalidad,
    CAST(fecha_ingreso AS DATE) AS fecha_ingreso,
    CAST(fecha_salida AS DATE) AS fecha_salida,
    area_id,
    cargo_id,
    UPPER(TRIM(estado)) AS estado
FROM stg_rrhh_empleados_raw;