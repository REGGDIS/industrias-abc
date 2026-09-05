SELECT
    producto_id,
    UPPER(TRIM(codigo_producto)) AS codigo_producto,
    TRIM(nombre_producto) AS nombre_producto,
    TRIM(categoria) AS categoria,
    UPPER(TRIM(unidad_medida)) AS unidad_medida
FROM productos
WHERE codigo_producto IS NOT NULL
  AND TRIM(codigo_producto) <> ''
  AND nombre_producto IS NOT NULL
  AND TRIM(nombre_producto) <> '';
