-- =====================================================================
-- ETL Compras 0.1 · Staging (limpieza) · tabla: areas
-- Dominio: Compras y Abastecimiento (PostgreSQL) · Responsable: Raymond Civil
--
-- Lee el dato RAW (stg_compras_areas_raw) —poblado por la extracción de areas—
-- y aplica transformaciones EXPLÍCITAS de preparación para staging:
--   TRIM  = quita espacios sobrantes al inicio/fin
--   UPPER = normaliza el texto a mayúsculas (para comparar/homologar)
--   NULLIF(x,'') = convierte cadena vacía en NULL (dato ausente real)
--   CAST  = fija el tipo (fechas a DATE, montos a NUMERIC)
-- Conserva los IDs locales y las claves de negocio (trazabilidad).
-- =====================================================================

SELECT
    area_id,                                   -- ID local (se preserva)
    UPPER(TRIM(codigo_area))  AS codigo_area,  -- clave de negocio, normalizada
    UPPER(TRIM(nombre_area))  AS nombre_area
FROM stg_compras_areas_raw;
