-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1:3306
-- Tiempo de generación: 27-08-2026 a las 23:10:37
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

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
