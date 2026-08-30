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
-- LIMPIEZA PARA EJECUCIÓN REPRODUCIBLE
-- =========================================================

DROP TABLE IF EXISTS asistencia;
DROP TABLE IF EXISTS turnos;
DROP TABLE IF EXISTS trabajador;

-- =========================================================
-- TABLA: trabajador
-- Referencia local de trabajadores del sistema de Asistencia.
-- La homologación con RRHH se realizará posteriormente vía ETL.
-- =========================================================

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
        PRIMARY KEY (turno_id),

    CONSTRAINT chk_turnos_horas_jornada
        CHECK (horas_jornada > 0)
) ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_0900_ai_ci;

-- =========================================================
-- TABLA: asistencia
-- Grano operacional: un trabajador por fecha.
-- El turno pertenece al registro de asistencia, no al trabajador.
-- =========================================================

CREATE TABLE asistencia (
    asistencia_id INT NOT NULL AUTO_INCREMENT,
    trabajador_id INT NOT NULL,
    turno_id INT NOT NULL,
    fecha DATE NOT NULL,
    hora_entrada TIME NULL,
    hora_salida TIME NULL,

    horas_trabajadas DECIMAL(5,2) NOT NULL DEFAULT 0,
    horas_normales DECIMAL(5,2) NOT NULL DEFAULT 0,
    horas_extras DECIMAL(5,2) NOT NULL DEFAULT 0,
    atraso_minutos INT NOT NULL DEFAULT 0,

    ausentismo TINYINT(1) NOT NULL DEFAULT 0,
    estado VARCHAR(30) NOT NULL,

    CONSTRAINT pk_asistencia
        PRIMARY KEY (asistencia_id),

    CONSTRAINT uq_asistencia_trabajador_fecha
        UNIQUE (trabajador_id, fecha),

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

    CONSTRAINT chk_asistencia_horas_trabajadas
        CHECK (horas_trabajadas >= 0),

    CONSTRAINT chk_asistencia_horas_normales
        CHECK (horas_normales >= 0),

    CONSTRAINT chk_asistencia_horas_extras
        CHECK (horas_extras >= 0),

    CONSTRAINT chk_asistencia_atraso
        CHECK (atraso_minutos >= 0),

    CONSTRAINT chk_asistencia_ausentismo
        CHECK (ausentismo IN (0, 1)),

    CONSTRAINT chk_asistencia_estado
        CHECK (estado IN ('PRESENTE', 'ATRASO', 'AUSENTE')),

    CONSTRAINT chk_asistencia_horas_extra
        CHECK (horas_extras <= horas_trabajadas),

    CONSTRAINT chk_asistencia_ausencia_coherente
        CHECK (
            ausentismo = 0
            OR (
                hora_entrada IS NULL
                AND hora_salida IS NULL
                AND horas_trabajadas = 0
                AND horas_normales = 0
                AND horas_extras = 0
                AND atraso_minutos = 0
                AND estado = 'AUSENTE'
            )
        ),

    INDEX idx_asistencia_trabajador (trabajador_id),
    INDEX idx_asistencia_turno (turno_id),
    INDEX idx_asistencia_fecha (fecha)
) ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_0900_ai_ci;