-- =====================================================================
-- ETL Compras 0.2 · Incremental · Detección de UPDATE · recepciones
-- Dominio: Compras (PostgreSQL) · Responsable: Raymond Civil
--
-- Devuelve SOLO las recepciones que CAMBIARON respecto de un snapshot anterior.
-- Igual que en órdenes, el watermark por PK no ve un UPDATE; se compara la
-- fuente actual contra la copia previa con IS DISTINCT FROM (seguro ante NULL).
--
-- tmp_compras_recepciones_snapshot_anterior = FIXTURE LOCAL del prototipo.
--   NO es un estándar del ETL Core.
-- Campos comparados: fecha_recepcion, estado.
-- =====================================================================

SELECT
    actual.recepcion_id,
    actual.oc_id,
    actual.fecha_recepcion   AS fecha_actual,
    anterior.fecha_recepcion AS fecha_anterior,
    actual.estado            AS estado_actual,
    anterior.estado          AS estado_anterior
FROM recepciones actual
JOIN tmp_compras_recepciones_snapshot_anterior anterior
  ON anterior.recepcion_id = actual.recepcion_id
WHERE
       actual.fecha_recepcion IS DISTINCT FROM anterior.fecha_recepcion
    OR actual.estado          IS DISTINCT FROM anterior.estado
ORDER BY actual.recepcion_id;
