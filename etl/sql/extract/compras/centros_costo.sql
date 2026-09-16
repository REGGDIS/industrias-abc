-- =====================================================================
-- ETL Compras 0.1 · Extracción · tabla: centros_costo
-- Dominio: Compras y Abastecimiento (PostgreSQL) · Responsable: Raymond Civil
--
-- Propósito: extraer centros_costo SIN modificar la fuente (extracción transparente).
-- Conserva el ID local de origen y la clave de negocio (codigo_centro)
-- para trazabilidad y futura homologación. La limpieza/tipado va en staging.
-- No aplica transformaciones ni oculta inconsistencias en esta etapa.
-- =====================================================================

SELECT
    centro_costo_id,
    codigo_centro,
    nombre_centro,
    area_id,
    estado
FROM centros_costo;
