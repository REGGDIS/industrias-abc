-- =====================================================================
-- ETL Compras 0.1 · Extracción · tabla: insumos
-- Dominio: Compras y Abastecimiento (PostgreSQL) · Responsable: Raymond Civil
--
-- Propósito: extraer insumos SIN modificar la fuente (extracción transparente).
-- Conserva el ID local de origen y la clave de negocio (codigo_insumo)
-- para trazabilidad y futura homologación. La limpieza/tipado va en staging.
-- No aplica transformaciones ni oculta inconsistencias en esta etapa.
-- =====================================================================

SELECT
    insumo_id,
    codigo_insumo,
    nombre_insumo,
    categoria_id,
    unidad_medida,
    stock_minimo,
    estado
FROM insumos;
