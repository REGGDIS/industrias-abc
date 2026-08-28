-- =====================================================================
--  seed.sql  -  Datos de prueba del Sistema Operacional de COMPRAS
--  Coherentes con el Universo Empresarial Master v0.2 (Industrias ABC).
--  Heterogeneidad controlada (RUT con/sin puntos, mayusculas) que NO
--  rompe restricciones; la base se recrea desde cero con schema.sql.
--  Ejecutar despues de schema.sql.
-- =====================================================================

-- Limpieza de datos (respeta el orden hijo -> padre; sin borrar estructura)
TRUNCATE detalle_recepcion, recepciones, detalle_orden_compra, ordenes_compra,
         insumos, categorias_insumo, proveedores, compradores,
         centros_costo, areas RESTART IDENTITY;

-- 1) areas (referencia del Universo)
INSERT INTO areas (codigo_area, nombre_area) VALUES
  ('A01','Administración'),
  ('A02','Recursos Humanos'),
  ('A03','Finanzas y Contabilidad'),
  ('A04','Compras y Abastecimiento'),
  ('A05','Producción'),
  ('A06','Mantención'),
  ('A07','Logística');

-- 2) centros_costo (1:1 con area)
INSERT INTO centros_costo (codigo_centro, nombre_centro, area_id)
SELECT v.cod, v.nom, a.area_id FROM (VALUES
  ('CC001','Administración General','A01'),
  ('CC002','Recursos Humanos','A02'),
  ('CC003','Finanzas','A03'),
  ('CC004','Abastecimiento','A04'),
  ('CC005','Planta de Producción','A05'),
  ('CC006','Mantención Industrial','A06'),
  ('CC007','Logística y Bodega','A07')
) AS v(cod,nom,area) JOIN areas a ON a.codigo_area = v.area;

-- 3) compradores (catalogo propio de Compras; homologable con RRHH)
INSERT INTO compradores (codigo_comprador, nombre_comprador, area_id)
SELECT v.cod, v.nom, a.area_id FROM (VALUES
  ('COMP01','Carlos Torres López','A04'),
  ('COMP02','Paula López Contreras','A04'),
  ('COMP03','Sebastián Silva Jara','A04'),
  ('COMP04','Rodrigo Rodríguez Soto','A04')
) AS v(cod,nom,area) JOIN areas a ON a.codigo_area = v.area;

-- 4) proveedores (15 del Master; con heterogeneidad controlada de calidad)
INSERT INTO proveedores (rut_proveedor, razon_social, nombre_fantasia, categoria, region, comuna, estado) VALUES
  ('76000137-6','Aceros del Sur SpA','Aceros del Sur','Acero y perfiles','Biobío','Talcahuano','ACTIVO'),
  ('76000274-7','Metales Andinos Ltda.','Metales Andinos','Acero y perfiles','Biobío','Concepción','ACTIVO'),
  ('76000411-1','Ferretería Industrial Bío Bío','Ferretería Ind. Bío Bío','Ferretería industrial','Biobío','Los Ángeles','ACTIVO'),
  ('76.000.548-7','Soldatec SpA','Soldatec','Soldadura','Biobío','Concepción','ACTIVO'),
  ('76000685-8','Pinturas Técnicas del Pacífico','Pinturas Técnicas del Pacífico','Pinturas','Ñuble','Chillán','ACTIVO'),
  ('76000822-2','LubriChile Industrial Ltda.','LubriChile Ind.','Lubricantes','Metropolitana','Santiago','ACTIVO'),
  ('76000959-8','Rodamientos Centro Sur','Rodamientos Centro Sur','Rodamientos','Biobío','Los Ángeles','ACTIVO'),
  ('76001096-0','Embalajes del Valle SpA','Embalajes del Valle','Embalaje','Biobío','Nacimiento','ACTIVO'),
  ('76001233-5','Suministros Industriales Laja','Suministros Ind.es Laja','Suministros industriales','Biobío','Laja','ACTIVO'),
  ('76001370-6','Fijaciones del Sur Ltda.','Fijaciones del Sur','Ferretería industrial','Araucanía','Temuco','ACTIVO'),
  ('76.001.507-5','Servicios y Aceros Cabrero','Servicios y Aceros Cabrero','Acero y perfiles','Biobío','Cabrero','ACTIVO'),
  ('76001644-6','Tecnoinsumos Chile SpA','Tecnoinsumos Chile','Suministros industriales','Metropolitana','Santiago','ACTIVO'),
  ('76001781-7','QUIMICA Y PINTURAS INDUSTRIAL','Química y Pinturas Ind.','Pinturas','Valparaíso','Quilpué','ACTIVO'),
  ('76001918-6','Importadora Mecánica Sur','Importadora Mecánica Sur','Rodamientos','Biobío','Concepción','ACTIVO'),
  ('76002055-9','Packaging Industrial Chile','Packaging Ind. Chile','Embalaje','Maule','Talca','INACTIVO');

