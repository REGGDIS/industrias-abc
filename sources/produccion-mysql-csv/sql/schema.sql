-- INDUSTRIAS ABC | BUSINESS INTELLIGENCE
-- Sistema Operacional de Producción
-- schema.sql | Modelo Lógico v0.1
-- Responsable: Joaquín Medina | 26-08-2026

CREATE DATABASE IF NOT EXISTS industrias_abc_produccion
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_0900_ai_ci;

USE industrias_abc_produccion;

CREATE TABLE IF NOT EXISTS productos (
    producto_id BIGINT NOT NULL AUTO_INCREMENT,
    codigo_producto VARCHAR(50) NOT NULL,
    nombre_producto VARCHAR(150) NOT NULL,
    categoria VARCHAR(100) NOT NULL,
    unidad_medida VARCHAR(30) NOT NULL,
    CONSTRAINT pk_productos PRIMARY KEY (producto_id),
    CONSTRAINT uq_productos_codigo UNIQUE (codigo_producto)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS ordenes_produccion (
    orden_produccion_id BIGINT NOT NULL AUTO_INCREMENT,
    numero_orden VARCHAR(50) NOT NULL,
    producto_id BIGINT NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_termino DATE NULL,
    cantidad_planificada DECIMAL(12,2) NOT NULL,
    cantidad_producida DECIMAL(12,2) NOT NULL,
    cantidad_rechazada DECIMAL(12,2) NOT NULL,
    estado VARCHAR(30) NOT NULL,
    centro_costo_id BIGINT NOT NULL,
    CONSTRAINT pk_ordenes_produccion PRIMARY KEY (orden_produccion_id),
    CONSTRAINT uq_ordenes_produccion_numero UNIQUE (numero_orden),
    CONSTRAINT fk_ordenes_produccion_producto
        FOREIGN KEY (producto_id) REFERENCES productos (producto_id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT chk_ordenes_cantidad_planificada CHECK (cantidad_planificada >= 0),
    CONSTRAINT chk_ordenes_cantidad_producida CHECK (cantidad_producida >= 0),
    CONSTRAINT chk_ordenes_cantidad_rechazada CHECK (cantidad_rechazada >= 0),
    CONSTRAINT chk_ordenes_rechazada_no_supera_producida
        CHECK (cantidad_rechazada <= cantidad_producida),
    CONSTRAINT chk_ordenes_fecha_termino
        CHECK (fecha_termino IS NULL OR fecha_termino >= fecha_inicio),
    INDEX idx_ordenes_producto (producto_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS consumo_insumos (
    consumo_id BIGINT NOT NULL AUTO_INCREMENT,
    orden_produccion_id BIGINT NOT NULL,
    insumo_id BIGINT NOT NULL,
    cantidad_planificada DECIMAL(12,2) NOT NULL,
    cantidad_consumida DECIMAL(12,2) NOT NULL,
    fecha_consumo DATE NOT NULL,
    CONSTRAINT pk_consumo_insumos PRIMARY KEY (consumo_id),
    CONSTRAINT fk_consumo_insumos_orden
        FOREIGN KEY (orden_produccion_id)
        REFERENCES ordenes_produccion (orden_produccion_id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT chk_consumo_cantidad_planificada CHECK (cantidad_planificada >= 0),
    CONSTRAINT chk_consumo_cantidad_consumida CHECK (cantidad_consumida >= 0),
    INDEX idx_consumo_orden (orden_produccion_id),
    INDEX idx_consumo_insumo (insumo_id)
) ENGINE=InnoDB;

-- NOTAS:
-- 1. codigo_producto y numero_orden ya generan índices por UNIQUE;
--    no se duplican con índices adicionales.
-- 2. insumo_id y centro_costo_id son referencias lógicas locales:
--    no poseen FK físicas hacia otros sistemas.
-- 3. El Modelo Lógico no define valores cerrados para estado;
--    por ello se mantiene VARCHAR(30) NOT NULL.
-- 4. La coherencia entre fecha_consumo y el período de la orden
--    requiere validación posterior en validaciones.sql.