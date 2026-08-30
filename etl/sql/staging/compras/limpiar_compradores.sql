-- =====================================================================
-- ETL Compras 0.1 · Staging (limpieza) · tabla: compradores
-- Dominio: Compras y Abastecimiento (PostgreSQL) · Responsable: Raymond Civil
--
-- Funciones SQL aplicadas en este script (según corresponde a sus campos): TRIM, UPPER.
--   TRIM  = quita espacios sobrantes | UPPER = normaliza a mayúsculas
--   NULLIF(x,'') = cadena vacía -> NULL | CAST = fija el tipo (DATE / NUMERIC)
-- Conserva los IDs locales y las claves de negocio (trazabilidad).
--
-- Origen: stg_compras_compradores_raw = dato RAW poblado por la extracción de compradores.
-- Validación local: esa tabla RAW se materializó como fixture temporal
--   (CREATE TABLE stg_compras_compradores_raw AS <extracción de compradores>) en un PostgreSQL de prueba,
--   y luego se ejecutó este script. El fixture NO forma parte del ETL Core.
-- =====================================================================

SELECT
    comprador_id,                                      -- ID local (se preserva)
    UPPER(TRIM(codigo_comprador))  AS codigo_comprador,-- clave de negocio
    UPPER(TRIM(nombre_comprador))  AS nombre_comprador,
    area_id,                                            -- FK local (se preserva)
    UPPER(TRIM(estado))            AS estado
FROM stg_compras_compradores_raw;
