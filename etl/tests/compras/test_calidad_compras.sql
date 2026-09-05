-- =====================================================================
--  test_calidad_compras.sql
--  ETL Compras 0.3 - Pruebas reproducibles de las validaciones de calidad
--  Proyecto: Business Intelligence - Industrias ABC  (Equipo BInnova)
--  Dominio: Compras   Responsable: Raymond Civil
--  Rama: feat/etl-compras-calidad-03   Base: develop   Version: 0.1
--
--  QUE PRUEBA
--    Que cada regla de validaciones_calidad_compras.sql DETECTA lo que debe.
--
--  POR QUE USA TABLAS TEMPORALES (no las operacionales)
--    El esquema operacional ya impide estos errores por CHECK / FK / TRIGGER
--    (p. ej. no deja insertar cantidad<=0 ni una recepcion mayor a lo pedido).
--    Por eso, para PROBAR la deteccion, se cargan los mismos datos en tablas
--    de staging SIN esas restricciones -que es justo la capa donde el ETL
--    recibe datos crudos- y se aplican los MISMOS predicados de la validacion.
--
--  SEGURIDAD
--    Todo corre dentro de una transaccion con ROLLBACK y sobre tablas TEMP:
--    no modifica el seed ni ninguna tabla operacional.
--
--  EJECUTAR
--    psql "<conn>" -f etl/tests/compras/test_calidad_compras.sql
-- =====================================================================

\set ON_ERROR_STOP on
BEGIN;

-- ---------------------------------------------------------------------
-- 1) Catalogos de referencia (para las reglas de existencia)
--    Proveedores validos: 1,2   |   Insumos validos: 1,2
-- ---------------------------------------------------------------------
CREATE TEMP TABLE t_proveedores (proveedor_id INT) ON COMMIT DROP;
INSERT INTO t_proveedores VALUES (1),(2);

CREATE TEMP TABLE t_insumos (insumo_id INT) ON COMMIT DROP;
INSERT INTO t_insumos VALUES (1),(2);

-- ---------------------------------------------------------------------
-- 2) Staging SIN restricciones (mismas columnas que el modelo real)
-- ---------------------------------------------------------------------
CREATE TEMP TABLE t_ordenes (
    oc_id INT, proveedor_id INT, subtotal NUMERIC, impuesto NUMERIC, total NUMERIC
) ON COMMIT DROP;

CREATE TEMP TABLE t_detalle (
    detalle_id INT, oc_id INT, insumo_id INT,
    cantidad NUMERIC, precio_unitario NUMERIC, descuento NUMERIC, subtotal NUMERIC
) ON COMMIT DROP;

CREATE TEMP TABLE t_recep (
    recepcion_id INT, oc_id INT
) ON COMMIT DROP;

CREATE TEMP TABLE t_detrec (
    detalle_recepcion_id INT, recepcion_id INT, detalle_id INT,
    cantidad_recibida NUMERIC, cantidad_rechazada NUMERIC
) ON COMMIT DROP;

-- ---------------------------------------------------------------------
-- 3) Fixtures con casos conocidos (validos + un error por regla)
-- ---------------------------------------------------------------------
-- Ordenes:  oc1 valida | oc2 proveedor inexistente | oc3 cabecera incoherente | oc4 valida (para R09d)
INSERT INTO t_ordenes (oc_id, proveedor_id, subtotal, impuesto, total) VALUES
    (1,  1, 1000, 190, 1190),   -- valida: 1000+190=1190 ; iva=round(1000*0.19,2)=190
    (2, 99,  500,  95,  595),   -- R07: proveedor 99 no existe
    (3,  1, 1000, 100, 1100),   -- R08: iva deberia ser 190, no 100
    (4,  1,  100,  19,  119);   -- valida (soporte para R09d)

-- Detalles (subtotal ya "coherente" salvo el caso que prueba R04)
INSERT INTO t_detalle (detalle_id, oc_id, insumo_id, cantidad, precio_unitario, descuento, subtotal) VALUES
    ( 1, 1, 1,  10, 100,  0, 1000),  -- valido (0 incidencias)
    ( 2, 1, 1,   0,  50,  0,    0),  -- R01: cantidad <= 0
    ( 3, 1, 2,   5, -20,  0, -100),  -- R02: precio < 0 (subtotal coherente para aislar)
    ( 4, 1, 1,   5,  20,-10,  110),  -- R03: descuento < 0
    ( 5, 1, 2,   4,  25,  0,  999),  -- R04: subtotal incoherente (esperado 100)
    ( 6,77, 1,   3,  10,  0,   30),  -- R05: oc 77 no existe
    ( 7, 1,88,   2,  10,  0,   20),  -- R06: insumo 88 no existe
    ( 8, 1, 1,  10,  10,  0,  100),  -- R10 FALTANTE (recibe 8 de 10)
    ( 9, 1, 2,   5,  10,  0,   50),  -- R10 EXCESO   (recibe 7 de 5)
    (10, 1, 1,   6,  10,  0,   60),  -- control: recibe 6 de 6 -> 0 incidencias
    (11, 1, 1,  12,  10,  0,  120),  -- R10 + anti-multiplicacion (2 recepciones: 5+4=9)
    (12, 4, 1,   5,  10,  0,   50);  -- soporte R09d (pertenece a oc4)

