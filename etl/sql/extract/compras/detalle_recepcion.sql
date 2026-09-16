-- =====================================================================
-- ETL Compras 0.1 · Extracción · tabla: detalle_recepcion
-- Dominio: Compras y Abastecimiento (PostgreSQL) · Responsable: Raymond Civil
--
-- Propósito: extraer detalle_recepcion SIN modificar la fuente (extracción transparente).
-- Conserva el ID local de origen y la clave de negocio (numero_oc + linea (vía recepcion_id/detalle_id))
-- para trazabilidad y futura homologación. La limpieza/tipado va en staging.
-- No aplica transformaciones ni oculta inconsistencias en esta etapa.
-- =====================================================================

SELECT
    detalle_recepcion_id,
    recepcion_id,
    detalle_id,
    cantidad_recibida,
    cantidad_rechazada,
    estado
FROM detalle_recepcion;
