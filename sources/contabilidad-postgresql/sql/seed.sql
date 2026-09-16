-- =============================================================================
-- SISTEMA OPERACIONAL DE CONTABILIDAD — INDUSTRIAS ABC
-- Motor: PostgreSQL
-- Archivo: seed.sql
-- Ubicación: sources/contabilidad-postgresql/sql/seed.sql
-- =============================================================================

BEGIN;


-- -----------------------------------------------------------------------------
-- 1. CARGA DE ÁREAS
-- Fuente de referencia: Universo Empresarial Master v0.2
-- -----------------------------------------------------------------------------

INSERT INTO areas (
    area_id,
    codigo_area,
    nombre_area
)
VALUES
    (1, 'A01', 'Administración'),
    (2, 'A02', 'Recursos Humanos'),
    (3, 'A03', 'Finanzas y Contabilidad'),
    (4, 'A04', 'Compras y Abastecimiento'),
    (5, 'A05', 'Producción'),
    (6, 'A06', 'Mantención'),
    (7, 'A07', 'Logística');


-- -----------------------------------------------------------------------------
-- 2. CARGA DE CENTROS DE COSTO
-- Relación 1:1 con Áreas.
-- Los códigos y nombres toman como referencia el Universo Empresarial Master v0.2.
-- El atributo responsable se mantiene NULL porque el Master no define responsables
-- oficiales para los centros de costo.
-- -----------------------------------------------------------------------------

INSERT INTO centros_costo (
    centro_costo_id,
    codigo,
    nombre,
    area_id,
    responsable,
    estado
)
VALUES
    (1, 'CC001', 'Administración General', 1, NULL, 'ACTIVO'),
    (2, 'CC002', 'Recursos Humanos', 2, NULL, 'ACTIVO'),
    (3, 'CC003', 'Finanzas', 3, NULL, 'ACTIVO'),
    (4, 'CC004', 'Abastecimiento', 4, NULL, 'ACTIVO'),
    (5, 'CC005', 'Planta de Producción', 5, NULL, 'ACTIVO'),
    (6, 'CC006', 'Mantención Industrial', 6, NULL, 'ACTIVO'),
    (7, 'CC007', 'Logística y Bodega', 7, NULL, 'ACTIVO');


-- -----------------------------------------------------------------------------
-- 3. PLAN DE CUENTAS JERÁRQUICO
-- Catálogo propio del Sistema Operacional de Contabilidad.
-- No corresponde a un catálogo proveniente del Universo Master.
-- -----------------------------------------------------------------------------


-- -----------------------------------------------------------------------------
-- 3.1 NIVEL 1: CUENTAS RAÍZ
-- cuenta_padre_id = NULL
-- -----------------------------------------------------------------------------

INSERT INTO cuentas_contables (
    cuenta_id,
    codigo_cuenta,
    nombre_cuenta,
    tipo_cuenta,
    grupo,
    nivel,
    cuenta_padre_id,
    estado
)
VALUES
    (1, '1', 'ACTIVO',
     'ACTIVO', 'ACTIVO',
     1, NULL, 'ACTIVA'),

    (2, '2', 'PASIVO',
     'PASIVO', 'PASIVO',
     1, NULL, 'ACTIVA'),

    (3, '3', 'PATRIMONIO',
     'PATRIMONIO', 'PATRIMONIO',
     1, NULL, 'ACTIVA'),

    (4, '4', 'INGRESOS',
     'INGRESOS', 'INGRESOS OPERACIONALES',
     1, NULL, 'ACTIVA'),

    (5, '5', 'COSTOS Y GASTOS',
     'GASTOS', 'GASTOS OPERACIONALES',
     1, NULL, 'ACTIVA');


-- -----------------------------------------------------------------------------
-- 3.2 NIVEL 2: CUENTAS DE AGRUPACIÓN
-- -----------------------------------------------------------------------------