-- Recepciones: rec1/rec2 de oc1 | rec50 huerfana (oc 12345 no existe)
INSERT INTO t_recep (recepcion_id, oc_id) VALUES
    (1, 1), (2, 1), (50, 12345);

-- Detalle de recepcion
INSERT INTO t_detrec (detalle_recepcion_id, recepcion_id, detalle_id, cantidad_recibida, cantidad_rechazada) VALUES
    (101,   1,  8, 8, 0),   -- det8: recibido 8  -> FALTANTE
    (102,   1,  9, 7, 0),   -- det9: recibido 7  -> EXCESO
    (103,   1, 10, 6, 0),   -- det10: recibido 6 -> exacto (control)
    (104,   1, 11, 5, 0),   -- det11: parte 1  (anti-multiplicacion)
    (105,   2, 11, 4, 0),   -- det11: parte 2  -> total 9 de 12 (FALTANTE, una sola incidencia)
    (106, 999, 20, 0, 0),   -- R09b: recepcion 999 no existe
    (107,   1, 7777,0, 0),  -- R09c: detalle 7777 no existe
    (108,   1, 12, 5, 0);   -- R09d: rec1 es de oc1 pero det12 es de oc4

-- ---------------------------------------------------------------------
-- 4) Motor de incidencias sobre el STAGING (mismos predicados que la
--    validacion oficial, aplicados a las tablas t_*)
-- ---------------------------------------------------------------------
CREATE TEMP TABLE stg_incidencias (
    entidad TEXT, id_registro INT, regla TEXT, severidad TEXT
) ON COMMIT DROP;

INSERT INTO stg_incidencias
SELECT 'detalle_orden_compra', detalle_id, 'CANTIDAD_POSITIVA','ERROR'
    FROM t_detalle WHERE cantidad <= 0
UNION ALL SELECT 'detalle_orden_compra', detalle_id, 'PRECIO_NO_NEGATIVO','ERROR'
    FROM t_detalle WHERE precio_unitario < 0
UNION ALL SELECT 'detalle_orden_compra', detalle_id, 'DESCUENTO_NO_NEGATIVO','ERROR'
    FROM t_detalle WHERE descuento < 0
UNION ALL SELECT 'detalle_orden_compra', detalle_id, 'SUBTOTAL_LINEA_COHERENTE','ERROR'
    FROM t_detalle WHERE subtotal <> ROUND(cantidad*precio_unitario - descuento, 2)
UNION ALL SELECT 'detalle_orden_compra', d.detalle_id, 'DETALLE_PERTENECE_ORDEN','ERROR'
    FROM t_detalle d WHERE NOT EXISTS (SELECT 1 FROM t_ordenes o WHERE o.oc_id=d.oc_id)
UNION ALL SELECT 'detalle_orden_compra', d.detalle_id, 'INSUMO_EXISTE','ERROR'
    FROM t_detalle d WHERE NOT EXISTS (SELECT 1 FROM t_insumos i WHERE i.insumo_id=d.insumo_id)
UNION ALL SELECT 'ordenes_compra', o.oc_id, 'PROVEEDOR_VALIDO','ERROR'
    FROM t_ordenes o WHERE NOT EXISTS (SELECT 1 FROM t_proveedores p WHERE p.proveedor_id=o.proveedor_id)
UNION ALL SELECT 'ordenes_compra', oc_id, 'CABECERA_COHERENTE','REVISION'
    FROM t_ordenes WHERE total <> subtotal+impuesto OR impuesto <> ROUND(subtotal*0.19,2)
UNION ALL SELECT 'recepciones', r.recepcion_id, 'RECEPCION_SIN_ORDEN','ERROR'
    FROM t_recep r WHERE NOT EXISTS (SELECT 1 FROM t_ordenes o WHERE o.oc_id=r.oc_id)
UNION ALL SELECT 'detalle_recepcion', dr.detalle_recepcion_id, 'DETREC_SIN_RECEPCION','ERROR'
    FROM t_detrec dr WHERE NOT EXISTS (SELECT 1 FROM t_recep r WHERE r.recepcion_id=dr.recepcion_id)
