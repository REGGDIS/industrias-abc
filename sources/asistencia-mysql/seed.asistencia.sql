-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1:3306
-- Tiempo de generación: 28-08-2026 a las 19:24:25
-- Versión del servidor: 9.1.0
-- Versión de PHP: 8.3.14

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `sistemadeasistenciaindustriasabc`
--

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `area`
--

DROP TABLE IF EXISTS `area`;
CREATE TABLE IF NOT EXISTS `area` (
  `IdArea` int NOT NULL AUTO_INCREMENT,
  `NombreArea` varchar(100) NOT NULL,
  `Descripcion` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`IdArea`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Volcado de datos para la tabla `area`
--

INSERT INTO `area` (`IdArea`, `NombreArea`, `Descripcion`) VALUES
(1, 'Administración', NULL),
(2, 'Operaciones', NULL),
(3, 'Mantención', NULL),
(4, 'Logística', NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `asistencia`
--

DROP TABLE IF EXISTS `asistencia`;
CREATE TABLE IF NOT EXISTS `asistencia` (
  `IdAsistencia` int NOT NULL AUTO_INCREMENT,
  `IdTrabajador` int NOT NULL,
  `Fecha` date NOT NULL,
  `HoraEntrada` time DEFAULT NULL,
  `HoraSalida` time DEFAULT NULL,
  `HorasTrabajadas` decimal(5,2) DEFAULT NULL,
  `Atraso` int NOT NULL,
  `Ausentismo` tinyint(1) NOT NULL,
  `HorasExtra` decimal(5,2) NOT NULL,
  PRIMARY KEY (`IdAsistencia`),
  KEY `idx_IdTrabajador` (`IdTrabajador`)
) ENGINE=InnoDB AUTO_INCREMENT=31 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Volcado de datos para la tabla `asistencia`
--

INSERT INTO `asistencia` (`IdAsistencia`, `IdTrabajador`, `Fecha`, `HoraEntrada`, `HoraSalida`, `HorasTrabajadas`, `Atraso`, `Ausentismo`, `HorasExtra`) VALUES
(1, 1, '2026-08-03', '08:00:00', '17:00:00', 9.00, 0, 0, 0.00),
(2, 2, '2026-08-03', '08:05:00', '17:00:00', 8.92, 5, 0, 0.00),
(3, 3, '2026-08-03', '08:00:00', '17:30:00', 9.50, 0, 0, 0.50),
(4, 4, '2026-08-03', '14:00:00', '23:00:00', 9.00, 0, 0, 0.00),
(5, 5, '2026-08-03', '14:10:00', '23:00:00', 8.83, 10, 0, 0.00),
(6, 6, '2026-08-03', '08:00:00', '17:00:00', 9.00, 0, 0, 0.00),
(7, 7, '2026-08-03', NULL, NULL, 0.00, 0, 1, 0.00),
(8, 8, '2026-08-03', '08:00:00', '17:00:00', 9.00, 0, 0, 0.00),
(9, 9, '2026-08-03', '14:00:00', '23:30:00', 9.50, 0, 0, 0.50),
(10, 10, '2026-08-03', '08:15:00', '17:00:00', 8.75, 15, 0, 0.00),
(11, 1, '2026-08-04', '08:00:00', '17:00:00', 9.00, 0, 0, 0.00),
(12, 2, '2026-08-04', '08:00:00', '17:00:00', 9.00, 0, 0, 0.00),
(13, 3, '2026-08-04', '08:05:00', '17:00:00', 8.92, 5, 0, 0.00),
(14, 4, '2026-08-04', '14:00:00', '23:00:00', 9.00, 0, 0, 0.00),
(15, 5, '2026-08-04', '14:00:00', '23:00:00', 9.00, 0, 0, 0.00),
(16, 6, '2026-08-04', '08:00:00', '17:00:00', 9.00, 0, 0, 0.00),
(17, 7, '2026-08-04', '14:05:00', '23:00:00', 8.92, 5, 0, 0.00),
(18, 8, '2026-08-04', '08:00:00', '17:00:00', 9.00, 0, 0, 0.00),
(19, 9, '2026-08-04', '14:00:00', '23:00:00', 9.00, 0, 0, 0.00),
(20, 10, '2026-08-04', '08:00:00', '17:00:00', 9.00, 0, 0, 0.00),
(21, 1, '2026-08-05', '08:00:00', '17:00:00', 9.00, 0, 0, 0.00),
(22, 2, '2026-08-05', '08:10:00', '17:00:00', 8.83, 10, 0, 0.00),
(23, 3, '2026-08-05', '08:00:00', '17:00:00', 9.00, 0, 0, 0.00),
(24, 4, '2026-08-05', NULL, NULL, 0.00, 0, 1, 0.00),
(25, 5, '2026-08-05', '14:00:00', '23:00:00', 9.00, 0, 0, 0.00),
(26, 6, '2026-08-05', '08:00:00', '17:30:00', 9.50, 0, 0, 0.50),
(27, 7, '2026-08-05', '14:00:00', '23:00:00', 9.00, 0, 0, 0.00),
(28, 8, '2026-08-05', '08:00:00', '17:00:00', 9.00, 0, 0, 0.00),
(29, 9, '2026-08-05', '14:15:00', '23:00:00', 8.75, 15, 0, 0.00),
(30, 10, '2026-08-05', '08:00:00', '17:00:00', 9.00, 0, 0, 0.00);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `cargo`
--

DROP TABLE IF EXISTS `cargo`;
CREATE TABLE IF NOT EXISTS `cargo` (
  `IdCargo` int NOT NULL AUTO_INCREMENT,
  `NombreCargo` varchar(100) NOT NULL,
  `Descripcion` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`IdCargo`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Volcado de datos para la tabla `cargo`
--

INSERT INTO `cargo` (`IdCargo`, `NombreCargo`, `Descripcion`) VALUES
(1, 'Gerente', NULL),
(2, 'Supervisor', NULL),
(3, 'Técnico', NULL),
(4, 'Administrativo', NULL),
(5, 'Operario', NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `trabajador`
--

DROP TABLE IF EXISTS `trabajador`;
CREATE TABLE IF NOT EXISTS `trabajador` (
  `IdTrabajador` int NOT NULL AUTO_INCREMENT,
  `Rut` varchar(12) NOT NULL,
  `Nombre` varchar(100) NOT NULL,
  `Apellido` varchar(100) NOT NULL,
  `FechaIngreso` date NOT NULL,
  `IdArea` int NOT NULL,
  `IdCargo` int NOT NULL,
  `IdTurno` int NOT NULL,
  PRIMARY KEY (`IdTrabajador`),
  KEY `idx_IdArea` (`IdArea`),
  KEY `idx_IdCargo` (`IdCargo`),
  KEY `idx_IdTurno` (`IdTurno`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Volcado de datos para la tabla `trabajador`
--

INSERT INTO `trabajador` (`IdTrabajador`, `Rut`, `Nombre`, `Apellido`, `FechaIngreso`, `IdArea`, `IdCargo`, `IdTurno`) VALUES
(1, '18.452.731-6', 'Juan', 'Pérez', '2024-01-15', 1, 1, 1),
(2, '16.783.294-2', 'María', 'González', '2024-02-01', 1, 4, 1),
(3, '21.546.892-7', 'Pedro', 'Soto', '2024-02-15', 2, 2, 1),
(4, '14.928.563-9', 'Ana', 'Muñoz', '2024-03-01', 2, 3, 2),
(5, '19.375.641-3', 'Carlos', 'Rojas', '2024-03-15', 2, 5, 2),
(6, '17.624.859-5', 'Laura', 'Contreras', '2024-04-01', 3, 3, 1),
(7, '22.318.476-1', 'Diego', 'Ramírez', '2024-04-15', 3, 3, 2),
(8, '15.937.284-8', 'Sofía', 'Vargas', '2024-05-01', 4, 2, 1),
(9, '20.761.453-4', 'Felipe', 'Castro', '2024-05-15', 4, 5, 2),
(10, '13.684.925-6', 'Camila', 'Morales', '2024-06-01', 4, 4, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `turno`
--

DROP TABLE IF EXISTS `turno`;
CREATE TABLE IF NOT EXISTS `turno` (
  `IdTurno` int NOT NULL AUTO_INCREMENT,
  `NombreTurno` varchar(100) NOT NULL,
  `HoraEntrada` time(6) NOT NULL,
  `HoraSalida` time(6) NOT NULL,
  PRIMARY KEY (`IdTurno`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Volcado de datos para la tabla `turno`
--

INSERT INTO `turno` (`IdTurno`, `NombreTurno`, `HoraEntrada`, `HoraSalida`) VALUES
(1, 'Mañana', '08:00:00.000000', '17:00:00.000000'),
(2, 'Tarde', '14:00:00.000000', '23:00:00.000000'),
(3, 'Noche', '23:00:00.000000', '08:00:00.000000');

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `asistencia`
--
ALTER TABLE `asistencia`
  ADD CONSTRAINT `asistencia_ibfk_1` FOREIGN KEY (`IdTrabajador`) REFERENCES `trabajador` (`IdTrabajador`) ON DELETE RESTRICT ON UPDATE CASCADE;

--
-- Filtros para la tabla `trabajador`
--
ALTER TABLE `trabajador`
  ADD CONSTRAINT `trabajador_ibfk_1` FOREIGN KEY (`IdArea`) REFERENCES `area` (`IdArea`) ON DELETE RESTRICT ON UPDATE CASCADE,
  ADD CONSTRAINT `trabajador_ibfk_2` FOREIGN KEY (`IdCargo`) REFERENCES `cargo` (`IdCargo`) ON DELETE RESTRICT ON UPDATE CASCADE,
  ADD CONSTRAINT `trabajador_ibfk_3` FOREIGN KEY (`IdTurno`) REFERENCES `turno` (`IdTurno`) ON DELETE RESTRICT ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
