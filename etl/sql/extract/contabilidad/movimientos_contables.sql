-- =====================================================================
-- ETL Contabilidad 0.1 · Extracción · tabla: movimientos_contables
-- Dominio: Contabilidad (PostgreSQL) · Responsable: Raymond Civil
--
-- Propósito: extraer movimientos_contables SIN modificar la fuente (extracción transparente).
-- Columnas explícitas (no SELECT *), con los nombres físicos del schema.sql.
-- Conserva el ID local (movimiento_id) como trazabilidad y la clave de negocio (documento_tipo + documento_numero).
-- La limpieza y el tipado se realizan en la etapa de staging.
-- =====================================================================

SELECT
    movimiento_id,
    fecha,
    cuenta_id,
    centro_costo_id,
    documento_tipo,
    documento_numero,
    descripcion,
    debe,
    haber,
    moneda,
    tipo_cambio
FROM movimientos_contables;
