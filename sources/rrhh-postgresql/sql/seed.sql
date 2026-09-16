-- ============================================================
-- INDUSTRIAS ABC
-- Sistema Operacional de Recursos Humanos
-- Motor: PostgreSQL 16
-- Archivo: seed.sql
-- Referencia: Universo Empresarial Master v0.2
-- ============================================================

BEGIN;

-- ============================================================
-- 1. CENTROS DE COSTO
-- ============================================================

INSERT INTO centros_costo (
    codigo_centro_costo,
    nombre_centro_costo
)
VALUES
    ('CC001', 'Administración General'),
    ('CC002', 'Recursos Humanos'),
    ('CC003', 'Finanzas'),
    ('CC004', 'Abastecimiento'),
    ('CC005', 'Planta de Producción'),
    ('CC006', 'Mantención Industrial'),
    ('CC007', 'Logística y Bodega')
ON CONFLICT (codigo_centro_costo) DO NOTHING;


-- ============================================================
-- 2. ÁREAS
-- ============================================================

INSERT INTO areas (
    codigo_area,
    nombre_area,
    gerencia,
    centro_costo_id
)
SELECT
    datos.codigo_area,
    datos.nombre_area,
    datos.gerencia,
    cc.centro_costo_id
FROM (
    VALUES
        ('A01', 'Administración',
         'Gerencia General', 'CC001'),

        ('A02', 'Recursos Humanos',
         'Gerencia de Personas', 'CC002'),

        ('A03', 'Finanzas y Contabilidad',
         'Gerencia de Administración y Finanzas', 'CC003'),

        ('A04', 'Compras y Abastecimiento',
         'Gerencia de Operaciones', 'CC004'),

        ('A05', 'Producción',
         'Gerencia de Operaciones', 'CC005'),

        ('A06', 'Mantención',
         'Gerencia de Operaciones', 'CC006'),

        ('A07', 'Logística',
         'Gerencia de Operaciones', 'CC007')
) AS datos (
    codigo_area,
    nombre_area,
    gerencia,
    codigo_centro_costo
)
JOIN centros_costo cc
    ON cc.codigo_centro_costo = datos.codigo_centro_costo
ON CONFLICT (codigo_area) DO NOTHING;


-- ============================================================
-- 3. CARGOS
-- ============================================================

INSERT INTO cargos (
    codigo_cargo,
    nombre_cargo,
    nivel,
    sueldo_base_referencial
)
VALUES
    ('C01', 'Gerente General',
     'Dirección', 3500000.00),

    ('C02', 'Jefe de Área',
     'Jefatura', 2200000.00),

    ('C03', 'Analista Administrativo',
     'Profesional', 1400000.00),

    ('C04', 'Analista de Recursos Humanos',
     'Profesional', 1450000.00),

    ('C05', 'Analista Contable',
     'Profesional', 1500000.00),

    ('C06', 'Encargado de Compras',
     'Profesional', 1550000.00),

    ('C07', 'Operador de Producción',
     'Operativo', 850000.00),

    ('C08', 'Supervisor de Producción',
     'Jefatura', 1650000.00),

    ('C09', 'Técnico de Mantención',
     'Técnico', 1200000.00),

    ('C10', 'Encargado de Bodega',
     'Técnico', 1150000.00),

    ('C11', 'Operador Logístico',
     'Operativo', 900000.00),

    ('C12', 'Asistente Administrativo',
     'Administrativo', 950000.00)
ON CONFLICT (codigo_cargo) DO NOTHING;


-- ============================================================
-- 4. EMPLEADOS
-- ============================================================
-- Los IDs internos de área y cargo NO se suponen.
-- Se resuelven mediante codigo_area y codigo_cargo.
-- ============================================================

INSERT INTO empleados (
    rut,
    nombres,
    apellido_paterno,
    apellido_materno,
    fecha_nacimiento,
    sexo,
    nacionalidad,
    fecha_ingreso,
    fecha_salida,
    area_id,
    cargo_id,
    estado
)
SELECT
    datos.rut,
    datos.nombres,
    datos.apellido_paterno,
    datos.apellido_materno,
    datos.fecha_nacimiento,
    datos.sexo,
    datos.nacionalidad,
    datos.fecha_ingreso,
    datos.fecha_salida,
    a.area_id,
    c.cargo_id,
    datos.estado