-- 5) categorias_insumo
INSERT INTO categorias_insumo (codigo_categoria, nombre_categoria) VALUES
  ('CAT01','Materias primas'),
  ('CAT02','Fijaciones'),
  ('CAT03','Componentes'),
  ('CAT04','Soldadura'),
  ('CAT05','Pinturas'),
  ('CAT06','Lubricantes'),
  ('CAT07','Consumibles'),
  ('CAT08','Embalaje');

-- 6) insumos (codigo local de Compras; la categoria se normaliza por FK)
INSERT INTO insumos (codigo_insumo, nombre_insumo, categoria_id, unidad_medida, stock_minimo)
SELECT v.cod, v.nom, c.categoria_id, v.um, v.stock FROM (VALUES
  ('INS001','Acero laminado','CAT01','kg',500),
  ('INS002','Perfil de acero','CAT01','m',300),
  ('INS003','Plancha metálica','CAT01','unidad',100),
  ('INS004','Pernos industriales','CAT02','unidad',1000),
  ('INS005','Tuercas industriales','CAT02','unidad',1000),
  ('INS006','Rodamientos','CAT03','unidad',200),
  ('INS007','Electrodos de soldadura','CAT04','kg',150),
  ('INS008','Alambre de soldadura','CAT04','kg',150),
  ('INS009','Pintura anticorrosiva','CAT05','litro',200),
  ('INS010','Lubricante industrial','CAT06','litro',100),
  ('INS011','Discos de corte','CAT07','unidad',300),
  ('INS012','Discos de desbaste','CAT07','unidad',300),
  ('INS013','Material de embalaje','CAT08','unidad',500),
  ('INS014','Etiquetas industriales','CAT08','unidad',1000),
  ('INS015','Elementos de fijación','CAT02','unidad',800)
) AS v(cod,nom,cat,um,stock) JOIN categorias_insumo c ON c.codigo_categoria = v.cat;

-- 7) ordenes_compra (cabecera; subtotal/impuesto/total se recalculan al final)
INSERT INTO ordenes_compra (numero_oc, proveedor_id, fecha_emision, fecha_requerida,
                            centro_costo_id, comprador_id, estado, moneda)
SELECT 'OC-2025-0001', p.proveedor_id, DATE '2025-01-15', DATE '2025-01-30', cc.centro_costo_id, cp.comprador_id, 'RECIBIDA', 'CLP'
  FROM proveedores p, centros_costo cc, compradores cp
  WHERE p.rut_proveedor='76000137-6' AND cc.codigo_centro='CC004' AND cp.codigo_comprador='COMP01'
UNION ALL
SELECT 'OC-2025-0002', p.proveedor_id, DATE '2025-02-10', DATE '2025-02-25', cc.centro_costo_id, cp.comprador_id, 'RECIBIDA', 'CLP'
  FROM proveedores p, centros_costo cc, compradores cp
  WHERE p.rut_proveedor='76000411-1' AND cc.codigo_centro='CC004' AND cp.codigo_comprador='COMP02'
UNION ALL
SELECT 'OC-2025-0003', p.proveedor_id, DATE '2025-03-05', DATE '2025-03-20', cc.centro_costo_id, cp.comprador_id, 'PARCIAL', 'CLP'
  FROM proveedores p, centros_costo cc, compradores cp
  WHERE p.rut_proveedor='76.000.548-7' AND cc.codigo_centro='CC005' AND cp.codigo_comprador='COMP01'
UNION ALL
SELECT 'OC-2025-0004', p.proveedor_id, DATE '2025-04-12', DATE '2025-04-26', cc.centro_costo_id, cp.comprador_id, 'RECIBIDA', 'CLP'
  FROM proveedores p, centros_costo cc, compradores cp
  WHERE p.rut_proveedor='76000685-8' AND cc.codigo_centro='CC006' AND cp.codigo_comprador='COMP03'
