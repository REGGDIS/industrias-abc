/* ============================================================================
   seed.sql — Carga de datos ficticios
   Dominio: Contratos y Remuneraciones
   Motor:   SQL Server
   ----------------------------------------------------------------------------
   Contenido:
   1) Empleado (referencia local, coherente con el Universo Empresarial Master
      v0.2, hoja Empleados). No es el maestro real de personal: ese vive en el
      dominio RRHH; esta copia solo existe para poder poblar Contrato y
      Liquidación con datos ficticios coherentes con el resto del equipo.
   2) ConceptoPago — catálogo de haberes y descuentos habituales.
   3) Contrato + Liquidacion + DetalleLiquidacion — datos ficticios de prueba
      para 21 empleados (1 registro de ejemplo + 20 adicionales).
   Requiere haber ejecutado antes schema.sql.
   ============================================================================ */
USE ContratosRemuneraciones_ABC;
GO

-- ----------------------------------------------------------------------------
-- 1) Empleado (referencia local desde el Universo Empresarial Master v0.2)
-- ----------------------------------------------------------------------------
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP001', N'15000984-7', N'Paula Civil Martínez', N'A01', N'C01', '2019-06-07');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP002', N'15001968-0', N'Alejandro Valenzuela Sepúlveda', N'A01', N'C03', '2018-09-01');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP003', N'15002952-K', N'Francisca González González', N'A01', N'C12', '2025-11-11');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP004', N'15003936-3', N'Luis Contreras Sepúlveda', N'A01', N'C03', '2023-07-26');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP005', N'15004920-2', N'Patricia Muñoz Civil', N'A01', N'C03', '2022-06-03');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP006', N'15005904-6', N'Nicolás Morales San Martín', N'A01', N'C12', '2024-05-25');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP007', N'15006797-9', N'Sebastián Muñoz Martínez', N'A01', N'C02', '2024-03-26');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP008', N'15007781-8', N'Juan Carrasco Martínez', N'A02', N'C02', '2023-05-20');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP009', N'15008765-1', N'Andrea Osses Díaz', N'A02', N'C12', '2024-07-18');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP010', N'15009749-5', N'Catalina Carrasco Henríquez', N'A02', N'C04', '2025-01-27');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP011', N'15010733-4', N'Valentina Fuentes San Martín', N'A02', N'C12', '2021-03-26');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP012', N'15011717-8', N'Andrea Silva Martínez', N'A02', N'C12', '2021-08-14');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP013', N'15012701-7', N'Constanza Gutiérrez Castro', N'A02', N'C04', '2024-09-07');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP014', N'15013594-K', N'Valentina Silva Muñoz', N'A03', N'C02', '2026-06-22');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP015', N'15014578-3', N'Verónica Castillo Fuentes', N'A03', N'C12', '2025-07-23');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP016', N'15015562-2', N'María Osses Pérez', N'A03', N'C05', '2021-04-22');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP017', N'15016546-6', N'Pedro Mendoza Medina', N'A03', N'C05', '2026-01-01');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP018', N'15017530-5', N'Francisca Fuentes Castillo', N'A03', N'C02', '2016-06-10');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP019', N'15018514-9', N'Verónica Torres Castillo', N'A03', N'C05', '2022-04-14');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP020', N'15019498-9', N'Álvaro Mendoza Medina', N'A03', N'C02', '2024-12-10');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP021', N'15020391-0', N'Marcela Figueroa Bravo', N'A03', N'C12', '2022-01-08');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP022', N'15021375-4', N'Sebastián Silva Jara', N'A04', N'C02', '2026-04-04');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP023', N'15022359-8', N'Carlos Torres López', N'A04', N'C06', '2024-02-15');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP024', N'15023343-7', N'Sebastián Martínez Henríquez', N'A04', N'C12', '2026-06-25');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP025', N'15024327-0', N'Rodrigo Rodríguez Soto', N'A04', N'C02', '2016-11-04');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP026', N'15025311-K', N'Paula López Contreras', N'A04', N'C06', '2024-07-04');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP027', N'15026295-K', N'René Fuentes Civil', N'A04', N'C12', '2025-10-15');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP028', N'15027188-6', N'Jorge Soto López', N'A04', N'C02', '2025-05-12');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP029', N'15028172-5', N'Pilar San Martín Medina', N'A04', N'C12', '2017-05-21');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP030', N'15029156-9', N'Nicolás Rodríguez Castillo', N'A04', N'C12', '2023-01-05');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP031', N'15030140-8', N'Macarena San Martín Pérez', N'A05', N'C02', '2021-06-02');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP032', N'15031124-1', N'Verónica Pérez Figueroa', N'A05', N'C08', '2022-11-21');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP033', N'15032108-5', N'René Martínez Valenzuela', N'A05', N'C08', '2025-06-12');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP034', N'15033092-0', N'Luis Bravo Osses', N'A05', N'C08', '2024-06-16');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP035', N'15033985-5', N'Eduardo Medina Henríquez', N'A05', N'C02', '2024-05-07');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP036', N'15034969-9', N'Natalia Jara Reyes', N'A05', N'C07', '2022-01-20');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP037', N'15035953-8', N'Paula Vásquez Fuentes', N'A05', N'C08', '2023-09-22');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP038', N'15036937-1', N'Héctor Díaz Vega', N'A05', N'C02', '2020-05-18');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP039', N'15037921-0', N'Francisca Vásquez Mendoza', N'A05', N'C07', '2025-08-18');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP040', N'15038905-4', N'Pedro Soto Medina', N'A05', N'C08', '2018-02-12');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP041', N'15039889-4', N'Felipe González Castro', N'A05', N'C08', '2020-03-06');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP042', N'15040782-6', N'Alejandro Sepúlveda Ramírez', N'A05', N'C07', '2025-07-06');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP043', N'15041766-K', N'Luis Araya Castillo', N'A05', N'C08', '2021-01-06');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP044', N'15042750-9', N'Catalina Valenzuela Valenzuela', N'A05', N'C07', '2024-05-17');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP045', N'15043734-2', N'Valentina Morales Castillo', N'A05', N'C02', '2025-08-14');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP046', N'15044718-6', N'Álvaro Gutiérrez Muñoz', N'A05', N'C02', '2017-07-21');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP047', N'15045702-5', N'Lorena Vega Medina', N'A05', N'C07', '2024-09-25');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP048', N'15046686-5', N'Felipe Espinoza Vega', N'A05', N'C02', '2021-12-09');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP049', N'15047579-1', N'Natalia Mardones Mendoza', N'A05', N'C07', '2025-06-24');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP050', N'15048563-0', N'Ignacio Castillo Bravo', N'A05', N'C07', '2023-04-01');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP051', N'15049547-4', N'René Valenzuela Jara', N'A05', N'C02', '2016-03-28');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP052', N'15050531-3', N'Natalia Salazar López', N'A05', N'C02', '2023-04-08');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP053', N'15051515-7', N'Luis Mardones Gutiérrez', N'A05', N'C08', '2021-09-21');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP054', N'15052499-7', N'Carlos Espinoza Castillo', N'A05', N'C02', '2019-03-16');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP055', N'15053483-6', N'Sebastián Morales López', N'A05', N'C02', '2025-06-19');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP056', N'15054376-2', N'Rodrigo Carrasco Civil', N'A05', N'C08', '2023-08-06');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP057', N'15055360-1', N'Pilar Vega Pérez', N'A05', N'C02', '2017-10-27');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP058', N'15056344-5', N'Patricia Torres Soto', N'A05', N'C07', '2023-05-13');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP059', N'15057328-9', N'René Gutiérrez Mendoza', N'A05', N'C08', '2019-10-23');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP060', N'15058312-8', N'Constanza Figueroa Reyes', N'A05', N'C08', '2022-10-03');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP061', N'15059296-8', N'Patricia Navarrete Civil', N'A06', N'C02', '2022-02-21');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP062', N'15060280-7', N'Javiera Muñoz Castillo', N'A06', N'C02', '2018-06-09');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP063', N'15061173-3', N'Macarena Silva González', N'A06', N'C09', '2024-10-18');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP064', N'15062157-7', N'Cristian Espinoza Reyes', N'A06', N'C09', '2023-07-14');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP065', N'15063141-6', N'Macarena Ramírez Sepúlveda', N'A06', N'C02', '2023-01-15');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP066', N'15064125-K', N'Fernanda Vega Castro', N'A06', N'C09', '2022-03-12');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP067', N'15065109-3', N'Patricia Salazar Vásquez', N'A06', N'C02', '2021-08-20');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP068', N'15066093-9', N'Macarena Civil Contreras', N'A06', N'C02', '2024-07-23');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP069', N'15067077-2', N'Daniela Araya Soto', N'A06', N'C09', '2019-09-18');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP070', N'15067970-2', N'Héctor Espinoza Vásquez', N'A06', N'C02', '2022-09-07');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP071', N'15068954-6', N'Nicolás Gutiérrez Pérez', N'A07', N'C02', '2022-07-13');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP072', N'15069938-K', N'Rodrigo Soto Osses', N'A07', N'C02', '2022-06-18');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP073', N'15070922-9', N'Lorena Espinoza Vega', N'A07', N'C11', '2025-02-22');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP074', N'15071906-2', N'René Díaz San Martín', N'A07', N'C02', '2025-01-04');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP075', N'15072890-8', N'Valentina Civil González', N'A07', N'C02', '2025-10-27');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP076', N'15073874-1', N'Pilar Gutiérrez Fuentes', N'A07', N'C11', '2022-07-24');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP077', N'15074767-8', N'Carolina Castillo Reyes', N'A07', N'C02', '2025-02-10');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP078', N'15075751-7', N'Miguel Sepúlveda Rodríguez', N'A07', N'C11', '2022-10-07');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP079', N'15076735-0', N'Marcela Soto Navarrete', N'A07', N'C11', '2018-08-18');
INSERT INTO dbo.Empleado (empleado_id, rut_referencia, nombre_completo, codigo_area_ref, codigo_cargo_ref, fecha_ingreso_ref) VALUES (N'EMP080', N'15077719-4', N'Catalina Henríquez Medina', N'A07', N'C10', '2025-12-17');GO


