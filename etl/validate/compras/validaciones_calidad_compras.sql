-- =====================================================================
--  validaciones_calidad_compras.sql
--  ETL Compras 0.3 - Validaciones de Calidad de Datos (transaccional)
--  Proyecto: Business Intelligence - Industrias ABC  (Equipo BInnova)
--  Dominio: Compras   Responsable: Raymond Civil
--  Rama: feat/etl-compras-calidad-03   Base: develop   Version: 0.1
--
--  OBJETIVO
--    Dejar el dominio Compras (ordenes, detalles, recepciones) confiable de
--    cara a una futura FACT_COMPRAS. NO construye hechos ni dimensiones.
--    Es de SOLO LECTURA (SELECT): no modifica datos operacionales.
--
--  FORMULAS ANCLADAS AL MODELO REAL (schema.sql / validaciones.sql):
--    - Subtotal de linea : ROUND(cantidad*precio_unitario - descuento, 2)              (B6)
--    - Cabecera          : total = subtotal + impuesto ; impuesto = ROUND(subtotal*0.19,2) (B7)
--    - Solicitado vs recibido : SUM(cantidad_recibida + cantidad_rechazada) por detalle_id (B5/C7)
--
--  REGLA ANTI-MULTIPLICACION
--    Las recepciones se AGREGAN por detalle_id en una subconsulta ANTES de
--    unirse al detalle de la orden. Asi la cantidad solicitada se lee una sola
--    vez por linea y ningun JOIN la multiplica.
--
--  SALIDA
--    (1) Detalle de incidencias : entidad, id_registro, regla, severidad, motivo
--    (2) Resumen               : procesados / validos / en_revision / con_error
--
--  SEVERIDAD (vocabulario controlado)
--    ERROR    -> incumple una regla dura; bloquea el registro para el DW.
--    REVISION -> diferencia legitima a revisar por el equipo (no bloquea).
--
--  EJECUTAR
--    psql "<conn>" -f etl/validate/compras/validaciones_calidad_compras.sql
-- =====================================================================

\set ON_ERROR_STOP on

-- Tabla temporal de trabajo (se auto-elimina al cerrar la sesion; no toca
-- ninguna tabla operacional). El DROP inicial permite re-ejecutar el script.
DROP TABLE IF EXISTS tmp_calidad_incidencias;

CREATE TEMP TABLE tmp_calidad_incidencias (
    entidad     TEXT    NOT NULL,
    id_registro INTEGER NOT NULL,
    regla       TEXT    NOT NULL,
    severidad   TEXT    NOT NULL,
    motivo      TEXT    NOT NULL
);

-- ---------------------------------------------------------------------
-- Carga de incidencias: una fila por registro que incumple una regla.
-- Cada bloque del UNION ALL implementa exactamente una regla del encargo.
-- ---------------------------------------------------------------------
INSERT INTO tmp_calidad_incidencias (entidad, id_registro, regla, severidad, motivo)

-- R01  Cantidad > 0                                             [ERROR]
SELECT 'detalle_orden_compra', detalle_id, 'CANTIDAD_POSITIVA', 'ERROR',
       'cantidad=' || cantidad || ' (debe ser > 0)'
FROM detalle_orden_compra
WHERE cantidad <= 0

UNION ALL
-- R02  Precio unitario >= 0                                     [ERROR]
SELECT 'detalle_orden_compra', detalle_id, 'PRECIO_NO_NEGATIVO', 'ERROR',
       'precio_unitario=' || precio_unitario || ' (debe ser >= 0)'
FROM detalle_orden_compra
WHERE precio_unitario < 0

UNION ALL
-- R03  Descuento >= 0                                           [ERROR]
SELECT 'detalle_orden_compra', detalle_id, 'DESCUENTO_NO_NEGATIVO', 'ERROR',
       'descuento=' || descuento || ' (debe ser >= 0)'
FROM detalle_orden_compra
WHERE descuento < 0

