-- =====================================================================
-- ETL Compras 0.2 · Incremental · Detección de UPDATE · ordenes_compra
-- Dominio: Compras (PostgreSQL) · Responsable: Raymond Civil
--
-- Devuelve SOLO las órdenes que CAMBIARON respecto de un snapshot anterior.
-- El watermark por PK detecta inserciones, pero NO ve un UPDATE (el oc_id no
-- cambia cuando cambian sus atributos). Se compara la fuente actual contra una
-- copia previa (snapshot) con IS DISTINCT FROM (seguro ante NULL).
--
-- Campos comparados = TODOS los que una orden puede cambiar según el Informe §9:
--   estado, fecha_requerida, centro_costo_id, comprador_id, moneda,
--   subtotal, impuesto, total.
--
-- tmp_compras_ordenes_snapshot_anterior = FIXTURE LOCAL del prototipo. NO es un
--   estándar del ETL Core; el Core definirá luego cómo persistir snapshots.
-- =====================================================================

SELECT
    actual.oc_id,
    actual.numero_oc,
    actual.estado            AS estado_actual,
    anterior.estado          AS estado_anterior,
    actual.fecha_requerida   AS fecha_requerida_actual,
    anterior.fecha_requerida AS fecha_requerida_anterior,
    actual.centro_costo_id   AS centro_costo_actual,
    anterior.centro_costo_id AS centro_costo_anterior,
    actual.comprador_id      AS comprador_actual,
    anterior.comprador_id    AS comprador_anterior,
    actual.moneda            AS moneda_actual,
    anterior.moneda          AS moneda_anterior,
    actual.subtotal          AS subtotal_actual,
    anterior.subtotal        AS subtotal_anterior,
    actual.impuesto          AS impuesto_actual,
    anterior.impuesto        AS impuesto_anterior,
    actual.total             AS total_actual,
    anterior.total           AS total_anterior
FROM ordenes_compra actual
JOIN tmp_compras_ordenes_snapshot_anterior anterior
  ON anterior.oc_id = actual.oc_id
WHERE
       actual.estado          IS DISTINCT FROM anterior.estado
    OR actual.fecha_requerida IS DISTINCT FROM anterior.fecha_requerida
    OR actual.centro_costo_id IS DISTINCT FROM anterior.centro_costo_id
    OR actual.comprador_id    IS DISTINCT FROM anterior.comprador_id
    OR actual.moneda          IS DISTINCT FROM anterior.moneda
    OR actual.subtotal        IS DISTINCT FROM anterior.subtotal
    OR actual.impuesto        IS DISTINCT FROM anterior.impuesto
    OR actual.total           IS DISTINCT FROM anterior.total
ORDER BY actual.oc_id;
