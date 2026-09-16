-- =====================================================================
-- ETL Compras 0.1 · Extracción · tabla: areas
-- Dominio: Compras y Abastecimiento (PostgreSQL) · Responsable: Raymond Civil
--
-- Propósito: extraer areas SIN modificar la fuente (extracción transparente).
-- Conserva el ID local de origen y la clave de negocio (codigo_area)
-- para trazabilidad y futura homologación. La limpieza/tipado va en staging.
-- No aplica transformaciones ni oculta inconsistencias en esta etapa.
-- =====================================================================

SELECT
    area_id,
    codigo_area,
    nombre_area
FROM areas;
