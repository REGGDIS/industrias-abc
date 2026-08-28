-- =====================================================================
--  validaciones.sql  -  Sistema Operacional de COMPRAS Y ABASTECIMIENTO
--  Demuestra que la base fue creada y poblada correctamente y que soporta
--  los analisis definidos por el Trabajo v2. Ejecutar tras schema + seed.
--
--  Convencion: los bloques "control de integridad" deben devolver 0 filas
--  (o problemas = 0). Los bloques "analisis" muestran resultados de negocio.
--  Nota: los montos estan en la moneda original de cada orden; la conversion
--  CLP/USD/EUR corresponde a la etapa ETL, por eso los rankings de gasto se
--  calculan sobre ordenes en CLP.
-- =====================================================================

-- ---------------------------------------------------------------------
-- A. CONTEOS POR TABLA
-- ---------------------------------------------------------------------
SELECT 'areas'                AS tabla, COUNT(*) AS registros FROM areas
UNION ALL SELECT 'centros_costo',        COUNT(*) FROM centros_costo
UNION ALL SELECT 'compradores',          COUNT(*) FROM compradores
UNION ALL SELECT 'proveedores',          COUNT(*) FROM proveedores
UNION ALL SELECT 'categorias_insumo',    COUNT(*) FROM categorias_insumo
UNION ALL SELECT 'insumos',              COUNT(*) FROM insumos
UNION ALL SELECT 'ordenes_compra',       COUNT(*) FROM ordenes_compra
UNION ALL SELECT 'detalle_orden_compra', COUNT(*) FROM detalle_orden_compra
UNION ALL SELECT 'recepciones',          COUNT(*) FROM recepciones
UNION ALL SELECT 'detalle_recepcion',    COUNT(*) FROM detalle_recepcion
ORDER BY tabla;

-- ---------------------------------------------------------------------
-- B. CONTROLES DE INTEGRIDAD Y CALIDAD  (todos deben dar 0 filas)
-- ---------------------------------------------------------------------

-- B1. Proveedores duplicados por RUT exacto (UNIQUE ya lo impide)
SELECT rut_proveedor, COUNT(*) AS veces
FROM proveedores GROUP BY rut_proveedor HAVING COUNT(*) > 1;

-- B2. Mismo proveedor con RUT en formatos distintos (normalizando puntos/guion)
--     Debe dar 0: la heterogeneidad de formato NO implica duplicar proveedores.
SELECT UPPER(REPLACE(REPLACE(rut_proveedor,'.',''),'-','')) AS rut_normalizado,
       COUNT(*) AS veces, STRING_AGG(rut_proveedor, ' | ') AS formatos
FROM proveedores
GROUP BY 1 HAVING COUNT(*) > 1;

-- B3. Ordenes con fecha_requerida anterior a la emision (debe dar 0)
SELECT oc_id, numero_oc, fecha_emision, fecha_requerida
FROM ordenes_compra
WHERE fecha_requerida IS NOT NULL AND fecha_requerida < fecha_emision;

-- B4. Recepciones con fecha anterior a la emision de la orden (debe dar 0)
SELECT r.recepcion_id, o.numero_oc, o.fecha_emision, r.fecha_recepcion
FROM recepciones r JOIN ordenes_compra o ON o.oc_id = r.oc_id
WHERE r.fecha_recepcion < o.fecha_emision;

-- B5. Recepcion acumulada de una linea que supere lo solicitado (debe dar 0)
SELECT d.detalle_id, o.numero_oc, d.cantidad AS solicitado,
       SUM(dr.cantidad_recibida + dr.cantidad_rechazada) AS recepcionado
FROM detalle_orden_compra d
JOIN ordenes_compra o        ON o.oc_id = d.oc_id
JOIN detalle_recepcion dr    ON dr.detalle_id = d.detalle_id
GROUP BY d.detalle_id, o.numero_oc, d.cantidad
HAVING SUM(dr.cantidad_recibida + dr.cantidad_rechazada) > d.cantidad;

-- B6. Inconsistencia del subtotal de linea = cantidad*precio - descuento (debe dar 0)
SELECT detalle_id, oc_id, subtotal,
       ROUND(cantidad * precio_unitario - descuento, 2) AS subtotal_esperado
FROM detalle_orden_compra
WHERE subtotal <> ROUND(cantidad * precio_unitario - descuento, 2);

-- B7. Inconsistencia de cabecera: total <> subtotal+impuesto o IVA (19%) mal calculado (0)
SELECT oc_id, numero_oc, subtotal, impuesto, total
FROM ordenes_compra
WHERE total <> subtotal + impuesto
   OR impuesto <> ROUND(subtotal * 0.19, 2);

-- B8. Detalle de recepcion apuntando a una linea de otra orden (debe dar 0)
SELECT dr.detalle_recepcion_id
FROM detalle_recepcion dr
JOIN recepciones r          ON r.recepcion_id = dr.recepcion_id
JOIN detalle_orden_compra d ON d.detalle_id  = dr.detalle_id
WHERE r.oc_id <> d.oc_id;

