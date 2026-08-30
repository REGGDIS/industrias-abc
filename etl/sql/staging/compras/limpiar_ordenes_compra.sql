-- =====================================================================
-- ETL Compras 0.1 · Staging (limpieza) · tabla: ordenes_compra
-- Dominio: Compras y Abastecimiento (PostgreSQL) · Responsable: Raymond Civil
--
-- Funciones SQL aplicadas en este script (según corresponde a sus campos): TRIM, UPPER, CAST.
--   TRIM  = quita espacios sobrantes | UPPER = normaliza a mayúsculas
--   NULLIF(x,'') = cadena vacía -> NULL | CAST = fija el tipo (DATE / NUMERIC)
-- Conserva los IDs locales y las claves de negocio (trazabilidad).
--
-- Origen: stg_compras_ordenes_compra_raw = dato RAW poblado por la extracción de ordenes_compra.
-- Validación local: esa tabla RAW se materializó como fixture temporal
--   (CREATE TABLE stg_compras_ordenes_compra_raw AS <extracción de ordenes_compra>) en un PostgreSQL de prueba,
--   y luego se ejecutó este script. El fixture NO forma parte del ETL Core.
-- =====================================================================

SELECT
    oc_id,                                              -- ID local (se preserva)
    TRIM(numero_oc)                     AS numero_oc,   -- clave de negocio
    proveedor_id,                                        -- FK local
    CAST(fecha_emision  AS DATE)        AS fecha_emision,
    CAST(fecha_requerida AS DATE)       AS fecha_requerida,
    centro_costo_id,                                     -- FK local
    comprador_id,                                        -- FK local
    UPPER(TRIM(estado))                 AS estado,
    UPPER(TRIM(moneda))                 AS moneda,
    CAST(subtotal  AS NUMERIC(14,2))    AS subtotal,
    CAST(impuesto  AS NUMERIC(14,2))    AS impuesto,
    CAST(total     AS NUMERIC(14,2))    AS total
FROM stg_compras_ordenes_compra_raw;
