SELECT
    ci.consumo_id,
    ci.orden_produccion_id,
    op.numero_orden,
    ci.insumo_id,
    ci.cantidad_planificada,
    ci.cantidad_consumida,
    ci.fecha_consumo
FROM consumo_insumos ci
INNER JOIN ordenes_produccion op
    ON op.orden_produccion_id = ci.orden_produccion_id
WHERE ci.insumo_id IS NOT NULL
  AND ci.cantidad_planificada >= 0
  AND ci.cantidad_consumida >= 0
  AND ci.fecha_consumo IS NOT NULL
  AND ci.cantidad_consumida <= ci.cantidad_planificada;
