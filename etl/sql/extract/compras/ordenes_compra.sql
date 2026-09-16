-- =====================================================================
-- ETL Compras 0.1 · Extracción · tabla: ordenes_compra
-- Dominio: Compras y Abastecimiento (PostgreSQL) · Responsable: Raymond Civil
--
-- Propósito: extraer ordenes_compra SIN modificar la fuente (extracción transparente).
-- Conserva el ID local de origen y la clave de negocio (numero_oc)
-- para trazabilidad y futura homologación. La limpieza/tipado va en staging.
-- No aplica transformaciones ni oculta inconsistencias en esta etapa.
-- =====================================================================

SELECT
    oc_id,
    numero_oc,
    proveedor_id,
    fecha_emision,
    fecha_requerida,
    centro_costo_id,
    comprador_id,
    estado,
    moneda,
    subtotal,
    impuesto,
    total
FROM ordenes_compra;
