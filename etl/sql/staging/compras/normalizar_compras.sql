-- =====================================================================
--  normalizar_compras.sql
--  ETL Compras 0.4 · Staging/CLEAN · Normalización y Estandarización
--  Proyecto: Business Intelligence - Industrias ABC  (Equipo BInnova)
--  Dominio: Compras   Responsable: Raymond Civil
--  Rama: feat/etl-compras-normalizacion-04   Base: develop   Versión: 0.1
--
--  OBJETIVO
--    Estandarizar valores controlados de Compras (moneda, estados, códigos
--    de negocio y textos) sobre la capa RAW/CLEAN, conservando TRAZABILIDAD
--    (valor_original vs valor_normalizado) y clasificando cada campo como
--    NORMALIZADO / LIMPIO / REVISION / ERROR. NO construye hechos ni
--    dimensiones. Es de SOLO LECTURA: no modifica las tablas operacionales.
--
--  RELACIÓN CON 0.1 (no se duplica)
--    Los limpiar_*.sql de 0.1 ya aplican TRIM/UPPER. Esta capa NO los
--    reescribe: AGREGA la clasificación de dominio y la trazabilidad
--    antes/después que 0.1 no produce.
--
--  ORIGEN
--    Lee de los fixtures RAW stg_compras_<tabla>_raw (poblados por la
--    extracción de 0.1; NO forman parte del ETL Core).
--
--  DOMINIOS (anclados a sources/compras-postgresql/sql/schema.sql)
--    moneda            : CLP, USD, EUR                       (ck_ordenes_compra_moneda)
--    estado OC         : EMITIDA,PARCIAL,RECIBIDA,CERRADA,ANULADA
--    estado prov/insumo: ACTIVO, INACTIVO
--    estado recepción  : REGISTRADA,CONFORME,CON_DIFERENCIAS,ANULADA
--    numero_oc, codigo_insumo : NOT NULL / UNIQUE en el schema (no vacío)
--
--  IDEMPOTENCIA
--    valor_normalizado = UPPER(TRIM(x)) (o TRIM(x) en textos). Ambas son
--    idempotentes: aplicar de nuevo sobre el resultado no lo cambia.
--
--  SALIDA
--    (1) Detalle de trazabilidad : entidad,id_registro,campo,valor_original,valor_normalizado,estado
--    (2) Resumen                 : procesados / normalizados / en_revision / errores
--
--  EJECUTAR (requiere los fixtures RAW materializados):
--    psql "<conn>" -f etl/sql/staging/compras/normalizar_compras.sql
-- =====================================================================

\set ON_ERROR_STOP on

-- Tabla temporal de trabajo (se auto-elimina; no toca nada operacional).
DROP TABLE IF EXISTS tmp_normalizacion_compras;

CREATE TEMP TABLE tmp_normalizacion_compras AS

-- ORDENES · moneda  -> dominio {CLP,USD,EUR}
SELECT 'ordenes_compra'::text AS entidad, oc_id AS id_registro, 'moneda'::text AS campo,
       moneda::text AS valor_original,
       UPPER(TRIM(moneda)) AS valor_normalizado,
       CASE WHEN UPPER(TRIM(moneda)) IN ('CLP','USD','EUR')
            THEN 'NORMALIZADO' ELSE 'REVISION' END AS estado
FROM stg_compras_ordenes_compra_raw

UNION ALL
-- ORDENES · estado  -> dominio de OC
SELECT 'ordenes_compra', oc_id, 'estado', estado::text, UPPER(TRIM(estado)),
       CASE WHEN UPPER(TRIM(estado)) IN ('EMITIDA','PARCIAL','RECIBIDA','CERRADA','ANULADA')
            THEN 'NORMALIZADO' ELSE 'REVISION' END
FROM stg_compras_ordenes_compra_raw

UNION ALL
-- ORDENES · numero_oc  -> clave de negocio, no vacío (TRIM+UPPER)
SELECT 'ordenes_compra', oc_id, 'numero_oc', numero_oc::text, UPPER(TRIM(numero_oc)),
       CASE WHEN NULLIF(TRIM(numero_oc),'') IS NULL THEN 'ERROR' ELSE 'NORMALIZADO' END
FROM stg_compras_ordenes_compra_raw

