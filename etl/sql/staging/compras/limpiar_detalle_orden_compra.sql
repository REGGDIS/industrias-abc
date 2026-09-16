-- =====================================================================
-- ETL Compras 0.1 · Staging (limpieza) · tabla: detalle_orden_compra
-- Dominio: Compras y Abastecimiento (PostgreSQL) · Responsable: Raymond Civil
--
-- Funciones SQL aplicadas en este script (según corresponde a sus campos): CAST.
--   TRIM  = quita espacios sobrantes | UPPER = normaliza a mayúsculas
--   NULLIF(x,'') = cadena vacía -> NULL | CAST = fija el tipo (DATE / NUMERIC)
-- Conserva los IDs locales y las claves de negocio (trazabilidad).
--
-- Origen: stg_compras_detalle_orden_compra_raw = dato RAW poblado por la extracción de detalle_orden_compra.
-- Validación local: esa tabla RAW se materializó como fixture temporal
--   (CREATE TABLE stg_compras_detalle_orden_compra_raw AS <extracción de detalle_orden_compra>) en un PostgreSQL de prueba,
--   y luego se ejecutó este script. El fixture NO forma parte del ETL Core.
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
