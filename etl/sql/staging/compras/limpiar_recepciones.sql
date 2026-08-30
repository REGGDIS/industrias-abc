-- =====================================================================
-- ETL Compras 0.1 · Staging (limpieza) · tabla: recepciones
-- Dominio: Compras y Abastecimiento (PostgreSQL) · Responsable: Raymond Civil
--
-- Lee el dato RAW (stg_compras_recepciones_raw) —poblado por la extracción de recepciones—
-- y aplica transformaciones EXPLÍCITAS de preparación para staging:
--   TRIM  = quita espacios sobrantes al inicio/fin
--   UPPER = normaliza el texto a mayúsculas (para comparar/homologar)
--   NULLIF(x,'') = convierte cadena vacía en NULL (dato ausente real)
--   CAST  = fija el tipo (fechas a DATE, montos a NUMERIC)
-- Conserva los IDs locales y las claves de negocio (trazabilidad).
-- =====================================================================

SELECT
    recepcion_id,                                   -- ID local (se preserva)
    oc_id,                                          -- FK local (clave de negocio via numero_oc)
    CAST(fecha_recepcion AS DATE)  AS fecha_recepcion,
    UPPER(TRIM(estado))            AS estado
FROM stg_compras_recepciones_raw;
