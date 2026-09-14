INSERT INTO dw.dim_insumo (
    codigo_insumo,
    nombre_insumo,
    codigo_categoria,
    nombre_categoria,
    unidad_medida,
    stock_minimo,
    estado
)
VALUES (
    %(codigo_insumo)s,
    %(nombre_insumo)s,
    %(codigo_categoria)s,
    %(nombre_categoria)s,
    %(unidad_medida)s,
    %(stock_minimo)s,
    %(estado)s
)
ON CONFLICT (codigo_insumo)
DO UPDATE SET
    nombre_insumo = EXCLUDED.nombre_insumo,
    codigo_categoria = EXCLUDED.codigo_categoria,
    nombre_categoria = EXCLUDED.nombre_categoria,
    unidad_medida = EXCLUDED.unidad_medida,
    stock_minimo = EXCLUDED.stock_minimo,
    estado = EXCLUDED.estado;