FROM (
    VALUES
    -- ========================================================
    -- A01 - ADMINISTRACIÓN
    -- ========================================================

    ('15000984-7','Paula','Civil','Martínez',
     DATE '2002-02-01','F','Chilena',
     DATE '2019-06-07',NULL,'A01','C01','ACTIVO'),

    ('15001968-0','Alejandro','Valenzuela','Sepúlveda',
     DATE '1998-09-21','M','Chileno',
     DATE '2018-09-01',NULL,'A01','C03','ACTIVO'),

    ('15002952-K','Francisca','González','González',
     DATE '1979-02-02','F','Chilena',
     DATE '2025-11-11',NULL,'A01','C12','ACTIVO'),

    ('15003936-3','Luis','Contreras','Sepúlveda',
     DATE '1995-11-01','M','Chileno',
     DATE '2023-07-26',NULL,'A01','C03','ACTIVO'),

    ('15004920-2','Patricia','Muñoz','Civil',
     DATE '1996-08-17','F','Chilena',
     DATE '2022-06-03',NULL,'A01','C03','ACTIVO'),

    ('15005904-6','Nicolás','Morales','San Martín',
     DATE '1983-07-23','M','Chileno',
     DATE '2024-05-25',NULL,'A01','C12','ACTIVO'),

    ('15006797-9','Sebastián','Muñoz','Martínez',
     DATE '1966-04-14','M','Chileno',
     DATE '2024-03-26',NULL,'A01','C02','ACTIVO'),


    -- ========================================================
    -- A02 - RECURSOS HUMANOS
    -- ========================================================

    ('15007781-8','Juan','Carrasco','Martínez',
     DATE '1985-04-14','M','Chileno',
     DATE '2023-05-20',NULL,'A02','C02','ACTIVO'),

    ('15008765-1','Andrea','Osses','Díaz',
     DATE '1966-02-20','F','Chilena',
     DATE '2024-07-18',DATE '2025-02-15',
     'A02','C12','INACTIVO'),

    ('15009749-5','Catalina','Carrasco','Henríquez',
     DATE '1985-09-15','F','Chilena',
     DATE '2025-01-27',NULL,'A02','C04','ACTIVO'),

    ('15010733-4','Valentina','Fuentes','San Martín',
     DATE '1976-01-24','F','Chilena',
     DATE '2021-03-26',NULL,'A02','C12','ACTIVO'),

    ('15011717-8','Andrea','Silva','Martínez',
     DATE '1965-05-18','F','Chilena',
     DATE '2021-08-14',NULL,'A02','C12','ACTIVO'),

    ('15012701-7','Constanza','Gutiérrez','Castro',
     DATE '2003-12-18','F','Chilena',
     DATE '2024-09-07',NULL,'A02','C04','ACTIVO'),


    -- ========================================================
    -- A03 - FINANZAS Y CONTABILIDAD
    -- ========================================================

    ('15013594-K','Valentina','Silva','Muñoz',
     DATE '1966-12-10','F','Chilena',
     DATE '2026-06-22',NULL,'A03','C02','ACTIVO'),

    ('15014578-3','Verónica','Castillo','Fuentes',
     DATE '2004-04-27','F','Chilena',
     DATE '2025-07-23',NULL,'A03','C12','ACTIVO'),

    ('15015562-2','María','Osses','Pérez',
     DATE '1997-06-05','F','Chilena',
     DATE '2021-04-22',NULL,'A03','C05','ACTIVO'),

    ('15016546-6','Pedro','Mendoza','Medina',
     DATE '1968-05-21','M','Chileno',
     DATE '2026-01-01',NULL,'A03','C05','ACTIVO'),

    ('15017530-5','Francisca','Fuentes','Castillo',
     DATE '1978-08-21','F','Chilena',
     DATE '2016-06-10',DATE '2025-08-28',
     'A03','C02','INACTIVO'),

    ('15018514-9','Verónica','Torres','Castillo',
     DATE '1968-06-11','F','Chilena',
     DATE '2022-04-14',NULL,'A03','C05','ACTIVO'),

    ('15019498-9','Álvaro','Mendoza','Medina',
     DATE '2000-11-23','M','Chileno',
     DATE '2024-12-10',NULL,'A03','C02','ACTIVO'),

    ('15020391-0','Marcela','Figueroa','Bravo',
     DATE '1981-12-17','F','Venezolana',
     DATE '2022-01-08',NULL,'A03','C12','ACTIVO'),


    -- ========================================================
    -- A04 - COMPRAS Y ABASTECIMIENTO
    -- ========================================================

    ('15021375-4','Sebastián','Silva','Jara',
     DATE '2001-07-20','M','Chileno',
     DATE '2026-04-04',NULL,'A04','C02','ACTIVO'),

    ('15022359-8','Carlos','Torres','López',
     DATE '1989-11-23','M','Chileno',
     DATE '2024-02-15',NULL,'A04','C06','ACTIVO'),

    ('15023343-7','Sebastián','Martínez','Henríquez',
     DATE '1986-12-28','M','Chileno',
     DATE '2026-06-25',NULL,'A04','C12','ACTIVO'),

    ('15024327-0','Rodrigo','Rodríguez','Soto',
     DATE '2004-10-01','M','Chileno',
     DATE '2016-11-04',NULL,'A04','C02','ACTIVO'),

    ('15025311-K','Paula','López','Contreras',
     DATE '1968-05-06','F','Chilena',
     DATE '2024-07-04',NULL,'A04','C06','ACTIVO'),

    ('15026295-K','René','Fuentes','Civil',
     DATE '1978-04-17','M','Colombiana',
     DATE '2025-10-15',DATE '2026-04-02',
     'A04','C12','INACTIVO'),

    ('15027188-6','Jorge','Soto','López',
     DATE '1990-09-02','M','Chileno',
     DATE '2025-05-12',NULL,'A04','C02','ACTIVO'),

    ('15028172-5','Pilar','San Martín','Medina',
     DATE '1978-02-25','F','Chilena',
     DATE '2017-05-21',NULL,'A04','C12','ACTIVO'),

    ('15029156-9','Nicolás','Rodríguez','Castillo',
     DATE '1970-03-03','M','Chileno',
     DATE '2023-01-05',NULL,'A04','C12','ACTIVO'),


    -- ========================================================
    -- A05 - PRODUCCIÓN
    -- ========================================================

    ('15030140-8','Macarena','San Martín','Pérez',
     DATE '1994-09-11','F','Chilena',
     DATE '2021-06-02',NULL,'A05','C02','ACTIVO'),

    ('15031124-1','Verónica','Pérez','Figueroa',
     DATE '1990-12-22','F','Chilena',
     DATE '2022-11-21',NULL,'A05','C08','ACTIVO'),

    ('15032108-5','René','Martínez','Valenzuela',
     DATE '2004-09-24','M','Chileno',
     DATE '2025-06-12',NULL,'A05','C08','ACTIVO'),

    ('15033092-0','Luis','Bravo','Osses',
     DATE '1992-07-07','M','Chileno',
     DATE '2024-06-16',NULL,'A05','C08','ACTIVO'),

    ('15033985-5','Eduardo','Medina','Henríquez',
     DATE '1977-10-21','M','Chileno',
     DATE '2024-05-07',NULL,'A05','C02','ACTIVO'),

    ('15034969-9','Natalia','Jara','Reyes',
     DATE '1983-04-21','F','Peruana',
     DATE '2022-01-20',DATE '2025-07-16',
     'A05','C07','INACTIVO'),

    ('15035953-8','Paula','Vásquez','Fuentes',
     DATE '2001-10-26','F','Chilena',
     DATE '2023-09-22',NULL,'A05','C08','ACTIVO'),

    ('15036937-1','Héctor','Díaz','Vega',
     DATE '1975-03-18','M','Chileno',
     DATE '2020-05-18',NULL,'A05','C02','ACTIVO'),

    ('15037921-0','Francisca','Vásquez','Mendoza',
     DATE '1980-03-24','F','Chilena',
     DATE '2025-08-18',NULL,'A05','C07','ACTIVO'),

    ('15038905-4','Pedro','Soto','Medina',
     DATE '1971-04-07','M','Chileno',
     DATE '2018-02-12',NULL,'A05','C08','ACTIVO'),

    ('15039889-4','Felipe','González','Castro',
     DATE '1971-02-26','M','Chileno',
     DATE '2020-03-06',NULL,'A05','C08','ACTIVO'),

    ('15040782-6','Alejandro','Sepúlveda','Ramírez',
     DATE '1976-09-18','M','Chileno',
     DATE '2025-07-06',NULL,'A05','C07','ACTIVO'),

    ('15041766-K','Luis','Araya','Castillo',
     DATE '1994-10-20','M','Chileno',
     DATE '2021-01-06',NULL,'A05','C08','ACTIVO'),

    ('15042750-9','Catalina','Valenzuela','Valenzuela',
     DATE '1994-11-13','F','Chilena',
     DATE '2024-05-17',NULL,'A05','C07','ACTIVO'),

    ('15043734-2','Valentina','Morales','Castillo',
     DATE '1976-04-03','F','Chilena',
     DATE '2025-08-14',DATE '2026-02-27',
     'A05','C02','INACTIVO'),

    ('15044718-6','Álvaro','Gutiérrez','Muñoz',
     DATE '1980-04-26','M','Chileno',
     DATE '2017-07-21',NULL,'A05','C02','ACTIVO'),

    ('15045702-5','Lorena','Vega','Medina',
     DATE '1998-08-21','F','Chilena',
     DATE '2024-09-25',NULL,'A05','C07','ACTIVO'),

    ('15046686-5','Felipe','Espinoza','Vega',
     DATE '1971-06-09','M','Chileno',
     DATE '2021-12-09',NULL,'A05','C02','ACTIVO'),

    ('15047579-1','Natalia','Mardones','Mendoza',
     DATE '1982-12-24','F','Chilena',
     DATE '2025-06-24',NULL,'A05','C07','ACTIVO'),

    ('15048563-0','Ignacio','Castillo','Bravo',
     DATE '1979-08-14','M','Chileno',
     DATE '2023-04-01',NULL,'A05','C07','ACTIVO'),

    ('15049547-4','René','Valenzuela','Jara',
     DATE '2001-03-13','M','Chileno',
     DATE '2016-03-28',NULL,'A05','C02','ACTIVO'),

    ('15050531-3','Natalia','Salazar','López',
     DATE '1965-11-11','F','Chilena',
     DATE '2023-04-08',NULL,'A05','C02','ACTIVO'),

    ('15051515-7','Luis','Mardones','Gutiérrez',
     DATE '1980-03-03','M','Chileno',
     DATE '2021-09-21',NULL,'A05','C08','ACTIVO'),

    ('15052499-7','Carlos','Espinoza','Castillo',
     DATE '1983-04-24','M','Chileno',
     DATE '2019-03-16',DATE '2026-01-21',
     'A05','C02','INACTIVO'),

    ('15053483-6','Sebastián','Morales','López',
     DATE '1992-04-21','M','Chileno',
     DATE '2025-06-19',NULL,'A05','C02','ACTIVO'),

    ('15054376-2','Rodrigo','Carrasco','Civil',
     DATE '1998-11-12','M','Chileno',
     DATE '2023-08-06',NULL,'A05','C08','ACTIVO'),

    ('15055360-1','Pilar','Vega','Pérez',
     DATE '1968-10-23','F','Chilena',
     DATE '2017-10-27',NULL,'A05','C02','ACTIVO'),

    ('15056344-5','Patricia','Torres','Soto',
     DATE '1986-03-14','F','Chilena',
     DATE '2023-05-13',NULL,'A05','C07','ACTIVO'),

    ('15057328-9','René','Gutiérrez','Mendoza',
     DATE '1990-01-15','M','Chileno',
     DATE '2019-10-23',NULL,'A05','C08','ACTIVO'),

    ('15058312-8','Constanza','Figueroa','Reyes',
     DATE '1975-04-05','F','Chilena',
     DATE '2022-10-03',NULL,'A05','C08','ACTIVO'),


    -- ========================================================
    -- A06 - MANTENCIÓN
    -- ========================================================

    ('15059296-8','Patricia','Navarrete','Civil',
     DATE '1990-08-28','F','Chilena',
     DATE '2022-02-21',NULL,'A06','C02','ACTIVO'),

    ('15060280-7','Javiera','Muñoz','Castillo',
     DATE '1965-07-24','F','Argentina',
     DATE '2018-06-09',NULL,'A06','C02','ACTIVO'),

    ('15061173-3','Macarena','Silva','González',
     DATE '1967-10-01','F','Chilena',
     DATE '2024-10-18',DATE '2026-03-04',
     'A06','C09','INACTIVO'),

    ('15062157-7','Cristian','Espinoza','Reyes',
     DATE '1969-09-13','M','Chileno',
     DATE '2023-07-14',NULL,'A06','C09','ACTIVO'),

    ('15063141-6','Macarena','Ramírez','Sepúlveda',
     DATE '1985-02-18','F','Chilena',
     DATE '2023-01-15',NULL,'A06','C02','ACTIVO'),

    ('15064125-K','Fernanda','Vega','Castro',
     DATE '1968-05-26','F','Chilena',
     DATE '2022-03-12',NULL,'A06','C09','ACTIVO'),

    ('15065109-3','Patricia','Salazar','Vásquez',
     DATE '1982-01-20','F','Chilena',
     DATE '2021-08-20',NULL,'A06','C02','ACTIVO'),

    ('15066093-9','Macarena','Civil','Contreras',
     DATE '1969-11-01','F','Chilena',
     DATE '2024-07-23',NULL,'A06','C02','ACTIVO'),

    ('15067077-2','Daniela','Araya','Soto',
     DATE '1980-12-08','F','Chilena',
     DATE '2019-09-18',NULL,'A06','C09','ACTIVO'),

    ('15067970-2','Héctor','Espinoza','Vásquez',
     DATE '2004-09-11','M','Chileno',
     DATE '2022-09-07',NULL,'A06','C02','ACTIVO'),


    -- ========================================================
    -- A07 - LOGÍSTICA
    -- ========================================================

    ('15068954-6','Nicolás','Gutiérrez','Pérez',
     DATE '1967-04-25','M','Chileno',
     DATE '2022-07-13',NULL,'A07','C02','ACTIVO'),

    ('15069938-K','Rodrigo','Soto','Osses',
     DATE '1974-01-09','M','Chileno',
     DATE '2022-06-18',DATE '2026-02-11',
     'A07','C02','INACTIVO'),

    ('15070922-9','Lorena','Espinoza','Vega',
     DATE '1990-07-23','F','Venezolana',
     DATE '2025-02-22',NULL,'A07','C11','ACTIVO'),

    ('15071906-2','René','Díaz','San Martín',
     DATE '1979-10-01','M','Chileno',
     DATE '2025-01-04',NULL,'A07','C02','ACTIVO'),

    ('15072890-8','Valentina','Civil','González',
     DATE '1982-08-22','F','Chilena',
     DATE '2025-10-27',NULL,'A07','C02','ACTIVO'),

    ('15073874-1','Pilar','Gutiérrez','Fuentes',
     DATE '1977-09-02','F','Chilena',
     DATE '2022-07-24',NULL,'A07','C11','ACTIVO'),

    ('15074767-8','Carolina','Castillo','Reyes',
     DATE '1989-12-22','F','Chilena',
     DATE '2025-02-10',NULL,'A07','C02','ACTIVO'),

    ('15075751-7','Miguel','Sepúlveda','Rodríguez',
     DATE '1975-02-08','M','Colombiana',
     DATE '2022-10-07',NULL,'A07','C11','ACTIVO'),

    ('15076735-0','Marcela','Soto','Navarrete',
     DATE '1978-03-18','F','Chilena',
     DATE '2018-08-18',NULL,'A07','C11','ACTIVO'),

    ('15077719-4','Catalina','Henríquez','Medina',
     DATE '2003-07-24','F','Chilena',
     DATE '2025-12-17',NULL,'A07','C10','ACTIVO')

) AS datos (
    rut,
    nombres,
    apellido_paterno,
    apellido_materno,
    fecha_nacimiento,
    sexo,
    nacionalidad,
    fecha_ingreso,
    fecha_salida,
    codigo_area,
    codigo_cargo,
    estado
)
JOIN areas a
    ON a.codigo_area = datos.codigo_area
JOIN cargos c
    ON c.codigo_cargo = datos.codigo_cargo

ON CONFLICT (rut) DO NOTHING;


COMMIT;