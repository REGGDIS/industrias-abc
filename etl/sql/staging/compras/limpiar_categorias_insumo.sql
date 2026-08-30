-- =====================================================================
-- ETL Compras 0.1 · Staging (limpieza) · tabla: categorias_insumo
-- Dominio: Compras y Abastecimiento (PostgreSQL) · Responsable: Raymond Civil
--
-- Funciones SQL aplicadas en este script (según corresponde a sus campos): TRIM, UPPER.
--   TRIM  = quita espacios sobrantes | UPPER = normaliza a mayúsculas
--   NULLIF(x,'') = cadena vacía -> NULL | CAST = fija el tipo (DATE / NUMERIC)
-- Conserva los IDs locales y las claves de negocio (trazabilidad).
--
-- Origen: stg_compras_categorias_insumo_raw = dato RAW poblado por la extracción de categorias_insumo.
-- Validación local: esa tabla RAW se materializó como fixture temporal
--   (CREATE TABLE stg_compras_categorias_insumo_raw AS <extracción de categorias_insumo>) en un PostgreSQL de prueba,
--   y luego se ejecutó este script. El fixture NO forma parte del ETL Core.
-- =====================================================================

SELECT
    categoria_id,                                        -- ID local (se preserva)
    UPPER(TRIM(codigo_categoria))  AS codigo_categoria,  -- clave de negocio
    UPPER(TRIM(nombre_categoria))  AS nombre_categoria
FROM stg_compras_categorias_insumo_raw;
