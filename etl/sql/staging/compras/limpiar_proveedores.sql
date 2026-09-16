-- =====================================================================
-- ETL Compras 0.1 · Staging (limpieza) · tabla: proveedores
-- Dominio: Compras y Abastecimiento (PostgreSQL) · Responsable: Raymond Civil
--
-- Funciones SQL aplicadas en este script (según corresponde a sus campos): TRIM, UPPER, NULLIF.
--   TRIM  = quita espacios sobrantes | UPPER = normaliza a mayúsculas
--   NULLIF(x,'') = cadena vacía -> NULL | CAST = fija el tipo (DATE / NUMERIC)
-- Conserva los IDs locales y las claves de negocio (trazabilidad).
--
-- Origen: stg_compras_proveedores_raw = dato RAW poblado por la extracción de proveedores.
-- Validación local: esa tabla RAW se materializó como fixture temporal
--   (CREATE TABLE stg_compras_proveedores_raw AS <extracción de proveedores>) en un PostgreSQL de prueba,
--   y luego se ejecutó este script. El fixture NO forma parte del ETL Core.
-- =====================================================================

SELECT
    proveedor_id,                                            -- ID local (se preserva)
    TRIM(rut_proveedor)                     AS rut_proveedor,-- clave de negocio: TRIM sin alterar formato
    UPPER(TRIM(razon_social))               AS razon_social,
    NULLIF(UPPER(TRIM(nombre_fantasia)),'') AS nombre_fantasia,
    NULLIF(UPPER(TRIM(categoria)),'')       AS categoria,
    NULLIF(UPPER(TRIM(region)),'')          AS region,
    NULLIF(UPPER(TRIM(comuna)),'')          AS comuna,
    UPPER(TRIM(estado))                     AS estado
FROM stg_compras_proveedores_raw;