UNION ALL SELECT 'detalle_recepcion', dr.detalle_recepcion_id, 'DETREC_SIN_DETALLE','ERROR'
    FROM t_detrec dr WHERE NOT EXISTS (SELECT 1 FROM t_detalle d WHERE d.detalle_id=dr.detalle_id)
UNION ALL SELECT 'detalle_recepcion', dr.detalle_recepcion_id, 'DETREC_LINEA_OTRA_ORDEN','ERROR'
    FROM t_detrec dr
    JOIN t_recep r   ON r.recepcion_id = dr.recepcion_id
    JOIN t_detalle d ON d.detalle_id   = dr.detalle_id
    WHERE r.oc_id <> d.oc_id
UNION ALL SELECT 'detalle_orden_compra', d.detalle_id, 'SOLICITADO_VS_RECIBIDO','REVISION'
    FROM t_detalle d
    JOIN (SELECT detalle_id, SUM(cantidad_recibida+cantidad_rechazada) recepcionado
          FROM t_detrec GROUP BY detalle_id) rec ON rec.detalle_id = d.detalle_id
    WHERE rec.recepcionado <> d.cantidad;

-- ---------------------------------------------------------------------
-- 5) Reporte de casos: esperado vs obtenido  ->  PASA / FALLA
--    obt() cuenta incidencias de una (entidad,id,regla) concreta.
-- ---------------------------------------------------------------------
\echo '=== RESULTADO DE LAS PRUEBAS (PASA/FALLA) ==='
WITH casos(nro, caso, entidad, id_reg, regla, esperado) AS (VALUES
    ( 1, 'Registro valido (detalle)',        'detalle_orden_compra',  1, 'CANTIDAD_POSITIVA',        0),
    ( 1, 'Registro valido (orden)',          'ordenes_compra',        1, 'PROVEEDOR_VALIDO',         0),
    ( 2, 'Cantidad <= 0',                     'detalle_orden_compra',  2, 'CANTIDAD_POSITIVA',        1),
    ( 3, 'Precio < 0',                        'detalle_orden_compra',  3, 'PRECIO_NO_NEGATIVO',       1),
    ( 4, 'Descuento < 0',                     'detalle_orden_compra',  4, 'DESCUENTO_NO_NEGATIVO',    1),
    ( 5, 'Subtotal de linea incoherente',     'detalle_orden_compra',  5, 'SUBTOTAL_LINEA_COHERENTE', 1),
    ( 6, 'Cabecera incoherente (IVA)',        'ordenes_compra',        3, 'CABECERA_COHERENTE',       1),
    ( 7, 'Proveedor inexistente',             'ordenes_compra',        2, 'PROVEEDOR_VALIDO',         1),
    ( 8, 'Detalle sin orden (huerfano)',      'detalle_orden_compra',  6, 'DETALLE_PERTENECE_ORDEN',  1),
    ( 9, 'Insumo inexistente',                'detalle_orden_compra',  7, 'INSUMO_EXISTE',            1),
    (10, 'Recepcion sin orden',               'recepciones',          50, 'RECEPCION_SIN_ORDEN',      1),
    (10, 'Detrec sin recepcion',              'detalle_recepcion',   106, 'DETREC_SIN_RECEPCION',     1),
    (10, 'Detrec sin detalle',                'detalle_recepcion',   107, 'DETREC_SIN_DETALLE',       1),
    (10, 'Detrec linea de otra orden',        'detalle_recepcion',   108, 'DETREC_LINEA_OTRA_ORDEN',  1),
    (11, 'Solicitado vs recibido FALTANTE',   'detalle_orden_compra',  8, 'SOLICITADO_VS_RECIBIDO',   1),
    (12, 'Solicitado vs recibido EXCESO',     'detalle_orden_compra',  9, 'SOLICITADO_VS_RECIBIDO',   1),
    (13, 'Control: recibido = solicitado',    'detalle_orden_compra', 10, 'SOLICITADO_VS_RECIBIDO',   0),
    (14, 'Anti-multiplicacion (1 sola inc.)', 'detalle_orden_compra', 11, 'SOLICITADO_VS_RECIBIDO',   1)
)
SELECT c.nro,
       c.caso,
       c.esperado,
       (SELECT COUNT(*) FROM stg_incidencias s
         WHERE s.entidad=c.entidad AND s.id_registro=c.id_reg AND s.regla=c.regla) AS obtenido,
       CASE WHEN c.esperado =
            (SELECT COUNT(*) FROM stg_incidencias s
              WHERE s.entidad=c.entidad AND s.id_registro=c.id_reg AND s.regla=c.regla)
            THEN 'PASA' ELSE 'FALLA' END AS resultado