UNION ALL
SELECT 'OC-2025-0005', p.proveedor_id, DATE '2025-05-08', DATE '2025-05-22', cc.centro_costo_id, cp.comprador_id, 'CERRADA', 'CLP'
  FROM proveedores p, centros_costo cc, compradores cp
  WHERE p.rut_proveedor='76000822-2' AND cc.codigo_centro='CC006' AND cp.codigo_comprador='COMP03'
UNION ALL
SELECT 'OC-2025-0006', p.proveedor_id, DATE '2025-06-14', DATE '2025-06-28', cc.centro_costo_id, cp.comprador_id, 'EMITIDA', 'CLP'
  FROM proveedores p, centros_costo cc, compradores cp
  WHERE p.rut_proveedor='76000959-8' AND cc.codigo_centro='CC005' AND cp.codigo_comprador='COMP02'
UNION ALL
SELECT 'OC-2025-0007', p.proveedor_id, DATE '2025-07-03', DATE '2025-07-17', cc.centro_costo_id, cp.comprador_id, 'RECIBIDA', 'CLP'
  FROM proveedores p, centros_costo cc, compradores cp
  WHERE p.rut_proveedor='76001096-0' AND cc.codigo_centro='CC007' AND cp.codigo_comprador='COMP04'
UNION ALL
SELECT 'OC-2025-0008', p.proveedor_id, DATE '2025-09-20', DATE '2025-10-05', cc.centro_costo_id, cp.comprador_id, 'PARCIAL', 'CLP'
  FROM proveedores p, centros_costo cc, compradores cp
  WHERE p.rut_proveedor='76000274-7' AND cc.codigo_centro='CC004' AND cp.codigo_comprador='COMP01'
UNION ALL
SELECT 'OC-2025-0009', p.proveedor_id, DATE '2025-11-11', DATE '2025-11-25', cc.centro_costo_id, cp.comprador_id, 'ANULADA', 'CLP'
  FROM proveedores p, centros_costo cc, compradores cp
  WHERE p.rut_proveedor='76001233-5' AND cc.codigo_centro='CC004' AND cp.codigo_comprador='COMP02'
UNION ALL
SELECT 'OC-2026-0001', p.proveedor_id, DATE '2026-01-19', DATE '2026-02-02', cc.centro_costo_id, cp.comprador_id, 'RECIBIDA', 'USD'
  FROM proveedores p, centros_costo cc, compradores cp
  WHERE p.rut_proveedor='76.001.507-5' AND cc.codigo_centro='CC005' AND cp.codigo_comprador='COMP01'
UNION ALL
SELECT 'OC-2026-0002', p.proveedor_id, DATE '2026-03-15', DATE '2026-03-29', cc.centro_costo_id, cp.comprador_id, 'RECIBIDA', 'CLP'
  FROM proveedores p, centros_costo cc, compradores cp
  WHERE p.rut_proveedor='76001781-7' AND cc.codigo_centro='CC006' AND cp.codigo_comprador='COMP03'
UNION ALL
SELECT 'OC-2026-0003', p.proveedor_id, DATE '2026-05-22', DATE '2026-06-05', cc.centro_costo_id, cp.comprador_id, 'EMITIDA', 'EUR'
  FROM proveedores p, centros_costo cc, compradores cp
  WHERE p.rut_proveedor='76001644-6' AND cc.codigo_centro='CC004' AND cp.codigo_comprador='COMP04';

-- 8) detalle_orden_compra (el trigger calcula el subtotal de cada linea)
INSERT INTO detalle_orden_compra (oc_id, insumo_id, cantidad, precio_unitario, descuento)
SELECT o.oc_id, i.insumo_id, 500, 2500, 0
  FROM ordenes_compra o, insumos i
  WHERE o.numero_oc='OC-2025-0001' AND i.codigo_insumo='INS001';
INSERT INTO detalle_orden_compra (oc_id, insumo_id, cantidad, precio_unitario, descuento)
SELECT o.oc_id, i.insumo_id, 200, 3200, 0
  FROM ordenes_compra o, insumos i
  WHERE o.numero_oc='OC-2025-0001' AND i.codigo_insumo='INS002';
