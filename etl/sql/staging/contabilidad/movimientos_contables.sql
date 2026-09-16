-- =====================================================================
-- ETL Contabilidad 0.1 · Staging (limpieza) · tabla: movimientos_contables
-- Dominio: Contabilidad (PostgreSQL) · Responsable: Raymond Civil
--
-- Funciones SQL aplicadas (según corresponde a sus campos): TRIM, UPPER, CAST.
--   TRIM = quita espacios | UPPER = normaliza códigos/estados/moneda/categóricos
--   NULLIF(x,'') = cadena vacía -> NULL | CAST = estabiliza tipo (DATE)
-- No altera la semántica contable: debe/haber/tipo_cambio se mantienen numéricos
-- (sin redondear ni convertir moneda) y cuenta_padre_id se conserva (no se
-- reconstruye la jerarquía). IDs locales se conservan como trazabilidad.
--
-- Origen: stg_contabilidad_movimientos_contables_raw = dato RAW poblado por la extracción de movimientos_contables.
-- Validación local: la tabla RAW se materializó como fixture temporal
--   (CREATE TABLE stg_contabilidad_movimientos_contables_raw AS <extracción de movimientos_contables>) en un PostgreSQL de prueba;
--   el fixture NO forma parte del ETL Core.
-- =====================================================================

SELECT
    movimiento_id,                                -- ID local (trazabilidad)
    CAST(fecha AS DATE)         AS fecha,         -- estabiliza tipo
    cuenta_id,                                     -- FK local (referencia)
    centro_costo_id,                               -- FK local (referencia)
    UPPER(TRIM(documento_tipo)) AS documento_tipo, -- categórico
    TRIM(documento_numero)      AS documento_numero,
    TRIM(descripcion)           AS descripcion,
    debe,                                          -- numérico: NO redondear ni convertir
    haber,                                         -- numérico: NO redondear ni convertir
    UPPER(TRIM(moneda))         AS moneda,         -- dominio de moneda
    tipo_cambio                                    -- numérico: se conserva
FROM stg_contabilidad_movimientos_contables_raw;