-- ----------------------------------------------------------------------------
-- 2) ConceptoPago (catálogo de haberes y descuentos)
-- ----------------------------------------------------------------------------
INSERT INTO dbo.ConceptoPago (codigo, descripcion, tipo, afecta_imponible) VALUES
(N'BONO_PROD',    N'Bono de producción',            'HABER',     1),
(N'GRATIF_LEGAL', N'Gratificación legal',           'HABER',     1),
(N'COLACION',     N'Colación',                      'HABER',     0),
(N'MOVILIZACION', N'Movilización',                  'HABER',     0),
(N'HORAS_EXTRA',  N'Horas extraordinarias',         'HABER',     1),
(N'DESC_AFP',     N'Descuento cotización AFP',      'DESCUENTO', 0),
(N'DESC_SALUD',   N'Descuento cotización de salud', 'DESCUENTO', 0),
(N'DESC_OTROS',   N'Otros descuentos',              'DESCUENTO', 0);
GO

-- ----------------------------------------------------------------------------
-- 3a) Contrato + Liquidacion + Detalle — registro de ejemplo (EMP001)
-- ----------------------------------------------------------------------------
INSERT INTO dbo.Contrato (empleado_id, numero_contrato, tipo_contrato, fecha_inicio, fecha_termino, jornada, sueldo_base, cargo_contrato, estado)
VALUES (N'EMP001', N'CT-2024-0001', 'INDEFINIDO', '2019-06-07', NULL, 'COMPLETA', 850000, N'Gerente General', 'VIGENTE');