INSERT INTO detalle_orden_compra (oc_id, insumo_id, cantidad, precio_unitario, descuento)
SELECT o.oc_id, i.insumo_id, 2000, 120, 5000
  FROM ordenes_compra o, insumos i
  WHERE o.numero_oc='OC-2025-0002' AND i.codigo_insumo='INS004';
INSERT INTO detalle_orden_compra (oc_id, insumo_id, cantidad, precio_unitario, descuento)
SELECT o.oc_id, i.insumo_id, 2000, 90, 0
  FROM ordenes_compra o, insumos i
  WHERE o.numero_oc='OC-2025-0002' AND i.codigo_insumo='INS005';
INSERT INTO detalle_orden_compra (oc_id, insumo_id, cantidad, precio_unitario, descuento)
SELECT o.oc_id, i.insumo_id, 1500, 210, 0
  FROM ordenes_compra o, insumos i
  WHERE o.numero_oc='OC-2025-0002' AND i.codigo_insumo='INS015';
INSERT INTO detalle_orden_compra (oc_id, insumo_id, cantidad, precio_unitario, descuento)
SELECT o.oc_id, i.insumo_id, 300, 6800, 0
  FROM ordenes_compra o, insumos i
  WHERE o.numero_oc='OC-2025-0003' AND i.codigo_insumo='INS007';
INSERT INTO detalle_orden_compra (oc_id, insumo_id, cantidad, precio_unitario, descuento)
SELECT o.oc_id, i.insumo_id, 200, 5200, 0
  FROM ordenes_compra o, insumos i
  WHERE o.numero_oc='OC-2025-0003' AND i.codigo_insumo='INS008';
INSERT INTO detalle_orden_compra (oc_id, insumo_id, cantidad, precio_unitario, descuento)
SELECT o.oc_id, i.insumo_id, 150, 9800, 0
  FROM ordenes_compra o, insumos i
  WHERE o.numero_oc='OC-2025-0004' AND i.codigo_insumo='INS009';
INSERT INTO detalle_orden_compra (oc_id, insumo_id, cantidad, precio_unitario, descuento)
SELECT o.oc_id, i.insumo_id, 120, 7200, 0
  FROM ordenes_compra o, insumos i
  WHERE o.numero_oc='OC-2025-0005' AND i.codigo_insumo='INS010';
INSERT INTO detalle_orden_compra (oc_id, insumo_id, cantidad, precio_unitario, descuento)
SELECT o.oc_id, i.insumo_id, 200, 8500, 0
  FROM ordenes_compra o, insumos i
  WHERE o.numero_oc='OC-2025-0006' AND i.codigo_insumo='INS006';
INSERT INTO detalle_orden_compra (oc_id, insumo_id, cantidad, precio_unitario, descuento)
SELECT o.oc_id, i.insumo_id, 500, 350, 10000
  FROM ordenes_compra o, insumos i
  WHERE o.numero_oc='OC-2025-0007' AND i.codigo_insumo='INS013';
INSERT INTO detalle_orden_compra (oc_id, insumo_id, cantidad, precio_unitario, descuento)
SELECT o.oc_id, i.insumo_id, 1000, 45, 0
  FROM ordenes_compra o, insumos i
  WHERE o.numero_oc='OC-2025-0007' AND i.codigo_insumo='INS014';
INSERT INTO detalle_orden_compra (oc_id, insumo_id, cantidad, precio_unitario, descuento)
SELECT o.oc_id, i.insumo_id, 800, 2550, 0
  FROM ordenes_compra o, insumos i
  WHERE o.numero_oc='OC-2025-0008' AND i.codigo_insumo='INS001';
INSERT INTO detalle_orden_compra (oc_id, insumo_id, cantidad, precio_unitario, descuento)
SELECT o.oc_id, i.insumo_id, 50, 45000, 0
  FROM ordenes_compra o, insumos i
  WHERE o.numero_oc='OC-2025-0008' AND i.codigo_insumo='INS003';
INSERT INTO detalle_orden_compra (oc_id, insumo_id, cantidad, precio_unitario, descuento)
SELECT o.oc_id, i.insumo_id, 300, 1800, 0
  FROM ordenes_compra o, insumos i
  WHERE o.numero_oc='OC-2025-0009' AND i.codigo_insumo='INS011';
INSERT INTO detalle_orden_compra (oc_id, insumo_id, cantidad, precio_unitario, descuento)
SELECT o.oc_id, i.insumo_id, 300, 4.2, 0
  FROM ordenes_compra o, insumos i
  WHERE o.numero_oc='OC-2026-0001' AND i.codigo_insumo='INS002';
