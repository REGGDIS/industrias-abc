-- =====================================================================
-- ETL Compras 0.1 · Staging (limpieza) · tabla: recepciones
-- Dominio: Compras y Abastecimiento (PostgreSQL) · Responsable: Raymond Civil
--
-- Funciones SQL aplicadas en este script (según corresponde a sus campos): TRIM, UPPER, CAST.
--   TRIM  = quita espacios sobrantes | UPPER = normaliza a mayúsculas
--   NULLIF(x,'') = cadena vacía -> NULL | CAST = fija el tipo (DATE / NUMERIC)
-- Conserva los IDs locales y las claves de negocio (trazabilidad).
--
-- Origen: stg_compras_recepciones_raw = dato RAW poblado por la extracción de recepciones.
-- Validación local: esa tabla RAW se materializó como fixture temporal
--   (CREATE TABLE stg_compras_recepciones_raw AS <extracción de recepciones>) en un PostgreSQL de prueba,
--   y luego se ejecutó este script. El fixture NO forma parte del ETL Core.
-- =====================================================================

SELECT
    recepcion_id,                                   -- ID local (se preserva)
    oc_id,                                          -- FK local (clave de negocio via numero_oc)
    CAST(fecha_recepcion AS DATE)  AS fecha_recepcion,
    UPPER(TRIM(estado))            AS estado
FROM stg_compras_recepciones_raw;