INSERT INTO cuentas_contables (
    cuenta_id,
    codigo_cuenta,
    nombre_cuenta,
    tipo_cuenta,
    grupo,
    nivel,
    cuenta_padre_id,
    estado
)
VALUES
    (10, '1.1', 'ACTIVO CIRCULANTE',
     'ACTIVO', 'ACTIVO',
     2, 1, 'ACTIVA'),

    (11, '1.2', 'ACTIVO FIJO',
     'ACTIVO', 'ACTIVO',
     2, 1, 'ACTIVA'),

    (20, '2.1', 'PASIVO CIRCULANTE',
     'PASIVO', 'PASIVO',
     2, 2, 'ACTIVA'),

    (40, '4.1', 'INGRESOS POR VENTAS',
     'INGRESOS', 'VENTAS',
     2, 4, 'ACTIVA'),

    (50, '5.1', 'COSTOS DE PRODUCCIÓN',
     'COSTOS', 'COSTOS',
     2, 5, 'ACTIVA'),

    (51, '5.2', 'GASTOS DE ADMINISTRACIÓN',
     'GASTOS', 'GASTOS',
     2, 5, 'ACTIVA'),

    (52, '5.3', 'GASTOS DE MANTENCIÓN',
     'GASTOS', 'GASTOS',
     2, 5, 'ACTIVA'),

    (53, '5.4', 'GASTOS DE LOGÍSTICA',
     'GASTOS', 'GASTOS',
     2, 5, 'ACTIVA');


-- -----------------------------------------------------------------------------
-- 3.3 NIVEL 3: CUENTAS IMPUTABLES DE DETALLE
-- -----------------------------------------------------------------------------

INSERT INTO cuentas_contables (
    cuenta_id,
    codigo_cuenta,
    nombre_cuenta,
    tipo_cuenta,
    grupo,
    nivel,
    cuenta_padre_id,
    estado
)
VALUES
    (101, '1.1.01', 'Banco Estado Cuenta Corriente',
     'ACTIVO', 'DISPONIBLE',
     3, 10, 'ACTIVA'),

    (102, '1.1.02', 'Cuentas por Cobrar Clientes',
     'ACTIVO', 'EXIGIBLE',
     3, 10, 'ACTIVA'),

    (201, '2.1.01', 'Proveedores Nacionales',
     'PASIVO', 'OBLIGACIONES',
     3, 20, 'ACTIVA'),

    (202, '2.1.02', 'Remuneraciones por Pagar',
     'PASIVO', 'OBLIGACIONES',
     3, 20, 'ACTIVA'),

    (401, '4.1.01', 'Venta Estructuras Metálicas',
     'INGRESOS', 'VENTAS',
     3, 40, 'ACTIVA'),

    (501, '5.1.01', 'Consumo de Materias Primas',
     'COSTOS', 'PRODUCCIÓN',
     3, 50, 'ACTIVA'),

    (502, '5.1.02', 'Mano de Obra Directa',
     'COSTOS', 'PRODUCCIÓN',
     3, 50, 'ACTIVA'),

    (511, '5.2.01', 'Sueldos Administración',
     'GASTOS', 'ADMINISTRACIÓN',
     3, 51, 'ACTIVA'),

    (512, '5.2.02', 'Servicios Básicos y Arriendos',
     'GASTOS', 'ADMINISTRACIÓN',
     3, 51, 'ACTIVA'),

    (521, '5.3.01', 'Insumos y Repuestos Mantención',
     'GASTOS', 'MANTENCIÓN',
     3, 52, 'ACTIVA'),

    (531, '5.4.01', 'Fletes y Despacho',
     'GASTOS', 'LOGÍSTICA',
     3, 53, 'ACTIVA');


-- -----------------------------------------------------------------------------
-- 4. MOVIMIENTOS CONTABLES OPERACIONALES
-- Datos de prueba con cuadratura global controlada.
--
-- El modelo actual registra movimientos individuales y no posee una entidad
-- asiento_id que permita demostrar formalmente la cuadratura de cada asiento.
-- validaciones.sql comprobará la cuadratura general de los datos de prueba.
-- -----------------------------------------------------------------------------


-- -----------------------------------------------------------------------------
-- MOVIMIENTO DE PRUEBA 1:
-- Pago de sueldos de Administración — Enero 2025
-- -----------------------------------------------------------------------------

INSERT INTO movimientos_contables (
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
)
VALUES
    (
        '2025-01-30',
        511,
        1,
        'LIQUIDACION',
        'NOM-2025-01',
        'Pago de remuneraciones Administración',
        3500000.00,
        0.00,
        'CLP',
        1.0000
    ),
    (
        '2025-01-30',
        101,
        1,
        'TRANSFERENCIA',
        'TR-88910',
        'Transferencia bancaria sueldos Administración',
        0.00,
        3500000.00,
        'CLP',
        1.0000
    );