INSERT INTO detalle_orden_compra (oc_id, insumo_id, cantidad, precio_unitario, descuento)
SELECT o.oc_id, i.insumo_id, 200, 9950, 0
  FROM ordenes_compra o, insumos i
  WHERE o.numero_oc='OC-2026-0002' AND i.codigo_insumo='INS009';
INSERT INTO detalle_orden_compra (oc_id, insumo_id, cantidad, precio_unitario, descuento)
SELECT o.oc_id, i.insumo_id, 150, 7.8, 0
  FROM ordenes_compra o, insumos i
  WHERE o.numero_oc='OC-2026-0003' AND i.codigo_insumo='INS006';
INSERT INTO detalle_orden_compra (oc_id, insumo_id, cantidad, precio_unitario, descuento)
SELECT o.oc_id, i.insumo_id, 300, 1.6, 0
  FROM ordenes_compra o, insumos i
  WHERE o.numero_oc='OC-2026-0003' AND i.codigo_insumo='INS012';

-- 9) recepciones y detalle_recepcion (respetan recepcion acumulada <= solicitado)
INSERT INTO recepciones (oc_id, fecha_recepcion, estado)
SELECT o.oc_id, DATE '2025-01-28', 'CONFORME' FROM ordenes_compra o WHERE o.numero_oc='OC-2025-0001';
INSERT INTO detalle_recepcion (recepcion_id, detalle_id, cantidad_recibida, cantidad_rechazada, estado)
SELECT r.recepcion_id, d.detalle_id, 500, 0, 'OK'
  FROM recepciones r
  JOIN ordenes_compra o ON o.oc_id = r.oc_id
  JOIN detalle_orden_compra d ON d.oc_id = o.oc_id
  JOIN insumos i ON i.insumo_id = d.insumo_id
  WHERE o.numero_oc='OC-2025-0001' AND i.codigo_insumo='INS001' AND r.fecha_recepcion=DATE '2025-01-28';
INSERT INTO detalle_recepcion (recepcion_id, detalle_id, cantidad_recibida, cantidad_rechazada, estado)
SELECT r.recepcion_id, d.detalle_id, 200, 0, 'OK'
  FROM recepciones r
  JOIN ordenes_compra o ON o.oc_id = r.oc_id
  JOIN detalle_orden_compra d ON d.oc_id = o.oc_id
  JOIN insumos i ON i.insumo_id = d.insumo_id
  WHERE o.numero_oc='OC-2025-0001' AND i.codigo_insumo='INS002' AND r.fecha_recepcion=DATE '2025-01-28';

INSERT INTO recepciones (oc_id, fecha_recepcion, estado)
SELECT o.oc_id, DATE '2025-02-24', 'CONFORME' FROM ordenes_compra o WHERE o.numero_oc='OC-2025-0002';
INSERT INTO detalle_recepcion (recepcion_id, detalle_id, cantidad_recibida, cantidad_rechazada, estado)
SELECT r.recepcion_id, d.detalle_id, 2000, 0, 'OK'
  FROM recepciones r
  JOIN ordenes_compra o ON o.oc_id = r.oc_id
  JOIN detalle_orden_compra d ON d.oc_id = o.oc_id
  JOIN insumos i ON i.insumo_id = d.insumo_id
  WHERE o.numero_oc='OC-2025-0002' AND i.codigo_insumo='INS004' AND r.fecha_recepcion=DATE '2025-02-24';
INSERT INTO detalle_recepcion (recepcion_id, detalle_id, cantidad_recibida, cantidad_rechazada, estado)
SELECT r.recepcion_id, d.detalle_id, 2000, 0, 'OK'
  FROM recepciones r
  JOIN ordenes_compra o ON o.oc_id = r.oc_id
  JOIN detalle_orden_compra d ON d.oc_id = o.oc_id
  JOIN insumos i ON i.insumo_id = d.insumo_id
  WHERE o.numero_oc='OC-2025-0002' AND i.codigo_insumo='INS005' AND r.fecha_recepcion=DATE '2025-02-24';
