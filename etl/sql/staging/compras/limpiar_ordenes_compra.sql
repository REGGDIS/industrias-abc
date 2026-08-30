-- =====================================================================
-- ETL Compras 0.1 · Staging (limpieza) · tabla: ordenes_compra
-- Dominio: Compras y Abastecimiento (PostgreSQL) · Responsable: Raymond Civil
--
-- Lee el dato RAW (stg_compras_ordenes_compra_raw) —poblado por la extracción de ordenes_compra—
-- y aplica transformaciones EXPLÍCITAS de preparación para staging:
--   TRIM  = quita espacios sobrantes al inicio/fin
--   UPPER = normaliza el texto a mayúsculas (para comparar/homologar)
--   NULLIF(x,'') = convierte cadena vacía en NULL (dato ausente real)
--   CAST  = fija el tipo (fechas a DATE, montos a NUMERIC)
-- Conserva los IDs locales y las claves de negocio (trazabilidad).
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
