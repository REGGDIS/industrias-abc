-- =====================================================================
-- ETL Contabilidad 0.1 · Extracción · tabla: cuentas_contables
-- Dominio: Contabilidad (PostgreSQL) · Responsable: Raymond Civil
--
-- Propósito: extraer cuentas_contables SIN modificar la fuente (extracción transparente).
-- Columnas explícitas (no SELECT *), con los nombres físicos del schema.sql.
-- Conserva el ID local (cuenta_id) como trazabilidad y la clave de negocio (codigo_cuenta).
-- La limpieza y el tipado se realizan en la etapa de staging.
-- =====================================================================

SELECT
    cuenta_id,
    codigo_cuenta,
    nombre_cuenta,
    tipo_cuenta,
    grupo,
    nivel,
    cuenta_padre_id,
    estado
FROM cuentas_contables;
