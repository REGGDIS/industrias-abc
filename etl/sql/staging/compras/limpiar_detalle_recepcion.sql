-- =====================================================================
-- ETL Compras 0.1 · Staging (limpieza) · tabla: detalle_recepcion
-- Dominio: Compras y Abastecimiento (PostgreSQL) · Responsable: Raymond Civil
--
-- Funciones SQL aplicadas en este script (según corresponde a sus campos): TRIM, UPPER, CAST.
--   TRIM  = quita espacios sobrantes | UPPER = normaliza a mayúsculas
--   NULLIF(x,'') = cadena vacía -> NULL | CAST = fija el tipo (DATE / NUMERIC)
-- Conserva los IDs locales y las claves de negocio (trazabilidad).
--
-- Origen: stg_compras_detalle_recepcion_raw = dato RAW poblado por la extracción de detalle_recepcion.
-- Validación local: esa tabla RAW se materializó como fixture temporal
--   (CREATE TABLE stg_compras_detalle_recepcion_raw AS <extracción de detalle_recepcion>) en un PostgreSQL de prueba,
--   y luego se ejecutó este script. El fixture NO forma parte del ETL Core.
-- =====================================================================

SELECT
    detalle_recepcion_id,                                       -- ID local (se preserva)
    recepcion_id,                                               -- FK local
    detalle_id,                                                 -- FK local
    CAST(cantidad_recibida  AS NUMERIC(12,2)) AS cantidad_recibida,
    CAST(cantidad_rechazada AS NUMERIC(12,2)) AS cantidad_rechazada,
    UPPER(TRIM(estado))                       AS estado
FROM stg_compras_detalle_recepcion_raw;