UNION ALL
-- PROVEEDORES · estado -> dominio {ACTIVO,INACTIVO}
SELECT 'proveedores', proveedor_id, 'estado', estado::text, UPPER(TRIM(estado)),
       CASE WHEN UPPER(TRIM(estado)) IN ('ACTIVO','INACTIVO')
            THEN 'NORMALIZADO' ELSE 'REVISION' END
FROM stg_compras_proveedores_raw

UNION ALL
-- PROVEEDORES · razon_social -> texto descriptivo (solo TRIM)
SELECT 'proveedores', proveedor_id, 'razon_social', razon_social::text, TRIM(razon_social),
       CASE WHEN NULLIF(TRIM(razon_social),'') IS NULL THEN 'REVISION' ELSE 'LIMPIO' END
FROM stg_compras_proveedores_raw

UNION ALL
-- INSUMOS · codigo_insumo -> clave de negocio, no vacío (TRIM+UPPER)
SELECT 'insumos', insumo_id, 'codigo_insumo', codigo_insumo::text, UPPER(TRIM(codigo_insumo)),
       CASE WHEN NULLIF(TRIM(codigo_insumo),'') IS NULL THEN 'ERROR' ELSE 'NORMALIZADO' END
FROM stg_compras_insumos_raw

UNION ALL
-- INSUMOS · estado -> dominio {ACTIVO,INACTIVO}
SELECT 'insumos', insumo_id, 'estado', estado::text, UPPER(TRIM(estado)),
       CASE WHEN UPPER(TRIM(estado)) IN ('ACTIVO','INACTIVO')
            THEN 'NORMALIZADO' ELSE 'REVISION' END
FROM stg_compras_insumos_raw

UNION ALL
-- INSUMOS · nombre_insumo -> texto descriptivo (solo TRIM)
SELECT 'insumos', insumo_id, 'nombre_insumo', nombre_insumo::text, TRIM(nombre_insumo),
       CASE WHEN NULLIF(TRIM(nombre_insumo),'') IS NULL THEN 'REVISION' ELSE 'LIMPIO' END
FROM stg_compras_insumos_raw

UNION ALL
-- RECEPCIONES · estado -> dominio de recepción
SELECT 'recepciones', recepcion_id, 'estado', estado::text, UPPER(TRIM(estado)),
       CASE WHEN UPPER(TRIM(estado)) IN ('REGISTRADA','CONFORME','CON_DIFERENCIAS','ANULADA')
            THEN 'NORMALIZADO' ELSE 'REVISION' END
FROM stg_compras_recepciones_raw
;

-- ---------------------------------------------------------------------
-- (1) DETALLE DE TRAZABILIDAD (muestra lo que cambió o requiere atención)
--     Estados que requieren atención primero; luego cambios reales.
-- ---------------------------------------------------------------------
\echo '=== (1) DETALLE (cambios y/o registros a revisar) ==='
SELECT entidad, id_registro, campo, valor_original, valor_normalizado, estado
FROM tmp_normalizacion_compras
WHERE valor_original IS DISTINCT FROM valor_normalizado
   OR estado IN ('REVISION','ERROR')
ORDER BY CASE estado WHEN 'ERROR' THEN 0 WHEN 'REVISION' THEN 1 ELSE 2 END,
         entidad, id_registro, campo;

-- ---------------------------------------------------------------------
-- (2) RESUMEN procesados / normalizados / en_revision / errores + TOTAL
--     procesados     = campos evaluados (una fila por registro-campo)
--     normalizados   = estado NORMALIZADO o LIMPIO
--     en_revision    = estado REVISION
--     errores        = estado ERROR
--     Se cumple: procesados = normalizados + en_revision + errores
-- ---------------------------------------------------------------------
\echo '=== (2) RESUMEN procesados / normalizados / en_revision / errores ==='
SELECT COALESCE(entidad,'TOTAL') AS entidad,
       COUNT(*)                                                   AS procesados,
       COUNT(*) FILTER (WHERE estado IN ('NORMALIZADO','LIMPIO')) AS normalizados,
       COUNT(*) FILTER (WHERE estado = 'REVISION')                AS en_revision,
       COUNT(*) FILTER (WHERE estado = 'ERROR')                   AS errores
FROM tmp_normalizacion_compras
GROUP BY GROUPING SETS ((entidad), ())
ORDER BY (entidad IS NULL), entidad;

-- Fin de normalizar_compras.sql
