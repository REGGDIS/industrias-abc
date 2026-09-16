-- ============================================================
-- INDUSTRIAS ABC
-- Sistema Operacional de Recursos Humanos
-- Motor: PostgreSQL 16
-- Archivo: schema.sql
-- ============================================================

-- ============================================================
-- 1. TABLA: centros_costo
-- ============================================================

CREATE TABLE centros_costo (
    centro_costo_id INTEGER GENERATED ALWAYS AS IDENTITY,
    codigo_centro_costo VARCHAR(10) NOT NULL,
    nombre_centro_costo VARCHAR(100) NOT NULL,

    CONSTRAINT pk_centros_costo
        PRIMARY KEY (centro_costo_id),

    CONSTRAINT uq_centros_costo_codigo
        UNIQUE (codigo_centro_costo)
);


-- ============================================================
-- 2. TABLA: areas
-- ============================================================

CREATE TABLE areas (
    area_id INTEGER GENERATED ALWAYS AS IDENTITY,
    codigo_area VARCHAR(10) NOT NULL,
    nombre_area VARCHAR(100) NOT NULL,
    gerencia VARCHAR(100),
    centro_costo_id INTEGER NOT NULL,

    CONSTRAINT pk_areas
        PRIMARY KEY (area_id),

    CONSTRAINT uq_areas_codigo
        UNIQUE (codigo_area),

    CONSTRAINT uq_areas_centro_costo
        UNIQUE (centro_costo_id),

    CONSTRAINT fk_areas_centro_costo
        FOREIGN KEY (centro_costo_id)
        REFERENCES centros_costo (centro_costo_id)
        ON UPDATE RESTRICT
        ON DELETE RESTRICT
);


-- ============================================================
-- 3. TABLA: cargos
-- ============================================================

CREATE TABLE cargos (
    cargo_id INTEGER GENERATED ALWAYS AS IDENTITY,
    codigo_cargo VARCHAR(10) NOT NULL,
    nombre_cargo VARCHAR(100) NOT NULL,
    nivel VARCHAR(50),
    sueldo_base_referencial NUMERIC(12,2) NOT NULL,

    CONSTRAINT pk_cargos
        PRIMARY KEY (cargo_id),

    CONSTRAINT uq_cargos_codigo
        UNIQUE (codigo_cargo),

    CONSTRAINT ck_cargos_sueldo_base
        CHECK (sueldo_base_referencial >= 0)
);


-- ============================================================
-- 4. TABLA: empleados
-- ============================================================

CREATE TABLE empleados (
    empleado_id INTEGER GENERATED ALWAYS AS IDENTITY,
    rut VARCHAR(10) NOT NULL,
    nombres VARCHAR(100) NOT NULL,
    apellido_paterno VARCHAR(60) NOT NULL,
    apellido_materno VARCHAR(60),
    fecha_nacimiento DATE NOT NULL,
    sexo VARCHAR(20),
    nacionalidad VARCHAR(50),
    fecha_ingreso DATE NOT NULL,
    fecha_salida DATE,
    area_id INTEGER NOT NULL,
    cargo_id INTEGER NOT NULL,
    estado VARCHAR(20) NOT NULL,

    CONSTRAINT pk_empleados
        PRIMARY KEY (empleado_id),

    CONSTRAINT uq_empleados_rut
        UNIQUE (rut),

    CONSTRAINT ck_empleados_rut_formato
        CHECK (rut ~ '^[0-9]{7,8}-[0-9Kk]$'),

    CONSTRAINT ck_empleados_fechas
        CHECK (
            fecha_salida IS NULL
            OR fecha_salida >= fecha_ingreso
        ),

    CONSTRAINT ck_empleados_estado
        CHECK (estado IN ('ACTIVO', 'INACTIVO')),

    CONSTRAINT fk_empleados_area
        FOREIGN KEY (area_id)
        REFERENCES areas (area_id)
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,

    CONSTRAINT fk_empleados_cargo
        FOREIGN KEY (cargo_id)
        REFERENCES cargos (cargo_id)
        ON UPDATE RESTRICT
        ON DELETE RESTRICT
);


-- ============================================================
-- 5. ÍNDICES
-- ============================================================

CREATE INDEX idx_empleados_area
    ON empleados (area_id);

CREATE INDEX idx_empleados_cargo
    ON empleados (cargo_id);

CREATE INDEX idx_empleados_estado
    ON empleados (estado);

CREATE INDEX idx_empleados_fecha_ingreso
    ON empleados (fecha_ingreso);