FROM casos c
ORDER BY c.nro, c.caso;

-- ---------------------------------------------------------------------
-- 6) Evidencia explicita de la regla anti-multiplicacion (det 11)
--    det11 tiene 2 recepciones (5+4). El metodo correcto reporta
--    solicitado=12 y recepcionado=9. Un JOIN directo inflaria el
--    solicitado a 24 (12 x 2 filas de recepcion).
-- ---------------------------------------------------------------------
\echo '=== EVIDENCIA ANTI-MULTIPLICACION (detalle 11) ==='
SELECT 'MAL_join_directo'  AS metodo, d.detalle_id,
       SUM(d.cantidad)     AS solicitado_reportado
FROM t_detalle d JOIN t_detrec dr ON dr.detalle_id=d.detalle_id
WHERE d.detalle_id=11 GROUP BY d.detalle_id
UNION ALL
SELECT 'BIEN_agrega_antes', d.detalle_id, d.cantidad
FROM t_detalle d
JOIN (SELECT detalle_id, SUM(cantidad_recibida+cantidad_rechazada) r FROM t_detrec GROUP BY detalle_id) x
  ON x.detalle_id=d.detalle_id
WHERE d.detalle_id=11;

-- ---------------------------------------------------------------------
-- 7) Conteo global PASA/FALLA
--    Además de informar el resultado, el script falla realmente si
--    cualquier caso no cumple lo esperado.
-- ---------------------------------------------------------------------
\echo '=== CONTEO GLOBAL ==='

CREATE TEMP TABLE tmp_resultado_global ON COMMIT DROP AS
WITH casos(entidad, id_reg, regla, esperado) AS (VALUES
    ('detalle_orden_compra',  1, 'CANTIDAD_POSITIVA',        0),
    ('ordenes_compra',        1, 'PROVEEDOR_VALIDO',         0),
    ('detalle_orden_compra',  2, 'CANTIDAD_POSITIVA',        1),
    ('detalle_orden_compra',  3, 'PRECIO_NO_NEGATIVO',       1),
    ('detalle_orden_compra',  4, 'DESCUENTO_NO_NEGATIVO',    1),
    ('detalle_orden_compra',  5, 'SUBTOTAL_LINEA_COHERENTE', 1),
    ('ordenes_compra',        3, 'CABECERA_COHERENTE',       1),
    ('ordenes_compra',        2, 'PROVEEDOR_VALIDO',         1),
    ('detalle_orden_compra',  6, 'DETALLE_PERTENECE_ORDEN',  1),
    ('detalle_orden_compra',  7, 'INSUMO_EXISTE',            1),
    ('recepciones',          50, 'RECEPCION_SIN_ORDEN',      1),
    ('detalle_recepcion',   106, 'DETREC_SIN_RECEPCION',     1),
    ('detalle_recepcion',   107, 'DETREC_SIN_DETALLE',       1),
    ('detalle_recepcion',   108, 'DETREC_LINEA_OTRA_ORDEN',  1),
    ('detalle_orden_compra',  8, 'SOLICITADO_VS_RECIBIDO',   1),
    ('detalle_orden_compra',  9, 'SOLICITADO_VS_RECIBIDO',   1),
    ('detalle_orden_compra', 10, 'SOLICITADO_VS_RECIBIDO',   0),
    ('detalle_orden_compra', 11, 'SOLICITADO_VS_RECIBIDO',   1)
)
SELECT COUNT(*) AS total_casos,
       COUNT(*) FILTER (WHERE ok)     AS pasa,
       COUNT(*) FILTER (WHERE NOT ok) AS falla
FROM (
    SELECT c.esperado =
           (
               SELECT COUNT(*)
               FROM stg_incidencias s
               WHERE s.entidad = c.entidad
                 AND s.id_registro = c.id_reg
                 AND s.regla = c.regla
           ) AS ok
    FROM casos c
) q;

SELECT total_casos, pasa, falla
FROM tmp_resultado_global;

-- Aserción real: con ON_ERROR_STOP, cualquier fallo provoca código de
-- salida distinto de cero en psql.
DO $$
DECLARE
    v_falla INTEGER;
BEGIN
    SELECT falla
    INTO v_falla
    FROM tmp_resultado_global;

    IF v_falla <> 0 THEN
        RAISE EXCEPTION
            'Pruebas de calidad Compras fallidas: % caso(s) no pasaron',
            v_falla;
    END IF;
END
$$;

ROLLBACK;
-- Fin de test_calidad_compras.sql  (ROLLBACK: no persiste ningun cambio)
