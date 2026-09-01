-- =====================================================================
-- ETL Contabilidad 0.1 · Extracción · tabla: areas
-- Dominio: Contabilidad (PostgreSQL) · Responsable: Raymond Civil
--
-- Propósito: extraer areas SIN modificar la fuente (extracción transparente).
-- Columnas explícitas (no SELECT *), con los nombres físicos del schema.sql.
-- Conserva el ID local (area_id) como trazabilidad y la clave de negocio (codigo_area).
-- La limpieza y el tipado se realizan en la etapa de staging.
-- =====================================================================

SELECT
    area_id,
    codigo_area,
    nombre_area
FROM areas;
