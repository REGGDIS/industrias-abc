-- =============================================================================
-- SISTEMA OPERACIONAL DE CONTABILIDAD — INDUSTRIAS ABC
-- Motor: PostgreSQL
-- Archivo: validaciones.sql
-- Ubicación: sources/contabilidad-postgresql/sql/validaciones.sql
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1. CONTEOS GENERALES POR TABLA
-- -----------------------------------------------------------------------------

SELECT 'areas' AS tabla, COUNT(*) AS total_registros FROM areas

UNION ALL

SELECT 'centros_costo', COUNT(*) FROM centros_costo

UNION ALL

SELECT 'cuentas_contables', COUNT(*) FROM cuentas_contables

UNION ALL

SELECT 'movimientos_contables', COUNT(*) FROM movimientos_contables;


-- -----------------------------------------------------------------------------
-- 2. CONTROL DE DUPLICADOS EN CÓDIGOS ÚNICOS (Deben retornar 0 filas)
-- -----------------------------------------------------------------------------

-- 2.1 Duplicados en áreas

SELECT codigo_area, COUNT(*) AS repeticiones
FROM areas
GROUP BY codigo_area
HAVING COUNT(*) > 1;


-- 2.2 Duplicados en centros de costo

SELECT codigo, COUNT(*) AS repeticiones
FROM centros_costo
GROUP BY codigo
HAVING COUNT(*) > 1;


-- 2.3 Duplicados en plan de cuentas

SELECT codigo_cuenta, COUNT(*) AS repeticiones
FROM cuentas_contables
GROUP BY codigo_cuenta
HAVING COUNT(*) > 1;


-- -----------------------------------------------------------------------------
-- 3. DETECCIÓN DE NULOS EN CAMPOS OBLIGATORIOS
-- Todas las pruebas deben retornar 0 fallos.
-- -----------------------------------------------------------------------------

SELECT 'areas_nulos' AS prueba, COUNT(*) AS fallos
FROM areas
WHERE area_id IS NULL
   OR codigo_area IS NULL
   OR nombre_area IS NULL

UNION ALL

SELECT 'centros_costo_nulos', COUNT(*)
FROM centros_costo
WHERE centro_costo_id IS NULL
   OR codigo IS NULL
   OR nombre IS NULL
   OR area_id IS NULL
   OR estado IS NULL

UNION ALL

SELECT 'cuentas_contables_nulos', COUNT(*)
FROM cuentas_contables
WHERE cuenta_id IS NULL
   OR codigo_cuenta IS NULL
   OR nombre_cuenta IS NULL
   OR tipo_cuenta IS NULL
   OR grupo IS NULL
   OR nivel IS NULL
   OR estado IS NULL

UNION ALL

SELECT 'movimientos_contables_nulos', COUNT(*)
FROM movimientos_contables
WHERE movimiento_id IS NULL
   OR fecha IS NULL
   OR cuenta_id IS NULL
   OR centro_costo_id IS NULL
   OR documento_tipo IS NULL
   OR documento_numero IS NULL
   OR descripcion IS NULL
   OR debe IS NULL
   OR haber IS NULL
   OR moneda IS NULL
   OR tipo_cambio IS NULL;


-- -----------------------------------------------------------------------------
-- 4. VALIDACIÓN DE RELACIONES HUÉRFANAS / INTEGRIDAD REFERENCIAL
-- -----------------------------------------------------------------------------

-- 4.1 Movimientos apuntando a cuentas inexistentes
-- Debe retornar 0 filas.

SELECT m.movimiento_id, m.cuenta_id
FROM movimientos_contables m
LEFT JOIN cuentas_contables c
    ON m.cuenta_id = c.cuenta_id
WHERE c.cuenta_id IS NULL;


-- 4.2 Movimientos apuntando a centros de costo inexistentes
-- Debe retornar 0 filas.

SELECT m.movimiento_id, m.centro_costo_id
FROM movimientos_contables m
LEFT JOIN centros_costo cc
    ON m.centro_costo_id = cc.centro_costo_id
WHERE cc.centro_costo_id IS NULL;


-- 4.3 Vista de la relación 1:1 entre Áreas y Centros de Costo

SELECT
    a.codigo_area,
    a.nombre_area,
    cc.codigo AS codigo_centro_costo,
    cc.nombre AS nombre_centro_costo,
    cc.responsable,
    cc.estado
