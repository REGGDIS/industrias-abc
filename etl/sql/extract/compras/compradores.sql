-- =====================================================================
-- ETL Compras 0.1 · Extracción · tabla: compradores
-- Dominio: Compras y Abastecimiento (PostgreSQL) · Responsable: Raymond Civil
--
-- Propósito: extraer compradores SIN modificar la fuente (extracción transparente).
-- Conserva el ID local de origen y la clave de negocio (codigo_comprador)
-- para trazabilidad y futura homologación. La limpieza/tipado va en staging.
-- No aplica transformaciones ni oculta inconsistencias en esta etapa.
-- =====================================================================

SELECT
    comprador_id,
    codigo_comprador,
    nombre_comprador,
    area_id,
    estado
FROM compradores;
