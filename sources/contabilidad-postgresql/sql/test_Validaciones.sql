-- =============================================================================
-- INFORME DE PRUEBAS TÉCNICAS: VALIDACIÓN SOURCE-TO-STAGING
-- Dominio: Contabilidad
-- Responsable: Felipe Badilla
-- Rama: test/validacion-etl-contabilidad-01
-- Motor: PostgreSQL
-- =============================================================================

/*
================================================================================
GUÍA DE RESOLUCIÓN DE ERRORES FRECUENTES ANTES DE EJECUTAR:
================================================================================
Si obtienes el error: "ERROR: no existe la relación «stg_contabilidad_...»" (SQL state: 42P01):
Causa: Las vistas o tablas de staging aún no han sido creadas en tu sesión de PostgreSQL.
Solución paso a paso:
1. Abre los 4 scripts de staging ubicados en el repositorio:
   - etl/sql/staging/contabilidad/areas.sql
   - etl/sql/staging/contabilidad/centros_costo.sql
   - etl/sql/staging/contabilidad/cuentas_contables.sql
   - etl/sql/staging/contabilidad/movimientos_contables.sql
2. Ejecútalos creando una vista para cada uno en tu base de datos:
   CREATE OR REPLACE VIEW stg_contabilidad_areas_clean AS <pegar SELECT de areas.sql>;
   CREATE OR REPLACE VIEW stg_contabilidad_centros_costo_clean AS <pegar SELECT de centros_costo.sql>;
   CREATE OR REPLACE VIEW stg_contabilidad_cuentas_contables_clean AS <pegar SELECT de cuentas_contables.sql>;
   CREATE OR REPLACE VIEW stg_contabilidad_movimientos_contables_clean AS <pegar SELECT de movimientos_contables.sql>;
3. Vuelve a ejecutar este script de validación.
================================================================================
*/


-- =============================================================================
-- BLOQUE 1: RECONCILIACIÓN DE CONTEOS (SOURCE vs STAGING)
-- Objetivo: Comprobar que ningún registro se haya perdido en la extracción y limpieza.
-- Criterio de Éxito: cant_source = cant_staging y diferencia = 0.
-- =============================================================================

-- 1.1 Conteos consolidados de las 4 entidades
SELECT 
    'areas' AS entidad,
    (SELECT COUNT(*) FROM areas) AS cant_source,
    (SELECT COUNT(*) FROM stg_contabilidad_areas_clean) AS cant_staging,
    (SELECT COUNT(*) FROM areas) - (SELECT COUNT(*) FROM stg_contabilidad_areas_clean) AS diferencia
UNION ALL
SELECT 
    'centros_costo' AS entidad,
    (SELECT COUNT(*) FROM centros_costo) AS cant_source,
    (SELECT COUNT(*) FROM stg_contabilidad_centros_costo_clean) AS cant_staging,
    (SELECT COUNT(*) FROM centros_costo) - (SELECT COUNT(*) FROM stg_contabilidad_centros_costo_clean) AS diferencia
UNION ALL
SELECT 
    'cuentas_contables' AS entidad,
    (SELECT COUNT(*) FROM cuentas_contables) AS cant_source,
    (SELECT COUNT(*) FROM stg_contabilidad_cuentas_contables_clean) AS cant_staging,
    (SELECT COUNT(*) FROM cuentas_contables) - (SELECT COUNT(*) FROM stg_contabilidad_cuentas_contables_clean) AS diferencia
UNION ALL
SELECT 
    'movimientos_contables' AS entidad,
    (SELECT COUNT(*) FROM movimientos_contables) AS cant_source,
    (SELECT COUNT(*) FROM stg_contabilidad_movimientos_contables_clean) AS cant_staging,
    (SELECT COUNT(*) FROM movimientos_contables) - (SELECT COUNT(*) FROM stg_contabilidad_movimientos_contables_clean) AS diferencia;

/*
Diagnóstico si diferencia <> 0:
- Si faltan registros en staging, revisa si el script de staging tiene un filtro WHERE
  que esté descartando registros indebidamente.
*/


-- =============================================================================
-- BLOQUE 2: RECONCILIACIÓN FINANCIERA Y CUADRATURA CONTABLE
-- Objetivo: Garantizar integridad matemática de Debe y Haber entre fuente y staging.
-- Criterio de Éxito:
--   - diff_debe = 0.00
--   - diff_haber = 0.00
--   - cuadratura_staging = 0.00 (Debe es exactamente igual a Haber)
-- =============================================================================

-- 2.1 Comparación montos globales Source vs Staging
SELECT 
    (SELECT SUM(debe) FROM movimientos_contables) AS source_total_debe,
    (SELECT SUM(debe) FROM stg_contabilidad_movimientos_contables_clean) AS staging_total_debe,
    (SELECT SUM(debe) FROM movimientos_contables) - (SELECT SUM(debe) FROM stg_contabilidad_movimientos_contables_clean) AS diff_debe,
    (SELECT SUM(haber) FROM movimientos_contables) AS source_total_haber,
    (SELECT SUM(haber) FROM stg_contabilidad_movimientos_contables_clean) AS staging_total_haber,
    (SELECT SUM(haber) FROM movimientos_contables) - (SELECT SUM(haber) FROM stg_contabilidad_movimientos_contables_clean) AS diff_haber;

