-- =====================================================================
-- ETL Contabilidad 0.1 · Staging (limpieza) · tabla: centros_costo
-- Dominio: Contabilidad (PostgreSQL) · Responsable: Raymond Civil
--
-- Funciones SQL aplicadas (según corresponde a sus campos): TRIM, UPPER, NULLIF.
--   TRIM = quita espacios | UPPER = normaliza códigos/estados/moneda/categóricos
--   NULLIF(x,'') = cadena vacía -> NULL | CAST = estabiliza tipo (DATE)
-- No altera la semántica contable: debe/haber/tipo_cambio se mantienen numéricos
-- (sin redondear ni convertir moneda) y cuenta_padre_id se conserva (no se
-- reconstruye la jerarquía). IDs locales se conservan como trazabilidad.
--
-- Origen: stg_contabilidad_centros_costo_raw = dato RAW poblado por la extracción de centros_costo.
-- Validación local: la tabla RAW se materializó como fixture temporal
--   (CREATE TABLE stg_contabilidad_centros_costo_raw AS <extracción de centros_costo>) en un PostgreSQL de prueba;
--   el fixture NO forma parte del ETL Core.
-- =====================================================================

SELECT
    centro_costo_id,                           -- ID local (trazabilidad)
    UPPER(TRIM(codigo))  AS codigo,            -- clave de negocio, normalizada
    TRIM(nombre)         AS nombre,
    area_id,                                    -- FK local (referencia, se conserva)
    NULLIF(TRIM(responsable), '') AS responsable,  -- opcional: vacío -> NULL
    UPPER(TRIM(estado))  AS estado              -- dominio ACTIVO/INACTIVO
FROM stg_contabilidad_centros_costo_raw;