INSERT INTO detalle_recepcion (recepcion_id, detalle_id, cantidad_recibida, cantidad_rechazada, estado)
SELECT r.recepcion_id, d.detalle_id, 1500, 0, 'OK'
  FROM recepciones r
  JOIN ordenes_compra o ON o.oc_id = r.oc_id
  JOIN detalle_orden_compra d ON d.oc_id = o.oc_id
  JOIN insumos i ON i.insumo_id = d.insumo_id
  WHERE o.numero_oc='OC-2025-0002' AND i.codigo_insumo='INS015' AND r.fecha_recepcion=DATE '2025-02-24';

INSERT INTO recepciones (oc_id, fecha_recepcion, estado)
SELECT o.oc_id, DATE '2025-03-25', 'CON_DIFERENCIAS' FROM ordenes_compra o WHERE o.numero_oc='OC-2025-0003';
INSERT INTO detalle_recepcion (recepcion_id, detalle_id, cantidad_recibida, cantidad_rechazada, estado)
SELECT r.recepcion_id, d.detalle_id, 200, 20, 'PARCIAL'
  FROM recepciones r
  JOIN ordenes_compra o ON o.oc_id = r.oc_id
  JOIN detalle_orden_compra d ON d.oc_id = o.oc_id
  JOIN insumos i ON i.insumo_id = d.insumo_id
  WHERE o.numero_oc='OC-2025-0003' AND i.codigo_insumo='INS007' AND r.fecha_recepcion=DATE '2025-03-25';
INSERT INTO detalle_recepcion (recepcion_id, detalle_id, cantidad_recibida, cantidad_rechazada, estado)
SELECT r.recepcion_id, d.detalle_id, 200, 0, 'OK'
  FROM recepciones r
  JOIN ordenes_compra o ON o.oc_id = r.oc_id
  JOIN detalle_orden_compra d ON d.oc_id = o.oc_id
  JOIN insumos i ON i.insumo_id = d.insumo_id
  WHERE o.numero_oc='OC-2025-0003' AND i.codigo_insumo='INS008' AND r.fecha_recepcion=DATE '2025-03-25';

INSERT INTO recepciones (oc_id, fecha_recepcion, estado)
SELECT o.oc_id, DATE '2025-04-25', 'CONFORME' FROM ordenes_compra o WHERE o.numero_oc='OC-2025-0004';
INSERT INTO detalle_recepcion (recepcion_id, detalle_id, cantidad_recibida, cantidad_rechazada, estado)
SELECT r.recepcion_id, d.detalle_id, 150, 0, 'OK'
  FROM recepciones r
  JOIN ordenes_compra o ON o.oc_id = r.oc_id
  JOIN detalle_orden_compra d ON d.oc_id = o.oc_id
  JOIN insumos i ON i.insumo_id = d.insumo_id
  WHERE o.numero_oc='OC-2025-0004' AND i.codigo_insumo='INS009' AND r.fecha_recepcion=DATE '2025-04-25';

INSERT INTO recepciones (oc_id, fecha_recepcion, estado)
SELECT o.oc_id, DATE '2025-05-20', 'CONFORME' FROM ordenes_compra o WHERE o.numero_oc='OC-2025-0005';
INSERT INTO detalle_recepcion (recepcion_id, detalle_id, cantidad_recibida, cantidad_rechazada, estado)
SELECT r.recepcion_id, d.detalle_id, 120, 0, 'OK'
  FROM recepciones r
  JOIN ordenes_compra o ON o.oc_id = r.oc_id
  JOIN detalle_orden_compra d ON d.oc_id = o.oc_id
  JOIN insumos i ON i.insumo_id = d.insumo_id
  WHERE o.numero_oc='OC-2025-0005' AND i.codigo_insumo='INS010' AND r.fecha_recepcion=DATE '2025-05-20';


INSERT INTO recepciones (oc_id, fecha_recepcion, estado)
SELECT o.oc_id, DATE '2025-07-16', 'CONFORME' FROM ordenes_compra o WHERE o.numero_oc='OC-2025-0007';
INSERT INTO detalle_recepcion (recepcion_id, detalle_id, cantidad_recibida, cantidad_rechazada, estado)
SELECT r.recepcion_id, d.detalle_id, 500, 0, 'OK'
  FROM recepciones r
  JOIN ordenes_compra o ON o.oc_id = r.oc_id
  JOIN detalle_orden_compra d ON d.oc_id = o.oc_id
  JOIN insumos i ON i.insumo_id = d.insumo_id
  WHERE o.numero_oc='OC-2025-0007' AND i.codigo_insumo='INS013' AND r.fecha_recepcion=DATE '2025-07-16';
