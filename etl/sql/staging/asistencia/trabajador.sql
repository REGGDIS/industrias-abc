SELECT
    trabajador_id,
    TRIM(rut) AS rut,
    UPPER(TRIM(nombre)) AS nombre,
    UPPER(TRIM(apellido)) AS apellido,
    fecha_ingreso
FROM trabajador;