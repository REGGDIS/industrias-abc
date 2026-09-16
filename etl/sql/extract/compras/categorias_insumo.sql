-- =====================================================================
-- ETL Compras 0.1 · Extracción · tabla: categorias_insumo
-- Dominio: Compras y Abastecimiento (PostgreSQL) · Responsable: Raymond Civil
--
-- Propósito: extraer categorias_insumo SIN modificar la fuente (extracción transparente).
-- Conserva el ID local de origen y la clave de negocio (codigo_categoria)
-- para trazabilidad y futura homologación. La limpieza/tipado va en staging.
-- No aplica transformaciones ni oculta inconsistencias en esta etapa.
-- =====================================================================

SELECT
    categoria_id,
    codigo_categoria,
    nombre_categoria
FROM categorias_insumo;
