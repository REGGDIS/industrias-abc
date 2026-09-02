-- =====================================================================
-- ETL Compras 0.2 · Incremental · Detección de INSERT · ordenes_compra
-- Dominio: Compras (PostgreSQL) · Responsable: Raymond Civil
--
-- Devuelve SOLO las órdenes nuevas: las que tienen oc_id mayor al último
-- ID confirmado como procesado en una ejecución anterior (watermark técnico).
-- oc_id es INTEGER GENERATED ALWAYS AS IDENTITY (creciente), por eso sirve
-- como marca incremental para detectar inserciones.
--
-- :ultimo_oc_id  = último oc_id procesado por una ejecución anterior.
--   (En este prototipo es un PARÁMETRO documentado; ETL Core lo persistirá
--    después por fuente, entidad y ejecución. NO se usa MAX(oc_id) interno,
--    porque eso no distingue lo ya procesado de lo nuevo.)
-- Columnas explícitas (sin SELECT *); no modifica la fuente.
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
FROM ordenes_compra
WHERE oc_id > :ultimo_oc_id
ORDER BY oc_id;