-- 2.2 Verificación de la partida doble en Staging
SELECT 
    SUM(debe) AS total_debe_staging,
    SUM(haber) AS total_haber_staging,
    SUM(debe) - SUM(haber) AS cuadratura_staging,
    CASE 
        WHEN SUM(debe) - SUM(haber) = 0 THEN 'OK: BALANCE CUADRADO'
        ELSE 'ERROR: DESCUADRE CONTABLE'
    END AS estado_cuadratura
FROM stg_contabilidad_movimientos_contables_clean;

/*
Diagnóstico si hay descuadre:
- Verificar si hubo truncamiento de decimales por un CAST erróneo (usar NUMERIC(15,2)).
*/


-- =============================================================================
-- BLOQUE 3: UNICIDAD DE CLAVES DE NEGOCIO EN STAGING
-- Objetivo: Asegurar que no se generen duplicados tras las transformaciones (ej. UPPER/TRIM).
-- Criterio de Éxito: 0 filas devueltas en cada consulta.
-- =============================================================================

-- 3.1 Duplicados en áreas por código
SELECT codigo_area, COUNT(*) AS repeticiones
FROM stg_contabilidad_areas_clean
GROUP BY codigo_area
HAVING COUNT(*) > 1;

-- 3.2 Duplicados en centros de costo por código
SELECT codigo, COUNT(*) AS repeticiones
FROM stg_contabilidad_centros_costo_clean
GROUP BY codigo
HAVING COUNT(*) > 1;

-- 3.3 Duplicados en cuentas contables por código
SELECT codigo_cuenta, COUNT(*) AS repeticiones
FROM stg_contabilidad_cuentas_contables_clean
GROUP BY codigo_cuenta
HAVING COUNT(*) > 1;

/*
Diagnóstico si devuelve filas:
- Existen registros que diferían únicamente en espacios o mayúsculas en la fuente,
  y al aplicar TRIM() o UPPER() colisionaron como duplicados.
*/


-- =============================================================================
-- BLOQUE 4: INTEGRIDAD REFERENCIAL Y RELACIONES
-- Objetivo: Comprobar que no existan registros huérfanos entre entidades.
-- Criterio de Éxito: 0 filas devueltas en cada consulta.
-- =============================================================================

-- 4.1 Movimientos huérfanos de Cuenta Contable
SELECT m.movimiento_id, m.cuenta_id
FROM stg_contabilidad_movimientos_contables_clean m
LEFT JOIN stg_contabilidad_cuentas_contables_clean c ON m.cuenta_id = c.cuenta_id
WHERE c.cuenta_id IS NULL;

-- 4.2 Movimientos huérfanos de Centro de Costo
SELECT m.movimiento_id, m.centro_costo_id
FROM stg_contabilidad_movimientos_contables_clean m
LEFT JOIN stg_contabilidad_centros_costo_clean cc ON m.centro_costo_id = cc.centro_costo_id
WHERE cc.centro_costo_id IS NULL;

-- 4.3 Relación 1:1 entre Área y Centro de Costo (Ningún área debe tener más de 1 centro)
SELECT area_id, COUNT(*) AS total_centros_asociados
FROM stg_contabilidad_centros_costo_clean
GROUP BY area_id
HAVING COUNT(*) > 1;

-- 4.4 Jerarquía de cuentas (Cuentas hijas apuntando a un padre inexistente)
SELECT hijo.cuenta_id, hijo.codigo_cuenta, hijo.cuenta_padre_id
FROM stg_contabilidad_cuentas_contables_clean hijo
LEFT JOIN stg_contabilidad_cuentas_contables_clean padre ON hijo.cuenta_padre_id = padre.cuenta_id
WHERE hijo.cuenta_padre_id IS NOT NULL 
  AND padre.cuenta_id IS NULL;


-- =============================================================================
-- BLOQUE 5: REGLAS DE NEGOCIO Y DOMINIOS
-- Objetivo: Validar la consistencia contable y la normalización de estados y monedas.
-- Criterio de Éxito: 0 filas devueltas en cada consulta.
-- =============================================================================

-- 5.1 Reglas contables obligatorias en movimientos:
--   - Montos no pueden ser negativos.
--   - No pueden ser ambos 0 simultáneamente.
--   - No pueden tener valores mayores a 0 en Debe y Haber a la vez.
--   - tipo_cambio debe ser estrictamente positivo.
SELECT *
FROM stg_contabilidad_movimientos_contables_clean
WHERE debe < 0 
   OR haber < 0 
   OR (debe = 0 AND haber = 0)
   OR (debe > 0 AND haber > 0)
   OR tipo_cambio <= 0;

-- 5.2 Dominio de estado en Centros de Costo (Solo se permite 'ACTIVO' o 'INACTIVO')
SELECT centro_costo_id, codigo, estado
FROM stg_contabilidad_centros_costo_clean
WHERE estado NOT IN ('ACTIVO', 'INACTIVO') OR estado IS NULL;

-- 5.3 Dominio de estado en Cuentas Contables (Solo se permite 'ACTIVA' o 'INACTIVA')
SELECT cuenta_id, codigo_cuenta, estado
FROM stg_contabilidad_cuentas_contables_clean
WHERE estado NOT IN ('ACTIVA', 'INACTIVA') OR estado IS NULL;

-- 5.4 Normalización de Moneda (No vacíos ni con espacios residuales)
SELECT DISTINCT moneda
FROM stg_contabilidad_movimientos_contables_clean
WHERE moneda IS NULL 
   OR LENGTH(moneda) = 0 
   OR moneda <> TRIM(moneda);