-- =====================================================================
-- ETL Compras 0.2 · Incremental · Detección de INSERT · recepciones
-- Dominio: Compras (PostgreSQL) · Responsable: Raymond Civil
--
-- Devuelve SOLO las recepciones nuevas: recepcion_id mayor al último ID
-- confirmado en una ejecución anterior (watermark técnico por PK).
-- recepcion_id es INTEGER GENERATED ALWAYS AS IDENTITY.
--
-- :ultima_recepcion_id = última recepcion_id procesada anteriormente
--   (parámetro documentado; ETL Core lo persistirá después).
-- No se usa MAX(recepcion_id) interno como sustituto del watermark histórico.
-- Columnas explícitas (sin SELECT *); no modifica la fuente.
-- =====================================================================

SELECT
    recepcion_id,
    oc_id,
    fecha_recepcion,
    estado
FROM recepciones
WHERE recepcion_id > :ultima_recepcion_id
ORDER BY recepcion_id;
