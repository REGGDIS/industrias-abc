-- =====================================================================
-- ETL Compras 0.1 · Extracción · tabla: detalle_orden_compra
-- Dominio: Compras y Abastecimiento (PostgreSQL) · Responsable: Raymond Civil
--
-- Propósito: extraer detalle_orden_compra SIN modificar la fuente (extracción transparente).
-- Conserva el ID local de origen y la clave de negocio (numero_oc + codigo_insumo (vía oc_id/insumo_id))
-- para trazabilidad y futura homologación. La limpieza/tipado va en staging.
-- No aplica transformaciones ni oculta inconsistencias en esta etapa.
-- =====================================================================

SELECT
    detalle_id,
    oc_id,
    insumo_id,
    cantidad,
    precio_unitario,
    descuento,
    subtotal
FROM detalle_orden_compra;