FROM areas a
LEFT JOIN centros_costo cc
    ON a.area_id = cc.area_id
ORDER BY a.codigo_area;


-- 4.4 Áreas sin centro de costo asociado
-- Debe retornar 0 filas para el Universo Empresarial utilizado.

SELECT
    a.area_id,
    a.codigo_area,
    a.nombre_area
FROM areas a
LEFT JOIN centros_costo cc
    ON a.area_id = cc.area_id
WHERE cc.centro_costo_id IS NULL;


-- 4.5 Más de un centro de costo asociado a una misma área
-- Debe retornar 0 filas.

SELECT
    area_id,
    COUNT(*) AS cantidad_centros
FROM centros_costo
GROUP BY area_id
HAVING COUNT(*) > 1;


-- -----------------------------------------------------------------------------
-- 5. REGLAS DE NEGOCIO: PLAN DE CUENTAS
-- -----------------------------------------------------------------------------

-- 5.1 Cuentas hijas con cuenta_padre_id inexistente
-- Debe retornar 0 filas.

SELECT
    c.cuenta_id,
    c.codigo_cuenta,
    c.cuenta_padre_id
FROM cuentas_contables c
WHERE c.cuenta_padre_id IS NOT NULL
  AND c.cuenta_padre_id NOT IN (
      SELECT cuenta_id
      FROM cuentas_contables
  );


-- 5.2 Vista de la jerarquía completa del plan contable

SELECT
    c.nivel,
    c.codigo_cuenta,
    c.nombre_cuenta,
    c.tipo_cuenta,
    c.estado,
    COALESCE(
        p.codigo_cuenta || ' - ' || p.nombre_cuenta,
        '(RAÍZ)'
    ) AS cuenta_padre
FROM cuentas_contables c
LEFT JOIN cuentas_contables p
    ON c.cuenta_padre_id = p.cuenta_id
ORDER BY c.codigo_cuenta;


-- -----------------------------------------------------------------------------
-- 6. REGLAS DE NEGOCIO: MOVIMIENTOS CONTABLES
-- DEBE / HABER / TIPO DE CAMBIO
-- -----------------------------------------------------------------------------

-- 6.1 Movimientos con montos negativos, ambos en cero,
-- ambos positivos o tipo de cambio inválido.
-- Debe retornar 0 filas.

SELECT *
FROM movimientos_contables
WHERE debe < 0
   OR haber < 0
   OR (debe = 0 AND haber = 0)
   OR (debe > 0 AND haber > 0)
   OR tipo_cambio <= 0;


-- 6.2 Cuadratura contable global de los datos de prueba
-- Se valida Total Debe vs Total Haber de la fuente completa.

SELECT
    SUM(debe) AS total_debe,
    SUM(haber) AS total_haber,
    (SUM(debe) - SUM(haber)) AS diferencia_balance,
    CASE
        WHEN (SUM(debe) - SUM(haber)) = 0 THEN 'CUADRADO'
        ELSE 'DESCUADRADO'
    END AS estado_balance
FROM movimientos_contables;


-- -----------------------------------------------------------------------------
-- 7. TOTALES Y RESÚMENES RELEVANTES DEL DOMINIO
-- -----------------------------------------------------------------------------

-- 7.1 Distribución de montos por Tipo y Grupo de Cuenta

SELECT
    c.tipo_cuenta,
    c.grupo,
    COUNT(m.movimiento_id) AS cantidad_movimientos,
    SUM(m.debe) AS total_debe,
    SUM(m.haber) AS total_haber,
    SUM(m.debe - m.haber) AS saldo_neto
FROM cuentas_contables c
JOIN movimientos_contables m
    ON c.cuenta_id = m.cuenta_id
GROUP BY
    c.tipo_cuenta,
    c.grupo
ORDER BY
    c.tipo_cuenta,
    c.grupo;


-- 7.2 Imputación de movimientos por Centro de Costo

SELECT
    cc.codigo AS centro_costo,
    cc.nombre AS nombre_centro_costo,
    COUNT(m.movimiento_id) AS total_movimientos,
    SUM(m.debe) AS total_debe,
    SUM(m.haber) AS total_haber
FROM centros_costo cc
LEFT JOIN movimientos_contables m
    ON cc.centro_costo_id = m.centro_costo_id
GROUP BY
    cc.codigo,
    cc.nombre
ORDER BY
    cc.codigo;