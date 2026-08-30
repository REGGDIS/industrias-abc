-- =====================================================================
-- ETL Compras 0.1 · Extracción · tabla: recepciones
-- Dominio: Compras y Abastecimiento (PostgreSQL) · Responsable: Raymond Civil
--
-- Propósito: extraer recepciones SIN modificar la fuente (extracción transparente).
-- Conserva el ID local de origen y la clave de negocio (numero_oc (vía oc_id))
-- para trazabilidad y futura homologación. La limpieza/tipado va en staging.
-- No aplica transformaciones ni oculta inconsistencias en esta etapa.
-- =====================================================================

SELECT
    recepcion_id,
    oc_id,
    fecha_recepcion,
    estado
FROM recepciones;
