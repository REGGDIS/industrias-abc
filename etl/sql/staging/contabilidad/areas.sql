-- =====================================================================
-- ETL Contabilidad 0.1 · Staging (limpieza) · tabla: areas
-- Dominio: Contabilidad (PostgreSQL) · Responsable: Raymond Civil
--
-- Funciones SQL aplicadas (según corresponde a sus campos): TRIM, UPPER.
--   TRIM = quita espacios | UPPER = normaliza códigos/estados/moneda/categóricos
--   NULLIF(x,'') = cadena vacía -> NULL | CAST = estabiliza tipo (DATE)
-- No altera la semántica contable: debe/haber/tipo_cambio se mantienen numéricos
-- (sin redondear ni convertir moneda) y cuenta_padre_id se conserva (no se
-- reconstruye la jerarquía). IDs locales se conservan como trazabilidad.
--
-- Origen: stg_contabilidad_areas_raw = dato RAW poblado por la extracción de areas.
-- Validación local: la tabla RAW se materializó como fixture temporal
--   (CREATE TABLE stg_contabilidad_areas_raw AS <extracción de areas>) en un PostgreSQL de prueba;
--   el fixture NO forma parte del ETL Core.
-- =====================================================================

SELECT
    area_id,                                  -- ID local (trazabilidad)
    UPPER(TRIM(codigo_area)) AS codigo_area,  -- clave de negocio, normalizada
    TRIM(nombre_area)        AS nombre_area
FROM stg_contabilidad_areas_raw;
