-- =====================================================================
-- ETL Compras 0.1 · Staging (limpieza) · tabla: insumos
-- Dominio: Compras y Abastecimiento (PostgreSQL) · Responsable: Raymond Civil
--
-- Funciones SQL aplicadas en este script (según corresponde a sus campos): TRIM, UPPER, NULLIF.
--   TRIM  = quita espacios sobrantes | UPPER = normaliza a mayúsculas
--   NULLIF(x,'') = cadena vacía -> NULL | CAST = fija el tipo (DATE / NUMERIC)
-- Conserva los IDs locales y las claves de negocio (trazabilidad).
--
-- Origen: stg_compras_insumos_raw = dato RAW poblado por la extracción de insumos.
-- Validación local: esa tabla RAW se materializó como fixture temporal
--   (CREATE TABLE stg_compras_insumos_raw AS <extracción de insumos>) en un PostgreSQL de prueba,
--   y luego se ejecutó este script. El fixture NO forma parte del ETL Core.
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
