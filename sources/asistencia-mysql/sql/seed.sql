-- =========================================================
-- SEED.SQL
-- Datos ficticios para el Sistema Operacional de Asistencia
-- Industrias ABC
-- Motor: MySQL / InnoDB
--
-- Requiere ejecutar previamente schema.sql.
--
-- Los trabajadores corresponden a personas del Universo
-- Empresarial Master, pero se mantienen como referencias
-- locales propias del sistema de Asistencia.
--
-- La homologación con RRHH se realizará posteriormente
-- mediante ETL, principalmente por RUT normalizado.
-- =========================================================

USE sistemadeasistenciaindustriasabc;

-- =========================================================
-- 1. TRABAJADORES
--
-- Se utiliza formato de RUT con puntos para conservar una
-- diferencia de formato controlada respecto de otras fuentes.
-- Esto permitirá probar posteriormente la homologación ETL.
-- =========================================================

INSERT INTO trabajador
    (
        rut,
        nombre,
        apellido,
        fecha_ingreso
    )
VALUES
    ('15.000.984-7', 'Paula',      'Civil Martínez',              '2019-06-07'),
    ('15.001.968-0', 'Alejandro',  'Valenzuela Sepúlveda',       '2018-09-01'),
    ('15.002.952-K', 'Francisca',  'González González',           '2025-11-11'),
    ('15.003.936-3', 'Luis',       'Contreras Sepúlveda',         '2023-07-26'),
    ('15.004.920-2', 'Patricia',   'Muñoz Civil',                 '2022-06-03'),
    ('15.005.904-6', 'Nicolás',    'Morales San Martín',          '2024-05-25'),
    ('15.006.797-9', 'Sebastián',  'Muñoz Martínez',              '2024-03-26'),
    ('15.007.781-8', 'Juan',       'Carrasco Martínez',           '2023-05-20'),
    ('15.008.765-1', 'Andrea',     'Osses Díaz',                  '2024-07-18'),
    ('15.009.749-5', 'Catalina',   'Carrasco Henríquez',          '2025-01-27');


-- =========================================================
-- 2. TURNOS
--
-- El turno se asigna al registro diario de asistencia.
-- No existe un turno permanente almacenado en trabajador.
-- =========================================================

INSERT INTO turnos
    (
        nombre_turno,
        hora_inicio,
        hora_fin,
        horas_jornada
    )
VALUES
    ('Turno Mañana',         '08:00:00', '17:00:00', 8.00),
    ('Turno Tarde',          '14:00:00', '22:00:00', 8.00),
    ('Turno Administrativo', '09:00:00', '18:00:00', 8.00);


-- =========================================================
-- 3. ASISTENCIA
--
-- Período utilizado: 27 al 29 de julio de 2026.
--
-- Casos incluidos:
-- - asistencia normal;
-- - atrasos;
-- - ausencias;
-- - horas extraordinarias.
--
-- Estados válidos:
-- PRESENTE
-- ATRASO
-- AUSENTE
-- =========================================================

INSERT INTO asistencia
    (
        trabajador_id,
        turno_id,
        fecha,
        hora_entrada,
        hora_salida,
        horas_trabajadas,
        horas_normales,
        horas_extras,
        atraso_minutos,
        ausentismo,
        estado
    )
VALUES

-- ---------------------------------------------------------
-- Trabajador 1 — Paula Civil Martínez
-- ---------------------------------------------------------
(1, 1, '2026-07-27', '08:00:00', '17:00:00',
    8.00, 8.00, 0.00, 0, 0, 'PRESENTE'),

(1, 1, '2026-07-28', '08:10:00', '17:00:00',
    7.83, 7.83, 0.00, 10, 0, 'ATRASO'),

(1, 1, '2026-07-29', '08:00:00', '18:00:00',
    9.00, 8.00, 1.00, 0, 0, 'PRESENTE'),


-- ---------------------------------------------------------
-- Trabajador 2 — Alejandro Valenzuela Sepúlveda
-- ---------------------------------------------------------
(2, 2, '2026-07-27', '14:00:00', '22:00:00',
    8.00, 8.00, 0.00, 0, 0, 'PRESENTE'),

(2, 2, '2026-07-28', '14:05:00', '22:00:00',
    7.92, 7.92, 0.00, 5, 0, 'ATRASO'),

(2, 2, '2026-07-29', NULL, NULL,
    0.00, 0.00, 0.00, 0, 1, 'AUSENTE'),