UNION ALL
-- R04  Subtotal de linea coherente = ROUND(cantidad*precio - descuento, 2)  (B6)  [ERROR]
SELECT 'detalle_orden_compra', detalle_id, 'SUBTOTAL_LINEA_COHERENTE', 'ERROR',
       'subtotal=' || subtotal
       || ' esperado=' || ROUND(cantidad * precio_unitario - descuento, 2)
FROM detalle_orden_compra
WHERE subtotal <> ROUND(cantidad * precio_unitario - descuento, 2)

UNION ALL
-- R05  El detalle pertenece a una orden existente (sin huerfanos)  [ERROR]
SELECT 'detalle_orden_compra', d.detalle_id, 'DETALLE_PERTENECE_ORDEN', 'ERROR',
       'oc_id=' || d.oc_id || ' no existe en ordenes_compra'
FROM detalle_orden_compra d
WHERE NOT EXISTS (SELECT 1 FROM ordenes_compra o WHERE o.oc_id = d.oc_id)

UNION ALL
-- R06  El insumo del detalle existe                             [ERROR]
SELECT 'detalle_orden_compra', d.detalle_id, 'INSUMO_EXISTE', 'ERROR',
       'insumo_id=' || d.insumo_id || ' no existe en insumos'
FROM detalle_orden_compra d
WHERE NOT EXISTS (SELECT 1 FROM insumos i WHERE i.insumo_id = d.insumo_id)

UNION ALL
-- R07  Proveedor valido (existente) en la cabecera de la orden  [ERROR]
SELECT 'ordenes_compra', o.oc_id, 'PROVEEDOR_VALIDO', 'ERROR',
       'proveedor_id=' || o.proveedor_id || ' no existe en proveedores'
FROM ordenes_compra o
WHERE NOT EXISTS (SELECT 1 FROM proveedores p WHERE p.proveedor_id = o.proveedor_id)

UNION ALL
-- R08  Cabecera coherente: total = subtotal + impuesto ; impuesto = ROUND(subtotal*0.19,2)  (B7)  [REVISION]
SELECT 'ordenes_compra', oc_id, 'CABECERA_COHERENTE', 'REVISION',
       'total=' || total || ' subtotal=' || subtotal || ' impuesto=' || impuesto
       || ' | esperado_total=' || (subtotal + impuesto)
       || ' esperado_iva=' || ROUND(subtotal * 0.19, 2)
FROM ordenes_compra
WHERE total <> subtotal + impuesto
   OR impuesto <> ROUND(subtotal * 0.19, 2)

UNION ALL
-- R09a  Recepcion (cabecera) sin orden existente                [ERROR]
SELECT 'recepciones', r.recepcion_id, 'RECEPCION_SIN_ORDEN', 'ERROR',
       'oc_id=' || r.oc_id || ' no existe en ordenes_compra'
FROM recepciones r
WHERE NOT EXISTS (SELECT 1 FROM ordenes_compra o WHERE o.oc_id = r.oc_id)

UNION ALL
-- R09b  Detalle de recepcion sin recepcion cabecera             [ERROR]
SELECT 'detalle_recepcion', dr.detalle_recepcion_id, 'DETREC_SIN_RECEPCION', 'ERROR',
       'recepcion_id=' || dr.recepcion_id || ' no existe en recepciones'
FROM detalle_recepcion dr
WHERE NOT EXISTS (SELECT 1 FROM recepciones r WHERE r.recepcion_id = dr.recepcion_id)

UNION ALL
-- R09c  Detalle de recepcion sin linea de orden                 [ERROR]
SELECT 'detalle_recepcion', dr.detalle_recepcion_id, 'DETREC_SIN_DETALLE', 'ERROR',
       'detalle_id=' || dr.detalle_id || ' no existe en detalle_orden_compra'
FROM detalle_recepcion dr
WHERE NOT EXISTS (SELECT 1 FROM detalle_orden_compra d WHERE d.detalle_id = dr.detalle_id)

