SELECT
    orden_produccion_id,
    UPPER(TRIM(numero_orden)) AS numero_orden,
    producto_id,
    fecha_inicio,
    fecha_termino,
    cantidad_planificada,
    cantidad_producida,
    cantidad_rechazada,
    UPPER(TRIM(estado)) AS estado,
    centro_costo_id
FROM ordenes_produccion
WHERE numero_orden IS NOT NULL
  AND TRIM(numero_orden) <> ''
  AND producto_id IS NOT NULL
  AND fecha_inicio IS NOT NULL
  AND cantidad_planificada >= 0
  AND cantidad_producida >= 0
  AND cantidad_rechazada >= 0
  AND cantidad_rechazada <= cantidad_producida
  AND (fecha_termino IS NULL OR fecha_termino >= fecha_inicio);
