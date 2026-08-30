-- =====================================================================
-- ETL Compras 0.1 · Staging (limpieza) · tabla: areas
-- Dominio: Compras y Abastecimiento (PostgreSQL) · Responsable: Raymond Civil
--
-- Funciones SQL aplicadas en este script (según corresponde a sus campos): TRIM, UPPER.
--   TRIM  = quita espacios sobrantes | UPPER = normaliza a mayúsculas
--   NULLIF(x,'') = cadena vacía -> NULL | CAST = fija el tipo (DATE / NUMERIC)
-- Conserva los IDs locales y las claves de negocio (trazabilidad).
--
-- Origen: stg_compras_areas_raw = dato RAW poblado por la extracción de areas.
-- Validación local: esa tabla RAW se materializó como fixture temporal
--   (CREATE TABLE stg_compras_areas_raw AS <extracción de areas>) en un PostgreSQL de prueba,
--   y luego se ejecutó este script. El fixture NO forma parte del ETL Core.
-- =====================================================================

SELECT
    area_id,                                   -- ID local (se preserva)
    UPPER(TRIM(codigo_area))  AS codigo_area,  -- clave de negocio, normalizada
    UPPER(TRIM(nombre_area))  AS nombre_area
FROM stg_compras_areas_raw;