-- -----------------------------------------------------------------------------
-- MOVIMIENTO DE PRUEBA 2:
-- Compra de acero para Producción — Febrero 2025
-- -----------------------------------------------------------------------------

INSERT INTO movimientos_contables (
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
)
VALUES
    (
        '2025-02-15',
        501,
        5,
        'FACTURA',
        'FAC-76001',
        'Compra de materia prima acero laminado',
        12500000.00,
        0.00,
        'CLP',
        1.0000
    ),
    (
        '2025-02-15',
        201,
        4,
        'FACTURA',
        'FAC-76001',
        'Reconocimiento cuenta por pagar proveedor',
        0.00,
        12500000.00,
        'CLP',
        1.0000
    );


-- -----------------------------------------------------------------------------
-- MOVIMIENTO DE PRUEBA 3:
-- Mantención preventiva de maquinaria — Marzo 2025
-- -----------------------------------------------------------------------------

INSERT INTO movimientos_contables (
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
)
VALUES
    (
        '2025-03-10',
        521,
        6,
        'FACTURA',
        'FAC-33421',
        'Insumos mantención preventiva prensas',
        1800000.00,
        0.00,
        'CLP',
        1.0000
    ),
    (
        '2025-03-10',
        101,
        3,
        'TRANSFERENCIA',
        'TR-90112',
        'Pago mantención mediante transferencia Banco',
        0.00,
        1800000.00,
        'CLP',
        1.0000
    );


-- -----------------------------------------------------------------------------
-- MOVIMIENTO DE PRUEBA 4:
-- Arriendo de grúa horquilla y logística — Abril 2025
-- -----------------------------------------------------------------------------

INSERT INTO movimientos_contables (
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
)
VALUES
    (
        '2025-04-05',
        531,
        7,
        'FACTURA',
        'FAC-55102',
        'Servicio de flete y arriendo equipo bodega',
        950000.00,
        0.00,
        'CLP',
        1.0000
    ),
    (
        '2025-04-05',
        101,
        7,
        'TRANSFERENCIA',
        'TR-91450',
        'Traspaso bancario arriendo grúa',
        0.00,
        950000.00,
        'CLP',
        1.0000
    );


-- -----------------------------------------------------------------------------
-- MOVIMIENTO DE PRUEBA 5:
-- Venta de productos terminados — Mayo 2025
-- -----------------------------------------------------------------------------

INSERT INTO movimientos_contables (
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
)
VALUES
    (
        '2025-05-20',
        102,
        3,
        'FACTURA_VENTA',
        'FV-00101',
        'Emisión factura venta soportes industriales',
        8200000.00,
        0.00,
        'CLP',
        1.0000
    ),
    (
        '2025-05-20',
        401,
        5,
        'FACTURA_VENTA',
        'FV-00101',
        'Reconocimiento ingreso por venta estructuras',
        0.00,
        8200000.00,
        'CLP',
        1.0000
    );


-- -----------------------------------------------------------------------------
-- 5. SINCRONIZACIÓN DE SECUENCIAS DE IDENTIDAD
-- -----------------------------------------------------------------------------
-- Debido a que el seed utiliza IDs explícitos para mantener la estructura
-- jerárquica y las referencias internas, se actualizan las secuencias de las
-- columnas IDENTITY para que futuras inserciones automáticas continúen desde
-- el mayor identificador existente.
-- -----------------------------------------------------------------------------

SELECT setval(
    pg_get_serial_sequence('areas', 'area_id'),
    COALESCE(MAX(area_id), 1)
)
FROM areas;

SELECT setval(
    pg_get_serial_sequence('centros_costo', 'centro_costo_id'),
    COALESCE(MAX(centro_costo_id), 1)
)
FROM centros_costo;

SELECT setval(
    pg_get_serial_sequence('cuentas_contables', 'cuenta_id'),
    COALESCE(MAX(cuenta_id), 1)
)
FROM cuentas_contables;

SELECT setval(
    pg_get_serial_sequence('movimientos_contables', 'movimiento_id'),
    COALESCE(MAX(movimiento_id), 1)
)
FROM movimientos_contables;


COMMIT;