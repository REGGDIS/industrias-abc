WITH empleados_normalizados AS (
    SELECT
        empleado_id,
        REGEXP_REPLACE(
            UPPER(TRIM(rut)),
            '[^0-9K]',
            '',
            'g'
        ) AS rut_limpio,
        nombres,
        apellido_paterno,
        apellido_materno,
        fecha_nacimiento,
        sexo,
        nacionalidad,
        fecha_ingreso,
        fecha_salida,
        area_id,
        cargo_id,
        estado
    FROM stg_rrhh_empleados_raw
)

SELECT
    empleado_id,

    CASE
        WHEN rut_limpio IS NULL OR rut_limpio = '' THEN NULL
        WHEN LENGTH(rut_limpio) < 2 THEN rut_limpio
        ELSE
            LEFT(rut_limpio, LENGTH(rut_limpio) - 1)
            || '-'
            || RIGHT(rut_limpio, 1)
    END AS rut,

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

FROM empleados_normalizados;