SELECT
    consumo_id,
    orden_produccion_id,
    insumo_id,
    cantidad_planificada,
    cantidad_consumida,
    fecha_consumo
FROM consumo_insumos
ORDER BY consumo_id;
