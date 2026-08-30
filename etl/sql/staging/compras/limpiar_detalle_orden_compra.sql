-- =====================================================================
-- ETL Compras 0.1 · Staging (limpieza) · tabla: detalle_orden_compra
-- Dominio: Compras y Abastecimiento (PostgreSQL) · Responsable: Raymond Civil
--
-- Lee el dato RAW (stg_compras_detalle_orden_compra_raw) —poblado por la extracción de detalle_orden_compra—
-- y aplica transformaciones EXPLÍCITAS de preparación para staging:
--   TRIM  = quita espacios sobrantes al inicio/fin
--   UPPER = normaliza el texto a mayúsculas (para comparar/homologar)
--   NULLIF(x,'') = convierte cadena vacía en NULL (dato ausente real)
--   CAST  = fija el tipo (fechas a DATE, montos a NUMERIC)
-- Conserva los IDs locales y las claves de negocio (trazabilidad).
-- =====================================================================

SELECT
    detalle_id,                                            -- ID local (se preserva)
    oc_id,                                                 -- FK local
    insumo_id,                                             -- FK local
    CAST(cantidad         AS NUMERIC(12,2)) AS cantidad,
    CAST(precio_unitario  AS NUMERIC(14,2)) AS precio_unitario,
    CAST(descuento        AS NUMERIC(14,2)) AS descuento,
    CAST(subtotal         AS NUMERIC(14,2)) AS subtotal
FROM stg_compras_detalle_orden_compra_raw;
