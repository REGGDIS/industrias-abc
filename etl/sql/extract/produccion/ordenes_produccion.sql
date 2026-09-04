SELECT
    orden_produccion_id,
    numero_orden,
    producto_id,
    fecha_inicio,
    fecha_termino,
    cantidad_planificada,
    cantidad_producida,
    cantidad_rechazada,
    estado,
    centro_costo_id
FROM ordenes_produccion
ORDER BY orden_produccion_id;