UNION ALL
-- R09d  Recepcion apuntando a una linea de OTRA orden  (B8)      [ERROR]
SELECT 'detalle_recepcion', dr.detalle_recepcion_id, 'DETREC_LINEA_OTRA_ORDEN', 'ERROR',
       'la recepcion pertenece a una OC distinta a la de la linea del detalle'
FROM detalle_recepcion dr
JOIN recepciones r          ON r.recepcion_id = dr.recepcion_id
JOIN detalle_orden_compra d ON d.detalle_id  = dr.detalle_id
WHERE r.oc_id <> d.oc_id

UNION ALL
-- R10  Solicitado vs recibido por detalle_id (agrega ANTES del join)  [REVISION]
--      Solo se evaluan lineas que YA tienen recepciones; una linea sin
--      recepciones esta "pendiente" y es un estado legitimo (no se marca).
SELECT 'detalle_orden_compra', d.detalle_id, 'SOLICITADO_VS_RECIBIDO', 'REVISION',
       'solicitado=' || d.cantidad || ' recepcionado=' || rec.recepcionado
       || CASE WHEN rec.recepcionado > d.cantidad THEN ' (EXCESO)' ELSE ' (FALTANTE)' END
FROM detalle_orden_compra d
JOIN (
        SELECT detalle_id,
               SUM(cantidad_recibida + cantidad_rechazada) AS recepcionado
        FROM detalle_recepcion
        GROUP BY detalle_id
     ) rec ON rec.detalle_id = d.detalle_id
WHERE rec.recepcionado <> d.cantidad
;

-- ---------------------------------------------------------------------
-- (1) DETALLE DE INCIDENCIAS  (ERROR primero, luego por entidad e id)
-- ---------------------------------------------------------------------
\echo '=== (1) DETALLE DE INCIDENCIAS ==='
SELECT entidad, id_registro, regla, severidad, motivo
FROM tmp_calidad_incidencias
ORDER BY CASE severidad WHEN 'ERROR' THEN 0 ELSE 1 END,
         entidad, id_registro, regla;

-- ---------------------------------------------------------------------
-- (2) RESUMEN procesados / validos / en_revision / con_error + TOTAL
--     procesados = filas de la entidad
--     validos    = procesados - registros con ALGUNA incidencia
--     en_revision / con_error = registros distintos por severidad
--     (un registro con ERROR y REVISION cuenta en ambas columnas de
--      severidad, pero una sola vez como "no valido")
-- ---------------------------------------------------------------------
\echo '=== (2) RESUMEN PROCESADOS / VALIDOS / ERRORES ==='
WITH universo AS (
    SELECT 'ordenes_compra'       AS entidad, COUNT(*) AS procesados FROM ordenes_compra
    UNION ALL SELECT 'detalle_orden_compra', COUNT(*) FROM detalle_orden_compra
    UNION ALL SELECT 'recepciones',          COUNT(*) FROM recepciones
    UNION ALL SELECT 'detalle_recepcion',    COUNT(*) FROM detalle_recepcion
),
agg AS (
    SELECT entidad,
           COUNT(DISTINCT id_registro) FILTER (WHERE severidad = 'ERROR')    AS ids_error,
           COUNT(DISTINCT id_registro) FILTER (WHERE severidad = 'REVISION') AS ids_revision,
           COUNT(DISTINCT id_registro)                                        AS ids_con_incidencia
    FROM tmp_calidad_incidencias
    GROUP BY entidad
)
SELECT COALESCE(u.entidad, 'TOTAL')                                   AS entidad,
       SUM(u.procesados)                                              AS procesados,
       SUM(u.procesados - COALESCE(a.ids_con_incidencia, 0))          AS validos,
       SUM(COALESCE(a.ids_revision, 0))                               AS en_revision,
       SUM(COALESCE(a.ids_error, 0))                                  AS con_error
FROM universo u
LEFT JOIN agg a ON a.entidad = u.entidad
GROUP BY GROUPING SETS ((u.entidad), ())
ORDER BY (u.entidad IS NULL), u.entidad;

-- Fin de validaciones_calidad_compras.sql
