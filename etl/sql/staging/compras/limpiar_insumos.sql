-- =====================================================================
-- ETL Compras 0.1 · Staging (limpieza) · tabla: insumos
-- Dominio: Compras y Abastecimiento (PostgreSQL) · Responsable: Raymond Civil
--
-- Lee el dato RAW (stg_compras_insumos_raw) —poblado por la extracción de insumos—
-- y aplica transformaciones EXPLÍCITAS de preparación para staging:
--   TRIM  = quita espacios sobrantes al inicio/fin
--   UPPER = normaliza el texto a mayúsculas (para comparar/homologar)
--   NULLIF(x,'') = convierte cadena vacía en NULL (dato ausente real)
--   CAST  = fija el tipo (fechas a DATE, montos a NUMERIC)
-- Conserva los IDs locales y las claves de negocio (trazabilidad).
-- =====================================================================

SELECT
    insumo_id,                                       -- ID local (se preserva)
    UPPER(TRIM(codigo_insumo))    AS codigo_insumo,  -- clave de negocio
    UPPER(TRIM(nombre_insumo))    AS nombre_insumo,
    categoria_id,                                     -- FK local (se preserva)
    NULLIF(UPPER(TRIM(unidad_medida)),'') AS unidad_medida,
    stock_minimo,                                     -- ya es numerico en origen
    UPPER(TRIM(estado))           AS estado
FROM stg_compras_insumos_raw;
