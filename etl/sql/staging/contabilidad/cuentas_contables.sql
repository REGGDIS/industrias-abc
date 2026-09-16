-- =====================================================================
-- ETL Contabilidad 0.1 · Staging (limpieza) · tabla: cuentas_contables
-- Dominio: Contabilidad (PostgreSQL) · Responsable: Raymond Civil
--
-- Funciones SQL aplicadas (según corresponde a sus campos): TRIM, UPPER.
--   TRIM = quita espacios | UPPER = normaliza códigos/estados/moneda/categóricos
--   NULLIF(x,'') = cadena vacía -> NULL | CAST = estabiliza tipo (DATE)
-- No altera la semántica contable: debe/haber/tipo_cambio se mantienen numéricos
-- (sin redondear ni convertir moneda) y cuenta_padre_id se conserva (no se
-- reconstruye la jerarquía). IDs locales se conservan como trazabilidad.
--
-- Origen: stg_contabilidad_cuentas_contables_raw = dato RAW poblado por la extracción de cuentas_contables.
-- Validación local: la tabla RAW se materializó como fixture temporal
--   (CREATE TABLE stg_contabilidad_cuentas_contables_raw AS <extracción de cuentas_contables>) en un PostgreSQL de prueba;
--   el fixture NO forma parte del ETL Core.
-- =====================================================================

SELECT
    cuenta_id,                                    -- ID local (trazabilidad)
    UPPER(TRIM(codigo_cuenta)) AS codigo_cuenta,  -- clave de negocio, normalizada
    TRIM(nombre_cuenta)        AS nombre_cuenta,
    UPPER(TRIM(tipo_cuenta))   AS tipo_cuenta,    -- categórico
    UPPER(TRIM(grupo))         AS grupo,          -- categórico
    nivel,                                         -- numérico, se conserva
    cuenta_padre_id,                               -- se conserva (no reconstruir jerarquía)
    UPPER(TRIM(estado))        AS estado           -- dominio ACTIVA/INACTIVA
FROM stg_contabilidad_cuentas_contables_raw;
