-- =====================================================================
-- ETL Compras 0.1 · Staging (limpieza) · tabla: proveedores
-- Dominio: Compras y Abastecimiento (PostgreSQL) · Responsable: Raymond Civil
--
-- Lee el dato RAW (stg_compras_proveedores_raw) —poblado por la extracción de proveedores—
-- y aplica transformaciones EXPLÍCITAS de preparación para staging:
--   TRIM  = quita espacios sobrantes al inicio/fin
--   UPPER = normaliza el texto a mayúsculas (para comparar/homologar)
--   NULLIF(x,'') = convierte cadena vacía en NULL (dato ausente real)
--   CAST  = fija el tipo (fechas a DATE, montos a NUMERIC)
-- Conserva los IDs locales y las claves de negocio (trazabilidad).
-- NULLIF se usa en campos opcionales (fantasia/categoria/region/comuna) para que un vacío sea NULL.
-- =====================================================================

SELECT
    proveedor_id,                                            -- ID local (se preserva)
    TRIM(rut_proveedor)                     AS rut_proveedor,-- clave de negocio: se limpia SIN alterar formato
    UPPER(TRIM(razon_social))               AS razon_social,
    NULLIF(UPPER(TRIM(nombre_fantasia)),'') AS nombre_fantasia,
    NULLIF(UPPER(TRIM(categoria)),'')       AS categoria,
    NULLIF(UPPER(TRIM(region)),'')          AS region,
    NULLIF(UPPER(TRIM(comuna)),'')          AS comuna,
    UPPER(TRIM(estado))                     AS estado
FROM stg_compras_proveedores_raw;