DECLARE @contrato_id INT = SCOPE_IDENTITY();

INSERT INTO dbo.Liquidacion (empleado_id, contrato_id, periodo, sueldo_base, horas_extras, sueldo_imponible, sueldo_liquido, costo_empresa)
VALUES (N'EMP001', @contrato_id, '2026-07', 850000, 4, 950000, 780000, 1050000);

DECLARE @liquidacion_id INT = SCOPE_IDENTITY();

INSERT INTO dbo.DetalleLiquidacion (liquidacion_id, concepto_id, monto)
SELECT @liquidacion_id, concepto_id, monto
FROM (VALUES
    (N'HORAS_EXTRA',  35000),
    (N'GRATIF_LEGAL', 65000),
    (N'COLACION',     45000),
    (N'MOVILIZACION', 30000),
    (N'DESC_AFP',      95000),
    (N'DESC_SALUD',    70000)
) AS d(codigo, monto)
JOIN dbo.ConceptoPago cp ON cp.codigo = d.codigo;
GO

-- ----------------------------------------------------------------------------
-- 3b) Contrato + Liquidacion + Detalle — 20 empleados adicionales del Master
-- ----------------------------------------------------------------------------
-- Contratos adicionales (20 empleados reales del Universo Empresarial Master)
INSERT INTO dbo.Contrato (empleado_id, numero_contrato, tipo_contrato, fecha_inicio, fecha_termino, jornada, sueldo_base, cargo_contrato, estado) VALUES (N'EMP002', N'CT-2024-0002', 'PLAZO_FIJO', '2018-09-01', '2026-12-08', 'COMPLETA', 1439000, N'Analista Administrativo', 'VIGENTE');
INSERT INTO dbo.Contrato (empleado_id, numero_contrato, tipo_contrato, fecha_inicio, fecha_termino, jornada, sueldo_base, cargo_contrato, estado) VALUES (N'EMP003', N'CT-2024-0003', 'INDEFINIDO', '2025-11-11', NULL, 'COMPLETA', 907000, N'Asistente Administrativo', 'VIGENTE');
INSERT INTO dbo.Contrato (empleado_id, numero_contrato, tipo_contrato, fecha_inicio, fecha_termino, jornada, sueldo_base, cargo_contrato, estado) VALUES (N'EMP004', N'CT-2024-0004', 'INDEFINIDO', '2023-07-26', NULL, 'COMPLETA', 1466000, N'Analista Administrativo', 'VIGENTE');
INSERT INTO dbo.Contrato (empleado_id, numero_contrato, tipo_contrato, fecha_inicio, fecha_termino, jornada, sueldo_base, cargo_contrato, estado) VALUES (N'EMP005', N'CT-2024-0005', 'INDEFINIDO', '2022-06-03', NULL, 'COMPLETA', 1378000, N'Analista Administrativo', 'VIGENTE');
INSERT INTO dbo.Contrato (empleado_id, numero_contrato, tipo_contrato, fecha_inicio, fecha_termino, jornada, sueldo_base, cargo_contrato, estado) VALUES (N'EMP006', N'CT-2024-0006', 'INDEFINIDO', '2024-05-25', NULL, 'COMPLETA', 896000, N'Asistente Administrativo', 'VIGENTE');
INSERT INTO dbo.Contrato (empleado_id, numero_contrato, tipo_contrato, fecha_inicio, fecha_termino, jornada, sueldo_base, cargo_contrato, estado) VALUES (N'EMP007', N'CT-2024-0007', 'INDEFINIDO', '2024-03-26', NULL, 'PARCIAL', 2067000, N'Jefe de Área', 'VIGENTE');
INSERT INTO dbo.Contrato (empleado_id, numero_contrato, tipo_contrato, fecha_inicio, fecha_termino, jornada, sueldo_base, cargo_contrato, estado) VALUES (N'EMP008', N'CT-2024-0008', 'INDEFINIDO', '2023-05-20', NULL, 'COMPLETA', 2177000, N'Jefe de Área', 'VIGENTE');
INSERT INTO dbo.Contrato (empleado_id, numero_contrato, tipo_contrato, fecha_inicio, fecha_termino, jornada, sueldo_base, cargo_contrato, estado) VALUES (N'EMP009', N'CT-2024-0009', 'PLAZO_FIJO', '2024-07-18', '2025-02-15', 'COMPLETA', 999000, N'Asistente Administrativo', 'TERMINADO');
INSERT INTO dbo.Contrato (empleado_id, numero_contrato, tipo_contrato, fecha_inicio, fecha_termino, jornada, sueldo_base, cargo_contrato, estado) VALUES (N'EMP010', N'CT-2024-0010', 'INDEFINIDO', '2025-01-27', NULL, 'COMPLETA', 1507000, N'Analista de Recursos Humanos', 'VIGENTE');
INSERT INTO dbo.Contrato (empleado_id, numero_contrato, tipo_contrato, fecha_inicio, fecha_termino, jornada, sueldo_base, cargo_contrato, estado) VALUES (N'EMP011', N'CT-2024-0011', 'INDEFINIDO', '2021-03-26', NULL, 'COMPLETA', 884000, N'Asistente Administrativo', 'VIGENTE');
INSERT INTO dbo.Contrato (empleado_id, numero_contrato, tipo_contrato, fecha_inicio, fecha_termino, jornada, sueldo_base, cargo_contrato, estado) VALUES (N'EMP012', N'CT-2024-0012', 'PLAZO_FIJO', '2021-08-14', '2026-09-18', 'COMPLETA', 872000, N'Asistente Administrativo', 'VIGENTE');
INSERT INTO dbo.Contrato (empleado_id, numero_contrato, tipo_contrato, fecha_inicio, fecha_termino, jornada, sueldo_base, cargo_contrato, estado) VALUES (N'EMP013', N'CT-2024-0013', 'INDEFINIDO', '2024-09-07', NULL, 'COMPLETA', 1550000, N'Analista de Recursos Humanos', 'VIGENTE');
INSERT INTO dbo.Contrato (empleado_id, numero_contrato, tipo_contrato, fecha_inicio, fecha_termino, jornada, sueldo_base, cargo_contrato, estado) VALUES (N'EMP014', N'CT-2024-0014', 'INDEFINIDO', '2026-06-22', NULL, 'COMPLETA', 2301000, N'Jefe de Área', 'VIGENTE');
INSERT INTO dbo.Contrato (empleado_id, numero_contrato, tipo_contrato, fecha_inicio, fecha_termino, jornada, sueldo_base, cargo_contrato, estado) VALUES (N'EMP015', N'CT-2024-0015', 'PLAZO_FIJO', '2025-07-23', '2026-09-15', 'COMPLETA', 869000, N'Asistente Administrativo', 'VIGENTE');
INSERT INTO dbo.Contrato (empleado_id, numero_contrato, tipo_contrato, fecha_inicio, fecha_termino, jornada, sueldo_base, cargo_contrato, estado) VALUES (N'EMP016', N'CT-2024-0016', 'INDEFINIDO', '2021-04-22', NULL, 'COMPLETA', 1535000, N'Analista Contable', 'VIGENTE');
INSERT INTO dbo.Contrato (empleado_id, numero_contrato, tipo_contrato, fecha_inicio, fecha_termino, jornada, sueldo_base, cargo_contrato, estado) VALUES (N'EMP017', N'CT-2024-0017', 'INDEFINIDO', '2026-01-01', NULL, 'COMPLETA', 1407000, N'Analista Contable', 'VIGENTE');
INSERT INTO dbo.Contrato (empleado_id, numero_contrato, tipo_contrato, fecha_inicio, fecha_termino, jornada, sueldo_base, cargo_contrato, estado) VALUES (N'EMP018', N'CT-2024-0018', 'PLAZO_FIJO', '2016-06-10', '2025-08-28', 'COMPLETA', 2270000, N'Jefe de Área', 'TERMINADO');
INSERT INTO dbo.Contrato (empleado_id, numero_contrato, tipo_contrato, fecha_inicio, fecha_termino, jornada, sueldo_base, cargo_contrato, estado) VALUES (N'EMP019', N'CT-2024-0019', 'PLAZO_FIJO', '2022-04-14', '2026-09-22', 'COMPLETA', 1645000, N'Analista Contable', 'VIGENTE');
INSERT INTO dbo.Contrato (empleado_id, numero_contrato, tipo_contrato, fecha_inicio, fecha_termino, jornada, sueldo_base, cargo_contrato, estado) VALUES (N'EMP020', N'CT-2024-0020', 'INDEFINIDO', '2024-12-10', NULL, 'PARCIAL', 2147000, N'Jefe de Área', 'VIGENTE');
INSERT INTO dbo.Contrato (empleado_id, numero_contrato, tipo_contrato, fecha_inicio, fecha_termino, jornada, sueldo_base, cargo_contrato, estado) VALUES (N'EMP021', N'CT-2024-0021', 'TEMPORAL', '2022-01-08', NULL, 'COMPLETA', 1013000, N'Asistente Administrativo', 'VIGENTE');

