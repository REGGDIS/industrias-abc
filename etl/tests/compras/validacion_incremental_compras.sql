-- =====================================================================
-- ETL Compras 0.2 · Prueba del prototipo incremental
-- Archivo: etl/tests/compras/validacion_incremental_compras.sql
-- Dominio: Compras (PostgreSQL) · Responsable: Raymond Civil
--
-- Demuestra, de forma REPRODUCIBLE y SIN alterar el seed, que:
--   (1) el watermark por PK detecta INSERT (órdenes y recepciones);
--   (2) la comparación de snapshot detecta UPDATE (órdenes y recepciones)
--       y excluye las filas sin cambios.
-- Cada prueba corre dentro de BEGIN … ROLLBACK con tablas TEMP, respetando
-- FK, CHECK, dominios de estado y triggers. Ejecutar con:  psql -f este_archivo
-- =====================================================================
\echo '################ VALIDACIÓN INCREMENTAL COMPRAS 0.2 ################'

-- ------------------------------------------------------------------
-- PRUEBA 1 — INSERT de órdenes (watermark por oc_id)
-- ------------------------------------------------------------------
\echo ''
\echo '=== PRUEBA 1: INSERT de órdenes ==='
BEGIN;
SELECT MAX(oc_id) AS wm_oc FROM ordenes_compra \gset
\echo '  Watermark inicial (ultimo_oc_id):' :wm_oc
INSERT INTO ordenes_compra
    (numero_oc, proveedor_id, fecha_emision, fecha_requerida,
     centro_costo_id, comprador_id, estado, moneda, subtotal, impuesto, total)
VALUES
    ('OC-TEST-9999', 1, DATE '2026-07-01', DATE '2026-07-10',
     1, 1, 'EMITIDA', 'CLP', 1000.00, 190.00, 1190.00);
\echo '  Esperado: aparece SOLO la orden nueva (oc_id > watermark):'
SELECT oc_id, numero_oc, estado
FROM ordenes_compra
WHERE oc_id > :wm_oc
ORDER BY oc_id;
\echo '  Esperado: 0 filas si el watermark se avanza al máximo actual (nada nuevo):'
SELECT COUNT(*) AS nuevas_con_watermark_al_dia
FROM ordenes_compra
WHERE oc_id > (SELECT MAX(oc_id) FROM ordenes_compra);
ROLLBACK;

-- ------------------------------------------------------------------
-- PRUEBA 2 — INSERT de recepciones (watermark por recepcion_id)
-- ------------------------------------------------------------------
\echo ''
\echo '=== PRUEBA 2: INSERT de recepciones ==='
BEGIN;
SELECT MAX(recepcion_id) AS wm_rec FROM recepciones \gset
\echo '  Watermark inicial (ultima_recepcion_id):' :wm_rec
INSERT INTO recepciones (oc_id, fecha_recepcion, estado)
VALUES ((SELECT MIN(oc_id) FROM ordenes_compra), DATE '2026-12-31', 'REGISTRADA');
\echo '  Esperado: aparece SOLO la recepción nueva (recepcion_id > watermark):'
SELECT recepcion_id, oc_id, fecha_recepcion, estado
FROM recepciones
WHERE recepcion_id > :wm_rec
ORDER BY recepcion_id;
ROLLBACK;

-- ------------------------------------------------------------------
-- PRUEBA 3 — UPDATE de órdenes (snapshot + IS DISTINCT FROM)
-- ------------------------------------------------------------------
\echo ''
\echo '=== PRUEBA 3: UPDATE de órdenes ==='
BEGIN;
CREATE TEMP TABLE tmp_compras_ordenes_snapshot_anterior AS
    SELECT * FROM ordenes_compra;
-- cambio controlado y VÁLIDO (dominio EMITIDA/PARCIAL/RECIBIDA/CERRADA/ANULADA)
UPDATE ordenes_compra
   SET estado = 'PARCIAL'
 WHERE oc_id = (SELECT oc_id FROM ordenes_compra WHERE estado='EMITIDA' ORDER BY oc_id LIMIT 1);
\echo '  Esperado: aparece SOLO la orden modificada (estado_actual != estado_anterior):'
SELECT actual.oc_id, actual.estado AS estado_actual, anterior.estado AS estado_anterior
FROM ordenes_compra actual
JOIN tmp_compras_ordenes_snapshot_anterior anterior ON anterior.oc_id = actual.oc_id
WHERE actual.estado          IS DISTINCT FROM anterior.estado
   OR actual.fecha_requerida IS DISTINCT FROM anterior.fecha_requerida
   OR actual.centro_costo_id IS DISTINCT FROM anterior.centro_costo_id
   OR actual.comprador_id    IS DISTINCT FROM anterior.comprador_id
   OR actual.moneda          IS DISTINCT FROM anterior.moneda
   OR actual.subtotal        IS DISTINCT FROM anterior.subtotal
   OR actual.impuesto        IS DISTINCT FROM anterior.impuesto
   OR actual.total           IS DISTINCT FROM anterior.total
ORDER BY actual.oc_id;
\echo '  Verificacion (§17) sin cambios excluidos: total ordenes vs ordenes con cambios (esperado: 1 con cambios):'
SELECT (SELECT COUNT(*) FROM ordenes_compra) AS total_ordenes,
       COUNT(*) AS ordenes_con_cambios
FROM ordenes_compra actual
JOIN tmp_compras_ordenes_snapshot_anterior anterior ON anterior.oc_id = actual.oc_id
WHERE actual.estado          IS DISTINCT FROM anterior.estado
   OR actual.fecha_requerida IS DISTINCT FROM anterior.fecha_requerida
   OR actual.centro_costo_id IS DISTINCT FROM anterior.centro_costo_id
   OR actual.comprador_id    IS DISTINCT FROM anterior.comprador_id
   OR actual.moneda          IS DISTINCT FROM anterior.moneda
   OR actual.subtotal        IS DISTINCT FROM anterior.subtotal
   OR actual.impuesto        IS DISTINCT FROM anterior.impuesto
   OR actual.total           IS DISTINCT FROM anterior.total;
ROLLBACK;

-- ------------------------------------------------------------------
-- PRUEBA 4 — UPDATE de recepciones (snapshot + IS DISTINCT FROM)
-- ------------------------------------------------------------------
\echo ''
\echo '=== PRUEBA 4: UPDATE de recepciones ==='
BEGIN;
CREATE TEMP TABLE tmp_compras_recepciones_snapshot_anterior AS
    SELECT * FROM recepciones;
UPDATE recepciones
   SET estado = 'CON_DIFERENCIAS'
 WHERE recepcion_id = (SELECT recepcion_id FROM recepciones WHERE estado='CONFORME' ORDER BY recepcion_id LIMIT 1);
\echo '  Esperado: aparece SOLO la recepción modificada:'
SELECT actual.recepcion_id, actual.estado AS estado_actual, anterior.estado AS estado_anterior
FROM recepciones actual
JOIN tmp_compras_recepciones_snapshot_anterior anterior ON anterior.recepcion_id = actual.recepcion_id
WHERE actual.fecha_recepcion IS DISTINCT FROM anterior.fecha_recepcion
   OR actual.estado          IS DISTINCT FROM anterior.estado
ORDER BY actual.recepcion_id;
ROLLBACK;

\echo ''
\echo '################ FIN — el seed NO fue modificado (todo en ROLLBACK) ################'