INSERT INTO detalle_recepcion (recepcion_id, detalle_id, cantidad_recibida, cantidad_rechazada, estado)
SELECT r.recepcion_id, d.detalle_id, 1000, 0, 'OK'
  FROM recepciones r
  JOIN ordenes_compra o ON o.oc_id = r.oc_id
  JOIN detalle_orden_compra d ON d.oc_id = o.oc_id
  JOIN insumos i ON i.insumo_id = d.insumo_id
  WHERE o.numero_oc='OC-2025-0007' AND i.codigo_insumo='INS014' AND r.fecha_recepcion=DATE '2025-07-16';

INSERT INTO recepciones (oc_id, fecha_recepcion, estado)
SELECT o.oc_id, DATE '2025-10-14', 'CON_DIFERENCIAS' FROM ordenes_compra o WHERE o.numero_oc='OC-2025-0008';
INSERT INTO detalle_recepcion (recepcion_id, detalle_id, cantidad_recibida, cantidad_rechazada, estado)
SELECT r.recepcion_id, d.detalle_id, 500, 0, 'PARCIAL'
  FROM recepciones r
  JOIN ordenes_compra o ON o.oc_id = r.oc_id
  JOIN detalle_orden_compra d ON d.oc_id = o.oc_id
  JOIN insumos i ON i.insumo_id = d.insumo_id
  WHERE o.numero_oc='OC-2025-0008' AND i.codigo_insumo='INS001' AND r.fecha_recepcion=DATE '2025-10-14';
INSERT INTO detalle_recepcion (recepcion_id, detalle_id, cantidad_recibida, cantidad_rechazada, estado)
SELECT r.recepcion_id, d.detalle_id, 50, 0, 'OK'
  FROM recepciones r
  JOIN ordenes_compra o ON o.oc_id = r.oc_id
  JOIN detalle_orden_compra d ON d.oc_id = o.oc_id
  JOIN insumos i ON i.insumo_id = d.insumo_id
  WHERE o.numero_oc='OC-2025-0008' AND i.codigo_insumo='INS003' AND r.fecha_recepcion=DATE '2025-10-14';


INSERT INTO recepciones (oc_id, fecha_recepcion, estado)
SELECT o.oc_id, DATE '2026-02-01', 'CONFORME' FROM ordenes_compra o WHERE o.numero_oc='OC-2026-0001';
INSERT INTO detalle_recepcion (recepcion_id, detalle_id, cantidad_recibida, cantidad_rechazada, estado)
SELECT r.recepcion_id, d.detalle_id, 300, 0, 'OK'
  FROM recepciones r
  JOIN ordenes_compra o ON o.oc_id = r.oc_id
  JOIN detalle_orden_compra d ON d.oc_id = o.oc_id
  JOIN insumos i ON i.insumo_id = d.insumo_id
  WHERE o.numero_oc='OC-2026-0001' AND i.codigo_insumo='INS002' AND r.fecha_recepcion=DATE '2026-02-01';

INSERT INTO recepciones (oc_id, fecha_recepcion, estado)
SELECT o.oc_id, DATE '2026-03-28', 'CONFORME' FROM ordenes_compra o WHERE o.numero_oc='OC-2026-0002';
INSERT INTO detalle_recepcion (recepcion_id, detalle_id, cantidad_recibida, cantidad_rechazada, estado)
SELECT r.recepcion_id, d.detalle_id, 200, 0, 'OK'
  FROM recepciones r
  JOIN ordenes_compra o ON o.oc_id = r.oc_id
  JOIN detalle_orden_compra d ON d.oc_id = o.oc_id
  JOIN insumos i ON i.insumo_id = d.insumo_id
  WHERE o.numero_oc='OC-2026-0002' AND i.codigo_insumo='INS009' AND r.fecha_recepcion=DATE '2026-03-28';


-- 10) Recalcular subtotal / impuesto (IVA 19%) / total de cada orden desde su detalle
UPDATE ordenes_compra o SET
  subtotal = s.sub,
  impuesto = ROUND(s.sub * 0.19, 2),
  total    = s.sub + ROUND(s.sub * 0.19, 2)
FROM (SELECT oc_id, SUM(subtotal) AS sub FROM detalle_orden_compra GROUP BY oc_id) s
WHERE o.oc_id = s.oc_id;

-- Fin de seed.sql
