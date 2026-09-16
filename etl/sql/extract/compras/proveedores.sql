-- =====================================================================
-- ETL Compras 0.1 · Extracción · tabla: proveedores
-- Dominio: Compras y Abastecimiento (PostgreSQL) · Responsable: Raymond Civil
--
-- Propósito: extraer proveedores SIN modificar la fuente (extracción transparente).
-- Conserva el ID local de origen y la clave de negocio (rut_proveedor)
-- para trazabilidad y futura homologación. La limpieza/tipado va en staging.
-- No aplica transformaciones ni oculta inconsistencias en esta etapa.
-- =====================================================================

SELECT
    proveedor_id,
    rut_proveedor,
    razon_social,
    nombre_fantasia,
    categoria,
    region,
    comuna,
    estado
FROM proveedores;
