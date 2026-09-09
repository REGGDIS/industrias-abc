INSERT INTO dw.dim_centro_costo (
    codigo_centro_costo,
    nombre_centro_costo,
    estado
)
VALUES (
    %(codigo_centro_costo)s,
    %(nombre_centro_costo)s,
    NULL
)
ON CONFLICT (codigo_centro_costo)
DO UPDATE SET
    nombre_centro_costo = EXCLUDED.nombre_centro_costo
WHERE
    dw.dim_centro_costo.centro_costo_key <> 0
    AND dw.dim_centro_costo.codigo_centro_costo <> 'DESCONOCIDO'
    AND dw.dim_centro_costo.nombre_centro_costo
        IS DISTINCT FROM EXCLUDED.nombre_centro_costo;
