-- =========================================================
-- SCHEMA.SQL
-- Sistema Operacional de Control de Asistencia
-- Industrias ABC
-- Motor: MySQL / InnoDB
-- =========================================================

CREATE DATABASE IF NOT EXISTS sistemadeasistenciaindustriasabc
CHARACTER SET utf8mb4
COLLATE utf8mb4_0900_ai_ci;

USE sistemadeasistenciaindustriasabc;


-- =========================================================
-- TABLA: trabajador
-- =========================================================

DROP TABLE IF EXISTS asistencia;
DROP TABLE IF EXISTS trabajador;
DROP TABLE IF EXISTS turnos;


CREATE TABLE trabajador (
    trabajador_id INT NOT NULL AUTO_INCREMENT,
    rut VARCHAR(12) NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    fecha_ingreso DATE NOT NULL,

    CONSTRAINT pk_trabajador
        PRIMARY KEY (trabajador_id),

    CONSTRAINT uq_trabajador_rut
        UNIQUE (rut)

) ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_0900_ai_ci;


-- =========================================================
-- TABLA: turnos
-- =========================================================

CREATE TABLE turnos (
    turno_id INT NOT NULL AUTO_INCREMENT,
    nombre_turno VARCHAR(100) NOT NULL,
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL,
    horas_jornada DECIMAL(5,2) NOT NULL,

    CONSTRAINT pk_turnos
        PRIMARY KEY (turno_id)

) ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_0900_ai_ci;


-- =========================================================
-- TABLA: asistencia
-- =========================================================

CREATE TABLE asistencia (
    asistencia_id INT NOT NULL AUTO_INCREMENT,
    trabajador_id INT NOT NULL,
    turno_id INT NOT NULL,
    fecha DATE NOT NULL,
    hora_entrada TIME NULL,
    hora_salida TIME NULL,
    horas_trabajadas DECIMAL(5,2) NULL,
    horas_normales DECIMAL(5,2) NULL,
    horas_extras DECIMAL(5,2) NULL,
    atraso_minutos INT NULL,
    ausentismo TINYINT(1) NOT NULL DEFAULT 0,
    estado VARCHAR(30) NOT NULL,

    CONSTRAINT pk_asistencia
        PRIMARY KEY (asistencia_id),

    CONSTRAINT fk_asistencia_trabajador
        FOREIGN KEY (trabajador_id)
        REFERENCES trabajador(trabajador_id)
        ON DELETE RESTRICT
        ON UPDATE RESTRICT,

    CONSTRAINT fk_asistencia_turno
        FOREIGN KEY (turno_id)
        REFERENCES turnos(turno_id)
        ON DELETE RESTRICT
        ON UPDATE RESTRICT,

    INDEX idx_asistencia_trabajador (trabajador_id),
    INDEX idx_asistencia_turno (turno_id),
    INDEX idx_asistencia_fecha (fecha)

) ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_0900_ai_ci;