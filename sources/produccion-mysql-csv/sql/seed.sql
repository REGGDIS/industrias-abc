USE industrias_abc_produccion;

-- ------------------------------------------------------------
-- 1. Datos de productos
-- ------------------------------------------------------------

INSERT INTO productos (
    codigo_producto,
    nombre_producto,
    categoria,
    unidad_medida
) VALUES
    ('PROD-001', 'Producto A', 'Línea Industrial', 'UN'),
    ('PROD-002', 'Producto B', 'Línea Industrial', 'UN'),
    ('PROD-003', 'Producto C', 'Línea Industrial', 'UN'),
    ('PROD-004', 'Producto D', 'Línea Especial', 'UN'),
    ('PROD-005', 'Producto E', 'Línea Especial', 'UN');

-- ------------------------------------------------------------
-- 2. Datos de órdenes de producción
--
-- centro_costo_id corresponde a una referencia lógica local.
-- No existe FK física hacia Contabilidad.
-- ------------------------------------------------------------

INSERT INTO ordenes_produccion (
    numero_orden,
    producto_id,
    fecha_inicio,
    fecha_termino,
    cantidad_planificada,
    cantidad_producida,
    cantidad_rechazada,
    estado,
    centro_costo_id
) VALUES
    ('OP-2026-0001', 1, '2026-08-01', '2026-08-03',
     1000.00, 980.00, 20.00, 'TERMINADA', 101),

    ('OP-2026-0002', 2, '2026-08-02', '2026-08-05',
     1500.00, 1470.00, 30.00, 'TERMINADA', 102),

    ('OP-2026-0003', 3, '2026-08-04', '2026-08-07',
     800.00, 790.00, 10.00, 'TERMINADA', 103),

    ('OP-2026-0004', 1, '2026-08-08', '2026-08-10',
     1200.00, 1175.00, 25.00, 'TERMINADA', 101),

    ('OP-2026-0005', 4, '2026-08-10', NULL,
     900.00, 650.00, 15.00, 'EN_PROCESO', 104),

    ('OP-2026-0006', 5, '2026-08-12', NULL,
     700.00, 0.00, 0.00, 'PLANIFICADA', 105),

    ('OP-2026-0007', 2, '2026-08-14', '2026-08-16',
     1100.00, 1080.00, 20.00, 'TERMINADA', 102),

    ('OP-2026-0008', 3, '2026-08-17', NULL,
     950.00, 500.00, 8.00, 'EN_PROCESO', 103);

-- ------------------------------------------------------------
-- 3. Datos de consumo de insumos
--
-- insumo_id corresponde a una referencia lógica local.
-- No existe FK física hacia Compras / Abastecimiento.
-- ------------------------------------------------------------

INSERT INTO consumo_insumos (
    orden_produccion_id,
    insumo_id,
    cantidad_planificada,
    cantidad_consumida,
    fecha_consumo
) VALUES

    -- Orden OP-2026-0001
    (1, 1001, 500.00, 495.00, '2026-08-01'),
    (1, 1002, 250.00, 248.00, '2026-08-02'),
    (1, 1003, 100.00, 100.00, '2026-08-03'),

    -- Orden OP-2026-0002
    (2, 1001, 750.00, 740.00, '2026-08-02'),
    (2, 1004, 300.00, 295.00, '2026-08-04'),
    (2, 1005, 150.00, 150.00, '2026-08-05'),

    -- Orden OP-2026-0003
    (3, 1002, 400.00, 395.00, '2026-08-04'),
    (3, 1003, 180.00, 178.00, '2026-08-06'),

    -- Orden OP-2026-0004
    (4, 1001, 600.00, 590.00, '2026-08-08'),
    (4, 1005, 200.00, 198.00, '2026-08-09'),

    -- Orden OP-2026-0005
    (5, 1004, 450.00, 325.00, '2026-08-10'),
    (5, 1006, 180.00, 130.00, '2026-08-12'),

    -- Orden OP-2026-0006
    (6, 1002, 350.00, 0.00, '2026-08-12'),

    -- Orden OP-2026-0007
    (7, 1001, 550.00, 540.00, '2026-08-14'),
    (7, 1005, 180.00, 176.00, '2026-08-15'),

    -- Orden OP-2026-0008
    (8, 1003, 475.00, 250.00, '2026-08-17'),
    (8, 1006, 190.00, 100.00, '2026-08-18');