-- ---------------------------------------------------------
-- Trabajador 3 — Francisca González González
-- ---------------------------------------------------------
(3, 3, '2026-07-27', '09:00:00', '18:00:00',
    8.00, 8.00, 0.00, 0, 0, 'PRESENTE'),

(3, 3, '2026-07-28', '09:15:00', '18:00:00',
    7.75, 7.75, 0.00, 15, 0, 'ATRASO'),

(3, 3, '2026-07-29', '09:00:00', '19:00:00',
    9.00, 8.00, 1.00, 0, 0, 'PRESENTE'),


-- ---------------------------------------------------------
-- Trabajador 4 — Luis Contreras Sepúlveda
-- ---------------------------------------------------------
(4, 1, '2026-07-27', '08:00:00', '17:00:00',
    8.00, 8.00, 0.00, 0, 0, 'PRESENTE'),

(4, 1, '2026-07-28', '08:03:00', '17:00:00',
    7.95, 7.95, 0.00, 3, 0, 'ATRASO'),

(4, 1, '2026-07-29', NULL, NULL,
    0.00, 0.00, 0.00, 0, 1, 'AUSENTE'),


-- ---------------------------------------------------------
-- Trabajador 5 — Patricia Muñoz Civil
-- ---------------------------------------------------------
(5, 2, '2026-07-27', '14:00:00', '22:00:00',
    8.00, 8.00, 0.00, 0, 0, 'PRESENTE'),

(5, 2, '2026-07-28', '14:20:00', '22:00:00',
    7.67, 7.67, 0.00, 20, 0, 'ATRASO'),

(5, 2, '2026-07-29', '14:00:00', '23:00:00',
    9.00, 8.00, 1.00, 0, 0, 'PRESENTE'),


-- ---------------------------------------------------------
-- Trabajador 6 — Nicolás Morales San Martín
-- ---------------------------------------------------------
(6, 3, '2026-07-27', '09:00:00', '18:00:00',
    8.00, 8.00, 0.00, 0, 0, 'PRESENTE'),

(6, 3, '2026-07-28', '09:08:00', '18:00:00',
    7.87, 7.87, 0.00, 8, 0, 'ATRASO'),

(6, 3, '2026-07-29', '09:00:00', '18:30:00',
    8.50, 8.00, 0.50, 0, 0, 'PRESENTE'),


-- ---------------------------------------------------------
-- Trabajador 7 — Sebastián Muñoz Martínez
-- ---------------------------------------------------------
(7, 1, '2026-07-27', '08:00:00', '17:00:00',
    8.00, 8.00, 0.00, 0, 0, 'PRESENTE'),

(7, 1, '2026-07-28', '08:00:00', '17:00:00',
    8.00, 8.00, 0.00, 0, 0, 'PRESENTE'),

(7, 1, '2026-07-29', '08:12:00', '17:00:00',
    7.80, 7.80, 0.00, 12, 0, 'ATRASO'),


-- ---------------------------------------------------------
-- Trabajador 8 — Juan Carrasco Martínez
-- ---------------------------------------------------------
(8, 2, '2026-07-27', '14:00:00', '22:00:00',
    8.00, 8.00, 0.00, 0, 0, 'PRESENTE'),

(8, 2, '2026-07-28', NULL, NULL,
    0.00, 0.00, 0.00, 0, 1, 'AUSENTE'),

(8, 2, '2026-07-29', '14:00:00', '22:00:00',
    8.00, 8.00, 0.00, 0, 0, 'PRESENTE'),


-- ---------------------------------------------------------
-- Trabajador 9 — Andrea Osses Díaz
-- ---------------------------------------------------------
(9, 3, '2026-07-27', '09:00:00', '18:00:00',
    8.00, 8.00, 0.00, 0, 0, 'PRESENTE'),

(9, 3, '2026-07-28', '09:05:00', '18:00:00',
    7.92, 7.92, 0.00, 5, 0, 'ATRASO'),

(9, 3, '2026-07-29', '09:00:00', '18:00:00',
    8.00, 8.00, 0.00, 0, 0, 'PRESENTE'),


-- ---------------------------------------------------------
-- Trabajador 10 — Catalina Carrasco Henríquez
-- ---------------------------------------------------------
(10, 1, '2026-07-27', '08:00:00', '17:00:00',
    8.00, 8.00, 0.00, 0, 0, 'PRESENTE'),

(10, 1, '2026-07-28', '08:25:00', '17:00:00',
    7.58, 7.58, 0.00, 25, 0, 'ATRASO'),

(10, 1, '2026-07-29', '08:00:00', '18:00:00',
    9.00, 8.00, 1.00, 0, 0, 'PRESENTE');