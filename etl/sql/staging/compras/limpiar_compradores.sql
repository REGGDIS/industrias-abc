-- =====================================================================
-- ETL Compras 0.1 · Staging (limpieza) · tabla: compradores
-- Dominio: Compras y Abastecimiento (PostgreSQL) · Responsable: Raymond Civil
--
-- Lee el dato RAW (stg_compras_compradores_raw) —poblado por la extracción de compradores—
-- y aplica transformaciones EXPLÍCITAS de preparación para staging:
--   TRIM  = quita espacios sobrantes al inicio/fin
--   UPPER = normaliza el texto a mayúsculas (para comparar/homologar)
--   NULLIF(x,'') = convierte cadena vacía en NULL (dato ausente real)
--   CAST  = fija el tipo (fechas a DATE, montos a NUMERIC)
-- Conserva los IDs locales y las claves de negocio (trazabilidad).
-- =====================================================================

SELECT
    comprador_id,                                      -- ID local (se preserva)
    UPPER(TRIM(codigo_comprador))  AS codigo_comprador,-- clave de negocio
    UPPER(TRIM(nombre_comprador))  AS nombre_comprador,
    area_id,                                            -- FK local (se preserva)
    UPPER(TRIM(estado))            AS estado
FROM stg_compras_compradores_raw;