-- Liquidaciones del período 2026-07 para contratos vigentes
INSERT INTO dbo.Liquidacion (empleado_id, contrato_id, periodo, sueldo_base, horas_extras, sueldo_imponible, sueldo_liquido, costo_empresa) SELECT N'EMP002', contrato_id, '2026-07', 1439000, 8, 1678833, 1488337, 1806448 FROM dbo.Contrato WHERE numero_contrato = N'CT-2024-0002';
INSERT INTO dbo.Liquidacion (empleado_id, contrato_id, periodo, sueldo_base, horas_extras, sueldo_imponible, sueldo_liquido, costo_empresa) SELECT N'EMP003', contrato_id, '2026-07', 907000, 0, 997700, 905358, 1104881 FROM dbo.Contrato WHERE numero_contrato = N'CT-2024-0003';
INSERT INTO dbo.Liquidacion (empleado_id, contrato_id, periodo, sueldo_base, horas_extras, sueldo_imponible, sueldo_liquido, costo_empresa) SELECT N'EMP004', contrato_id, '2026-07', 1466000, 6, 1685900, 1490423, 1813727 FROM dbo.Contrato WHERE numero_contrato = N'CT-2024-0004';
INSERT INTO dbo.Liquidacion (empleado_id, contrato_id, periodo, sueldo_base, horas_extras, sueldo_imponible, sueldo_liquido, costo_empresa) SELECT N'EMP005', contrato_id, '2026-07', 1378000, 0, 1515800, 1336559, 1638524 FROM dbo.Contrato WHERE numero_contrato = N'CT-2024-0005';
INSERT INTO dbo.Liquidacion (empleado_id, contrato_id, periodo, sueldo_base, horas_extras, sueldo_imponible, sueldo_liquido, costo_empresa) SELECT N'EMP006', contrato_id, '2026-07', 896000, 6, 1030400, 940088, 1138562 FROM dbo.Contrato WHERE numero_contrato = N'CT-2024-0006';
INSERT INTO dbo.Liquidacion (empleado_id, contrato_id, periodo, sueldo_base, horas_extras, sueldo_imponible, sueldo_liquido, costo_empresa) SELECT N'EMP007', contrato_id, '2026-07', 2067000, 0, 2273700, 1967338, 2419161 FROM dbo.Contrato WHERE numero_contrato = N'CT-2024-0007';
INSERT INTO dbo.Liquidacion (empleado_id, contrato_id, periodo, sueldo_base, horas_extras, sueldo_imponible, sueldo_liquido, costo_empresa) SELECT N'EMP008', contrato_id, '2026-07', 2177000, 0, 2394700, 2068044, 2543791 FROM dbo.Contrato WHERE numero_contrato = N'CT-2024-0008';
INSERT INTO dbo.Liquidacion (empleado_id, contrato_id, periodo, sueldo_base, horas_extras, sueldo_imponible, sueldo_liquido, costo_empresa) SELECT N'EMP010', contrato_id, '2026-07', 1507000, 2, 1682817, 1479775, 1810552 FROM dbo.Contrato WHERE numero_contrato = N'CT-2024-0010';
INSERT INTO dbo.Liquidacion (empleado_id, contrato_id, periodo, sueldo_base, horas_extras, sueldo_imponible, sueldo_liquido, costo_empresa) SELECT N'EMP011', contrato_id, '2026-07', 884000, 0, 972400, 884302, 1078822 FROM dbo.Contrato WHERE numero_contrato = N'CT-2024-0011';
INSERT INTO dbo.Liquidacion (empleado_id, contrato_id, periodo, sueldo_base, horas_extras, sueldo_imponible, sueldo_liquido, costo_empresa) SELECT N'EMP012', contrato_id, '2026-07', 872000, 2, 973733, 887849, 1080195 FROM dbo.Contrato WHERE numero_contrato = N'CT-2024-0012';
INSERT INTO dbo.Liquidacion (empleado_id, contrato_id, periodo, sueldo_base, horas_extras, sueldo_imponible, sueldo_liquido, costo_empresa) SELECT N'EMP013', contrato_id, '2026-07', 1550000, 0, 1705000, 1494025, 1833400 FROM dbo.Contrato WHERE numero_contrato = N'CT-2024-0013';
INSERT INTO dbo.Liquidacion (empleado_id, contrato_id, periodo, sueldo_base, horas_extras, sueldo_imponible, sueldo_liquido, costo_empresa) SELECT N'EMP014', contrato_id, '2026-07', 2301000, 4, 2607800, 2258266, 2763284 FROM dbo.Contrato WHERE numero_contrato = N'CT-2024-0014';
INSERT INTO dbo.Liquidacion (empleado_id, contrato_id, periodo, sueldo_base, horas_extras, sueldo_imponible, sueldo_liquido, costo_empresa) SELECT N'EMP015', contrato_id, '2026-07', 869000, 8, 1013833, 928503, 1121498 FROM dbo.Contrato WHERE numero_contrato = N'CT-2024-0015';
INSERT INTO dbo.Liquidacion (empleado_id, contrato_id, periodo, sueldo_base, horas_extras, sueldo_imponible, sueldo_liquido, costo_empresa) SELECT N'EMP016', contrato_id, '2026-07', 1535000, 6, 1765250, 1557042, 1895458 FROM dbo.Contrato WHERE numero_contrato = N'CT-2024-0016';
INSERT INTO dbo.Liquidacion (empleado_id, contrato_id, periodo, sueldo_base, horas_extras, sueldo_imponible, sueldo_liquido, costo_empresa) SELECT N'EMP017', contrato_id, '2026-07', 1407000, 0, 1547700, 1363108, 1671381 FROM dbo.Contrato WHERE numero_contrato = N'CT-2024-0017';
INSERT INTO dbo.Liquidacion (empleado_id, contrato_id, periodo, sueldo_base, horas_extras, sueldo_imponible, sueldo_liquido, costo_empresa) SELECT N'EMP019', contrato_id, '2026-07', 1645000, 0, 1809500, 1580998, 1941035 FROM dbo.Contrato WHERE numero_contrato = N'CT-2024-0019';
INSERT INTO dbo.Liquidacion (empleado_id, contrato_id, periodo, sueldo_base, horas_extras, sueldo_imponible, sueldo_liquido, costo_empresa) SELECT N'EMP020', contrato_id, '2026-07', 2147000, 8, 2504833, 2183711, 2657228 FROM dbo.Contrato WHERE numero_contrato = N'CT-2024-0020';
INSERT INTO dbo.Liquidacion (empleado_id, contrato_id, periodo, sueldo_base, horas_extras, sueldo_imponible, sueldo_liquido, costo_empresa) SELECT N'EMP021', contrato_id, '2026-07', 1013000, 2, 1131183, 1019285, 1242368 FROM dbo.Contrato WHERE numero_contrato = N'CT-2024-0021';

