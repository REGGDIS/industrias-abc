INSERT INTO dw.dim_area (
    codigo_area,
    nombre_area,
    gerencia
)
VALUES (
    %(codigo_area)s,
    %(nombre_area)s,
    %(gerencia)s
)
ON CONFLICT (codigo_area)
DO UPDATE SET
    nombre_area = EXCLUDED.nombre_area,
    gerencia = EXCLUDED.gerencia
WHERE
    dw.dim_area.area_key <> 0
    AND dw.dim_area.codigo_area <> 'DESCONOCIDO'
    AND (
        dw.dim_area.nombre_area
            IS DISTINCT FROM EXCLUDED.nombre_area
        OR
        dw.dim_area.gerencia
            IS DISTINCT FROM EXCLUDED.gerencia
    );