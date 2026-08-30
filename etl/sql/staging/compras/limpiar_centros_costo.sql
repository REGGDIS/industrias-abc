-- =====================================================================
-- ETL Compras 0.1 · Staging (limpieza) · tabla: centros_costo
-- Dominio: Compras y Abastecimiento (PostgreSQL) · Responsable: Raymond Civil
--
-- Funciones SQL aplicadas en este script (según corresponde a sus campos): TRIM, UPPER.
--   TRIM  = quita espacios sobrantes | UPPER = normaliza a mayúsculas
--   NULLIF(x,'') = cadena vacía -> NULL | CAST = fija el tipo (DATE / NUMERIC)
-- Conserva los IDs locales y las claves de negocio (trazabilidad).
--
-- Origen: stg_compras_centros_costo_raw = dato RAW poblado por la extracción de centros_costo.
-- Validación local: esa tabla RAW se materializó como fixture temporal
--   (CREATE TABLE stg_compras_centros_costo_raw AS <extracción de centros_costo>) en un PostgreSQL de prueba,
--   y luego se ejecutó este script. El fixture NO forma parte del ETL Core.
-- =====================================================================

SELECT
    centro_costo_id,                               -- ID local (se preserva)
    UPPER(TRIM(codigo_centro))  AS codigo_centro,  -- clave de negocio
    UPPER(TRIM(nombre_centro))  AS nombre_centro,
    area_id,                                        -- FK local (se preserva)
    UPPER(TRIM(estado))         AS estado
FROM stg_compras_centros_costo_raw;