-- Detalle de cada liquidación
INSERT INTO dbo.DetalleLiquidacion (liquidacion_id, concepto_id, monto)
SELECT l.liquidacion_id, cp.concepto_id, d.monto
FROM dbo.Liquidacion l
CROSS JOIN (VALUES
    (N'GRATIF_LEGAL', 143900),
    (N'COLACION', 45000),
    (N'MOVILIZACION', 30000),
    (N'DESC_AFP', 164766),
    (N'DESC_SALUD', 100730),
    (N'HORAS_EXTRA', 95933)
) AS d(codigo, monto)
JOIN dbo.ConceptoPago cp ON cp.codigo = d.codigo
WHERE l.empleado_id = N'EMP002' AND l.periodo = '2026-07';
GO
INSERT INTO dbo.DetalleLiquidacion (liquidacion_id, concepto_id, monto)
SELECT l.liquidacion_id, cp.concepto_id, d.monto
FROM dbo.Liquidacion l
CROSS JOIN (VALUES
    (N'GRATIF_LEGAL', 90700),
    (N'COLACION', 45000),
    (N'MOVILIZACION', 30000),
    (N'DESC_AFP', 103852),
    (N'DESC_SALUD', 63490)
) AS d(codigo, monto)
JOIN dbo.ConceptoPago cp ON cp.codigo = d.codigo
WHERE l.empleado_id = N'EMP003' AND l.periodo = '2026-07';
GO
INSERT INTO dbo.DetalleLiquidacion (liquidacion_id, concepto_id, monto)
SELECT l.liquidacion_id, cp.concepto_id, d.monto
FROM dbo.Liquidacion l
CROSS JOIN (VALUES
    (N'GRATIF_LEGAL', 146600),
    (N'COLACION', 45000),
    (N'MOVILIZACION', 30000),
    (N'DESC_AFP', 167857),
    (N'DESC_SALUD', 102620),
    (N'HORAS_EXTRA', 73300)
) AS d(codigo, monto)
JOIN dbo.ConceptoPago cp ON cp.codigo = d.codigo
WHERE l.empleado_id = N'EMP004' AND l.periodo = '2026-07';
GO
INSERT INTO dbo.DetalleLiquidacion (liquidacion_id, concepto_id, monto)
SELECT l.liquidacion_id, cp.concepto_id, d.monto
FROM dbo.Liquidacion l
CROSS JOIN (VALUES
    (N'GRATIF_LEGAL', 137800),
    (N'COLACION', 45000),
    (N'MOVILIZACION', 30000),
    (N'DESC_AFP', 157781),
    (N'DESC_SALUD', 96460)
) AS d(codigo, monto)
JOIN dbo.ConceptoPago cp ON cp.codigo = d.codigo
WHERE l.empleado_id = N'EMP005' AND l.periodo = '2026-07';
GO
INSERT INTO dbo.DetalleLiquidacion (liquidacion_id, concepto_id, monto)
SELECT l.liquidacion_id, cp.concepto_id, d.monto
FROM dbo.Liquidacion l
CROSS JOIN (VALUES
    (N'GRATIF_LEGAL', 89600),
    (N'COLACION', 45000),
    (N'MOVILIZACION', 30000),
    (N'DESC_AFP', 102592),
    (N'DESC_SALUD', 62720),
    (N'HORAS_EXTRA', 44800)
) AS d(codigo, monto)
JOIN dbo.ConceptoPago cp ON cp.codigo = d.codigo
WHERE l.empleado_id = N'EMP006' AND l.periodo = '2026-07';
GO
INSERT INTO dbo.DetalleLiquidacion (liquidacion_id, concepto_id, monto)
SELECT l.liquidacion_id, cp.concepto_id, d.monto
FROM dbo.Liquidacion l
CROSS JOIN (VALUES
    (N'GRATIF_LEGAL', 206700),
    (N'COLACION', 45000),
    (N'MOVILIZACION', 30000),
    (N'DESC_AFP', 236672),
    (N'DESC_SALUD', 144690)
) AS d(codigo, monto)
JOIN dbo.ConceptoPago cp ON cp.codigo = d.codigo
WHERE l.empleado_id = N'EMP007' AND l.periodo = '2026-07';
GO
INSERT INTO dbo.DetalleLiquidacion (liquidacion_id, concepto_id, monto)
SELECT l.liquidacion_id, cp.concepto_id, d.monto
FROM dbo.Liquidacion l
CROSS JOIN (VALUES
    (N'GRATIF_LEGAL', 217700),
    (N'COLACION', 45000),
    (N'MOVILIZACION', 30000),
    (N'DESC_AFP', 249266),
    (N'DESC_SALUD', 152390)
) AS d(codigo, monto)
JOIN dbo.ConceptoPago cp ON cp.codigo = d.codigo
WHERE l.empleado_id = N'EMP008' AND l.periodo = '2026-07';
GO
INSERT INTO dbo.DetalleLiquidacion (liquidacion_id, concepto_id, monto)
SELECT l.liquidacion_id, cp.concepto_id, d.monto
FROM dbo.Liquidacion l
CROSS JOIN (VALUES
    (N'GRATIF_LEGAL', 150700),
    (N'COLACION', 45000),
    (N'MOVILIZACION', 30000),
    (N'DESC_AFP', 172552),
    (N'DESC_SALUD', 105490),
    (N'HORAS_EXTRA', 25117)
) AS d(codigo, monto)
JOIN dbo.ConceptoPago cp ON cp.codigo = d.codigo
WHERE l.empleado_id = N'EMP010' AND l.periodo = '2026-07';
GO
INSERT INTO dbo.DetalleLiquidacion (liquidacion_id, concepto_id, monto)
SELECT l.liquidacion_id, cp.concepto_id, d.monto
FROM dbo.Liquidacion l
CROSS JOIN (VALUES
    (N'GRATIF_LEGAL', 88400),
    (N'COLACION', 45000),
    (N'MOVILIZACION', 30000),
    (N'DESC_AFP', 101218),
    (N'DESC_SALUD', 61880)
) AS d(codigo, monto)
JOIN dbo.ConceptoPago cp ON cp.codigo = d.codigo
WHERE l.empleado_id = N'EMP011' AND l.periodo = '2026-07';
GO
INSERT INTO dbo.DetalleLiquidacion (liquidacion_id, concepto_id, monto)
SELECT l.liquidacion_id, cp.concepto_id, d.monto
FROM dbo.Liquidacion l
CROSS JOIN (VALUES
    (N'GRATIF_LEGAL', 87200),
    (N'COLACION', 45000),
    (N'MOVILIZACION', 30000),
    (N'DESC_AFP', 99844),
    (N'DESC_SALUD', 61040),
    (N'HORAS_EXTRA', 14533)
) AS d(codigo, monto)
JOIN dbo.ConceptoPago cp ON cp.codigo = d.codigo
WHERE l.empleado_id = N'EMP012' AND l.periodo = '2026-07';
GO
INSERT INTO dbo.DetalleLiquidacion (liquidacion_id, concepto_id, monto)
SELECT l.liquidacion_id, cp.concepto_id, d.monto
FROM dbo.Liquidacion l
CROSS JOIN (VALUES
    (N'GRATIF_LEGAL', 155000),
    (N'COLACION', 45000),
    (N'MOVILIZACION', 30000),
    (N'DESC_AFP', 177475),
    (N'DESC_SALUD', 108500)
) AS d(codigo, monto)
JOIN dbo.ConceptoPago cp ON cp.codigo = d.codigo
WHERE l.empleado_id = N'EMP013' AND l.periodo = '2026-07';
GO
INSERT INTO dbo.DetalleLiquidacion (liquidacion_id, concepto_id, monto)
SELECT l.liquidacion_id, cp.concepto_id, d.monto
FROM dbo.Liquidacion l
CROSS JOIN (VALUES
    (N'GRATIF_LEGAL', 230100),
    (N'COLACION', 45000),
    (N'MOVILIZACION', 30000),
    (N'DESC_AFP', 263464),
    (N'DESC_SALUD', 161070),
    (N'HORAS_EXTRA', 76700)
) AS d(codigo, monto)
JOIN dbo.ConceptoPago cp ON cp.codigo = d.codigo
WHERE l.empleado_id = N'EMP014' AND l.periodo = '2026-07';
GO
INSERT INTO dbo.DetalleLiquidacion (liquidacion_id, concepto_id, monto)
SELECT l.liquidacion_id, cp.concepto_id, d.monto
FROM dbo.Liquidacion l
CROSS JOIN (VALUES
    (N'GRATIF_LEGAL', 86900),
    (N'COLACION', 45000),
    (N'MOVILIZACION', 30000),
    (N'DESC_AFP', 99500),
    (N'DESC_SALUD', 60830),
    (N'HORAS_EXTRA', 57933)
) AS d(codigo, monto)
JOIN dbo.ConceptoPago cp ON cp.codigo = d.codigo
WHERE l.empleado_id = N'EMP015' AND l.periodo = '2026-07';
GO
INSERT INTO dbo.DetalleLiquidacion (liquidacion_id, concepto_id, monto)
SELECT l.liquidacion_id, cp.concepto_id, d.monto
FROM dbo.Liquidacion l
CROSS JOIN (VALUES
    (N'GRATIF_LEGAL', 153500),
    (N'COLACION', 45000),
    (N'MOVILIZACION', 30000),
    (N'DESC_AFP', 175758),
    (N'DESC_SALUD', 107450),
    (N'HORAS_EXTRA', 76750)
) AS d(codigo, monto)
JOIN dbo.ConceptoPago cp ON cp.codigo = d.codigo
WHERE l.empleado_id = N'EMP016' AND l.periodo = '2026-07';
GO
INSERT INTO dbo.DetalleLiquidacion (liquidacion_id, concepto_id, monto)
SELECT l.liquidacion_id, cp.concepto_id, d.monto
FROM dbo.Liquidacion l
CROSS JOIN (VALUES
    (N'GRATIF_LEGAL', 140700),
    (N'COLACION', 45000),
    (N'MOVILIZACION', 30000),
    (N'DESC_AFP', 161102),
    (N'DESC_SALUD', 98490)
) AS d(codigo, monto)
JOIN dbo.ConceptoPago cp ON cp.codigo = d.codigo
WHERE l.empleado_id = N'EMP017' AND l.periodo = '2026-07';
GO
INSERT INTO dbo.DetalleLiquidacion (liquidacion_id, concepto_id, monto)
SELECT l.liquidacion_id, cp.concepto_id, d.monto
FROM dbo.Liquidacion l
CROSS JOIN (VALUES
    (N'GRATIF_LEGAL', 164500),
    (N'COLACION', 45000),
    (N'MOVILIZACION', 30000),
    (N'DESC_AFP', 188352),
    (N'DESC_SALUD', 115150)
) AS d(codigo, monto)
JOIN dbo.ConceptoPago cp ON cp.codigo = d.codigo
WHERE l.empleado_id = N'EMP019' AND l.periodo = '2026-07';
GO
INSERT INTO dbo.DetalleLiquidacion (liquidacion_id, concepto_id, monto)
SELECT l.liquidacion_id, cp.concepto_id, d.monto
FROM dbo.Liquidacion l
CROSS JOIN (VALUES
    (N'GRATIF_LEGAL', 214700),
    (N'COLACION', 45000),
    (N'MOVILIZACION', 30000),
    (N'DESC_AFP', 245832),
    (N'DESC_SALUD', 150290),
    (N'HORAS_EXTRA', 143133)
) AS d(codigo, monto)
JOIN dbo.ConceptoPago cp ON cp.codigo = d.codigo
WHERE l.empleado_id = N'EMP020' AND l.periodo = '2026-07';
GO
INSERT INTO dbo.DetalleLiquidacion (liquidacion_id, concepto_id, monto)
SELECT l.liquidacion_id, cp.concepto_id, d.monto
FROM dbo.Liquidacion l
CROSS JOIN (VALUES
    (N'GRATIF_LEGAL', 101300),
    (N'COLACION', 45000),
    (N'MOVILIZACION', 30000),
    (N'DESC_AFP', 115988),
    (N'DESC_SALUD', 70910),
    (N'HORAS_EXTRA', 16883)
) AS d(codigo, monto)
JOIN dbo.ConceptoPago cp ON cp.codigo = d.codigo
WHERE l.empleado_id = N'EMP021' AND l.periodo = '2026-07';
GO
