INSERT INTO dw.dim_proveedor (
    rut_proveedor_normalizado,
    razon_social,
    nombre_fantasia,
    categoria,
    region,
    comuna,
    estado,
    codigo_proveedor_ref
)
VALUES (
    %(rut_proveedor_normalizado)s,
    %(razon_social)s,
    %(nombre_fantasia)s,
    %(categoria)s,
    %(region)s,
    %(comuna)s,
    %(estado)s,
    %(codigo_proveedor_ref)s
)
ON CONFLICT (rut_proveedor_normalizado)
DO UPDATE SET
    razon_social = EXCLUDED.razon_social,
    nombre_fantasia = EXCLUDED.nombre_fantasia,
    categoria = EXCLUDED.categoria,
    region = EXCLUDED.region,
    comuna = EXCLUDED.comuna,
    estado = EXCLUDED.estado,
    codigo_proveedor_ref = EXCLUDED.codigo_proveedor_ref;
