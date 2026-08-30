-- =====================================================================
-- ETL Compras 0.1 · Staging (limpieza) · tabla: categorias_insumo
-- Dominio: Compras y Abastecimiento (PostgreSQL) · Responsable: Raymond Civil
--
-- Lee el dato RAW (stg_compras_categorias_insumo_raw) —poblado por la
-- extracción de categorias_insumo— y aplica transformaciones EXPLÍCITAS:
--   TRIM  = quita espacios sobrantes al inicio/fin
--   UPPER = normaliza el texto a mayúsculas (para comparar/homologar)
-- Conserva el ID local y la clave de negocio (codigo_categoria).
-- Nota: script agregado por consistencia con la extracción (10 tablas).
-- =====================================================================

SELECT
    categoria_id,                                    -- ID local (se preserva)
    UPPER(TRIM(codigo_categoria))  AS codigo_categoria,  -- clave de negocio
    UPPER(TRIM(nombre_categoria))  AS nombre_categoria
FROM stg_compras_categorias_insumo_raw;
