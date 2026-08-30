-- =====================================================================
-- ETL Compras 0.1 · Staging (limpieza) · tabla: detalle_recepcion
-- Dominio: Compras y Abastecimiento (PostgreSQL) · Responsable: Raymond Civil
--
-- Lee el dato RAW (stg_compras_detalle_recepcion_raw) —poblado por la extracción de detalle_recepcion—
-- y aplica transformaciones EXPLÍCITAS de preparación para staging:
--   TRIM  = quita espacios sobrantes al inicio/fin
--   UPPER = normaliza el texto a mayúsculas (para comparar/homologar)
--   NULLIF(x,'') = convierte cadena vacía en NULL (dato ausente real)
--   CAST  = fija el tipo (fechas a DATE, montos a NUMERIC)
-- Conserva los IDs locales y las claves de negocio (trazabilidad).
-- =====================================================================

SELECT
    detalle_recepcion_id,                                       -- ID local (se preserva)
    recepcion_id,                                               -- FK local
    detalle_id,                                                 -- FK local
    CAST(cantidad_recibida  AS NUMERIC(12,2)) AS cantidad_recibida,
    CAST(cantidad_rechazada AS NUMERIC(12,2)) AS cantidad_rechazada,
    UPPER(TRIM(estado))                       AS estado
FROM stg_compras_detalle_recepcion_raw;
