-- =====================================================================
-- ETL Contabilidad 0.1 · Extracción · tabla: centros_costo
-- Dominio: Contabilidad (PostgreSQL) · Responsable: Raymond Civil
--
-- Propósito: extraer centros_costo SIN modificar la fuente (extracción transparente).
-- Columnas explícitas (no SELECT *), con los nombres físicos del schema.sql.
-- Conserva el ID local (centro_costo_id) como trazabilidad y la clave de negocio (codigo).
-- La limpieza y el tipado se realizan en la etapa de staging.
-- =====================================================================

SELECT
    centro_costo_id,
    codigo,
    nombre,
    area_id,
    responsable,
    estado
FROM centros_costo;