-- ---------------------------------------------------------------------
-- C. ANALISIS DE NEGOCIO EXIGIDOS POR EL TRABAJO v2
-- ---------------------------------------------------------------------

-- C1. Top 5 proveedores por gasto (ordenes en CLP, excluye anuladas)
SELECT p.razon_social, COUNT(o.oc_id) AS ordenes, SUM(o.total) AS gasto_clp
FROM ordenes_compra o JOIN proveedores p ON p.proveedor_id = o.proveedor_id
WHERE o.moneda = 'CLP' AND o.estado <> 'ANULADA'
GROUP BY p.razon_social
ORDER BY gasto_clp DESC
LIMIT 5;

-- C2. Insumos por gasto (sobre el detalle de ordenes en CLP no anuladas)
SELECT i.nombre_insumo, ci.nombre_categoria,
       SUM(d.subtotal) AS gasto_clp, SUM(d.cantidad) AS cantidad_total
FROM detalle_orden_compra d
JOIN ordenes_compra o     ON o.oc_id = d.oc_id
JOIN insumos i            ON i.insumo_id = d.insumo_id
JOIN categorias_insumo ci ON ci.categoria_id = i.categoria_id
WHERE o.moneda = 'CLP' AND o.estado <> 'ANULADA'
GROUP BY i.nombre_insumo, ci.nombre_categoria
ORDER BY gasto_clp DESC;

-- C3. Compras por centro de costo (CLP, no anuladas)
SELECT cc.codigo_centro, cc.nombre_centro,
       COUNT(o.oc_id) AS ordenes, SUM(o.total) AS gasto_clp
FROM ordenes_compra o JOIN centros_costo cc ON cc.centro_costo_id = o.centro_costo_id
WHERE o.moneda = 'CLP' AND o.estado <> 'ANULADA'
GROUP BY cc.codigo_centro, cc.nombre_centro
ORDER BY gasto_clp DESC;

-- C4. Compras por AREA (derivado: centro de costo -> area)
SELECT a.codigo_area, a.nombre_area,
       COUNT(o.oc_id) AS ordenes, SUM(o.total) AS gasto_clp
FROM ordenes_compra o
JOIN centros_costo cc ON cc.centro_costo_id = o.centro_costo_id
JOIN areas a          ON a.area_id = cc.area_id
WHERE o.moneda = 'CLP' AND o.estado <> 'ANULADA'
GROUP BY a.codigo_area, a.nombre_area
ORDER BY gasto_clp DESC;

-- C5. Compras por mes (CLP, no anuladas)
SELECT TO_CHAR(DATE_TRUNC('month', o.fecha_emision), 'YYYY-MM') AS mes,
       COUNT(o.oc_id) AS ordenes, SUM(o.total) AS gasto_clp
FROM ordenes_compra o
WHERE o.moneda = 'CLP' AND o.estado <> 'ANULADA'
GROUP BY 1 ORDER BY 1;

-- C6. Cumplimiento de proveedores: atrasos (recepcion posterior a lo requerido)
SELECT p.razon_social, o.numero_oc, o.fecha_requerida,
       MAX(r.fecha_recepcion) AS ultima_recepcion,
       MAX(r.fecha_recepcion) - o.fecha_requerida AS dias_atraso
FROM ordenes_compra o
JOIN proveedores p ON p.proveedor_id = o.proveedor_id
JOIN recepciones r ON r.oc_id = o.oc_id
GROUP BY p.razon_social, o.numero_oc, o.fecha_requerida
HAVING MAX(r.fecha_recepcion) > o.fecha_requerida
ORDER BY dias_atraso DESC;

-- C7. Diferencias de recepcion: lineas con rechazo o recepcion incompleta
SELECT o.numero_oc, i.nombre_insumo, d.cantidad AS solicitado,
       COALESCE(SUM(dr.cantidad_recibida),0)  AS recibido,
       COALESCE(SUM(dr.cantidad_rechazada),0) AS rechazado,
       d.cantidad - COALESCE(SUM(dr.cantidad_recibida + dr.cantidad_rechazada),0) AS pendiente
FROM detalle_orden_compra d
JOIN ordenes_compra o ON o.oc_id = d.oc_id
JOIN insumos i        ON i.insumo_id = d.insumo_id
LEFT JOIN detalle_recepcion dr ON dr.detalle_id = d.detalle_id
GROUP BY o.numero_oc, i.nombre_insumo, d.cantidad
HAVING COALESCE(SUM(dr.cantidad_rechazada),0) > 0
    OR d.cantidad - COALESCE(SUM(dr.cantidad_recibida + dr.cantidad_rechazada),0) > 0
ORDER BY o.numero_oc;

-- Fin de validaciones.sql
