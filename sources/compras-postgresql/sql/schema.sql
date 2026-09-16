-- =====================================================================
--  schema.sql  -  Sistema Operacional de COMPRAS Y ABASTECIMIENTO
--  Proyecto: Business Intelligence - Industrias ABC  (Equipo BInnova)
--  Motor: PostgreSQL        Dominio: Compras        Rama: feature/compras
--  Coherente con el Modelo Logico / ERD v0.1 (3NF, RESTRICT, sin CASCADE)
--
--  Convenciones (criterio del equipo):
--    PK: INTEGER GENERATED ALWAYS AS IDENTITY
--    Nombres de constraints: pk_/fk_/uq_/ck_  e indices idx_
--    FK solo internas al dominio Compras (sin FK fisicas a otras bases)
--    Reglas multi-fila (recepcion acumulada, fechas entre tablas) via TRIGGER
--
--  Dominios de estado de ordenes_compra y recepciones CONFIRMADOS por el
--  equipo (revision de Roberto, 28-08-2026).
-- =====================================================================

-- Recrear desde cero (orden hijo -> padre; sin CASCADE)
DROP TABLE IF EXISTS detalle_recepcion;
DROP TABLE IF EXISTS recepciones;
DROP TABLE IF EXISTS detalle_orden_compra;
DROP TABLE IF EXISTS ordenes_compra;
DROP TABLE IF EXISTS insumos;
DROP TABLE IF EXISTS categorias_insumo;
DROP TABLE IF EXISTS proveedores;
DROP TABLE IF EXISTS compradores;
DROP TABLE IF EXISTS centros_costo;
DROP TABLE IF EXISTS areas;

-- ---------------------------------------------------------------------
-- 1) areas  (unidad organizacional de referencia; poblada desde el Universo)
-- ---------------------------------------------------------------------
CREATE TABLE areas (
    area_id     INTEGER      GENERATED ALWAYS AS IDENTITY,
    codigo_area VARCHAR(10)  NOT NULL,
    nombre_area VARCHAR(80)  NOT NULL,
    CONSTRAINT pk_areas        PRIMARY KEY (area_id),
    CONSTRAINT uq_areas_codigo UNIQUE (codigo_area)
);

-- ---------------------------------------------------------------------
-- 2) centros_costo  (centro de costo al que se imputan las ordenes)
--    Relacion Area-Centro 1:1 -> area_id UNIQUE
-- ---------------------------------------------------------------------
CREATE TABLE centros_costo (
    centro_costo_id INTEGER     GENERATED ALWAYS AS IDENTITY,
    codigo_centro   VARCHAR(10) NOT NULL,
    nombre_centro   VARCHAR(80) NOT NULL,
    area_id         INTEGER     NOT NULL,
    estado          VARCHAR(15) NOT NULL DEFAULT 'ACTIVO',
    CONSTRAINT pk_centros_costo        PRIMARY KEY (centro_costo_id),
    CONSTRAINT uq_centros_costo_codigo UNIQUE (codigo_centro),
    CONSTRAINT uq_centros_costo_area   UNIQUE (area_id),
    CONSTRAINT fk_centros_costo_area   FOREIGN KEY (area_id)
        REFERENCES areas (area_id) ON DELETE RESTRICT,
    CONSTRAINT ck_centros_costo_estado CHECK (estado IN ('ACTIVO','INACTIVO'))
);

-- ---------------------------------------------------------------------
-- 3) compradores  (comprador interno que emite la OC; homologable con RRHH)
-- ---------------------------------------------------------------------
CREATE TABLE compradores (
    comprador_id     INTEGER      GENERATED ALWAYS AS IDENTITY,
    codigo_comprador VARCHAR(15)  NOT NULL,
    nombre_comprador VARCHAR(120) NOT NULL,
    area_id          INTEGER,
    estado           VARCHAR(15)  NOT NULL DEFAULT 'ACTIVO',
    CONSTRAINT pk_compradores        PRIMARY KEY (comprador_id),
    CONSTRAINT uq_compradores_codigo UNIQUE (codigo_comprador),
    CONSTRAINT fk_compradores_area   FOREIGN KEY (area_id)
        REFERENCES areas (area_id) ON DELETE RESTRICT,
    CONSTRAINT ck_compradores_estado CHECK (estado IN ('ACTIVO','INACTIVO'))
);

-- ---------------------------------------------------------------------
-- 4) proveedores  (abastecedor externo de insumos)
-- ---------------------------------------------------------------------
CREATE TABLE proveedores (
    proveedor_id    INTEGER      GENERATED ALWAYS AS IDENTITY,
    rut_proveedor   VARCHAR(12)  NOT NULL,
    razon_social    VARCHAR(120) NOT NULL,
    nombre_fantasia VARCHAR(120),
    categoria       VARCHAR(60),
    region          VARCHAR(60),
    comuna          VARCHAR(60),
    estado          VARCHAR(15)  NOT NULL DEFAULT 'ACTIVO',
    CONSTRAINT pk_proveedores        PRIMARY KEY (proveedor_id),
    CONSTRAINT uq_proveedores_rut    UNIQUE (rut_proveedor),
    CONSTRAINT ck_proveedores_estado CHECK (estado IN ('ACTIVO','INACTIVO'))
);

-- ---------------------------------------------------------------------
-- 5) categorias_insumo  (normaliza la categoria del insumo)
-- ---------------------------------------------------------------------
CREATE TABLE categorias_insumo (
    categoria_id     INTEGER     GENERATED ALWAYS AS IDENTITY,
    codigo_categoria VARCHAR(15) NOT NULL,
    nombre_categoria VARCHAR(80) NOT NULL,
    CONSTRAINT pk_categorias_insumo        PRIMARY KEY (categoria_id),
    CONSTRAINT uq_categorias_insumo_codigo UNIQUE (codigo_categoria)
);

-- ---------------------------------------------------------------------
-- 6) insumos  (material/articulo que la empresa adquiere)
-- ---------------------------------------------------------------------
CREATE TABLE insumos (
    insumo_id     INTEGER       GENERATED ALWAYS AS IDENTITY,
    codigo_insumo VARCHAR(20)   NOT NULL,
    nombre_insumo VARCHAR(120)  NOT NULL,
    categoria_id  INTEGER       NOT NULL,
    unidad_medida VARCHAR(15)   NOT NULL,
    stock_minimo  NUMERIC(12,2) NOT NULL DEFAULT 0,
    estado        VARCHAR(15)   NOT NULL DEFAULT 'ACTIVO',
    CONSTRAINT pk_insumos           PRIMARY KEY (insumo_id),
    CONSTRAINT uq_insumos_codigo    UNIQUE (codigo_insumo),
    CONSTRAINT fk_insumos_categoria FOREIGN KEY (categoria_id)
        REFERENCES categorias_insumo (categoria_id) ON DELETE RESTRICT,
    CONSTRAINT ck_insumos_stock     CHECK (stock_minimo >= 0),
    CONSTRAINT ck_insumos_estado    CHECK (estado IN ('ACTIVO','INACTIVO'))
);

-- ---------------------------------------------------------------------
-- 7) ordenes_compra  (cabecera de la compra a un proveedor)
-- ---------------------------------------------------------------------
CREATE TABLE ordenes_compra (
    oc_id           INTEGER       GENERATED ALWAYS AS IDENTITY,
    numero_oc       VARCHAR(20)   NOT NULL,
    proveedor_id    INTEGER       NOT NULL,
    fecha_emision   DATE          NOT NULL,
    fecha_requerida DATE,
    centro_costo_id INTEGER       NOT NULL,
    comprador_id    INTEGER       NOT NULL,
    estado          VARCHAR(20)   NOT NULL DEFAULT 'EMITIDA',
    moneda          CHAR(3)       NOT NULL DEFAULT 'CLP',
    subtotal        NUMERIC(14,2) NOT NULL DEFAULT 0,
    impuesto        NUMERIC(14,2) NOT NULL DEFAULT 0,
    total           NUMERIC(14,2) NOT NULL DEFAULT 0,
    CONSTRAINT pk_ordenes_compra          PRIMARY KEY (oc_id),
    CONSTRAINT uq_ordenes_compra_numero   UNIQUE (numero_oc),
    CONSTRAINT fk_ordenes_compra_proveedor FOREIGN KEY (proveedor_id)
        REFERENCES proveedores (proveedor_id) ON DELETE RESTRICT,
    CONSTRAINT fk_ordenes_compra_centro    FOREIGN KEY (centro_costo_id)
        REFERENCES centros_costo (centro_costo_id) ON DELETE RESTRICT,
    CONSTRAINT fk_ordenes_compra_comprador FOREIGN KEY (comprador_id)
        REFERENCES compradores (comprador_id) ON DELETE RESTRICT,
    CONSTRAINT ck_ordenes_compra_fecha  CHECK (fecha_requerida IS NULL
                                               OR fecha_requerida >= fecha_emision),
    CONSTRAINT ck_ordenes_compra_moneda CHECK (moneda IN ('CLP','USD','EUR')),
    CONSTRAINT ck_ordenes_compra_montos CHECK (subtotal >= 0 AND impuesto >= 0 AND total >= 0),
    -- dominio de estado confirmado por el equipo:
    CONSTRAINT ck_ordenes_compra_estado CHECK
        (estado IN ('EMITIDA','PARCIAL','RECIBIDA','CERRADA','ANULADA'))
);

-- ---------------------------------------------------------------------
-- 8) detalle_orden_compra  (linea de la OC por insumo)
--    Restriccion compuesta: un insumo una sola vez por orden
-- ---------------------------------------------------------------------
CREATE TABLE detalle_orden_compra (
    detalle_id      INTEGER       GENERATED ALWAYS AS IDENTITY,
    oc_id           INTEGER       NOT NULL,
    insumo_id       INTEGER       NOT NULL,
    cantidad        NUMERIC(12,2) NOT NULL,
    precio_unitario NUMERIC(14,2) NOT NULL,
    descuento       NUMERIC(14,2) NOT NULL DEFAULT 0,
    subtotal        NUMERIC(14,2) NOT NULL DEFAULT 0,  -- derivado; lo calcula el trigger
    CONSTRAINT pk_detalle_orden_compra   PRIMARY KEY (detalle_id),
    CONSTRAINT fk_detalle_oc_orden       FOREIGN KEY (oc_id)
        REFERENCES ordenes_compra (oc_id) ON DELETE RESTRICT,
    CONSTRAINT fk_detalle_oc_insumo      FOREIGN KEY (insumo_id)
        REFERENCES insumos (insumo_id) ON DELETE RESTRICT,
    CONSTRAINT uq_detalle_oc_insumo      UNIQUE (oc_id, insumo_id),
    CONSTRAINT ck_detalle_oc_cantidad    CHECK (cantidad > 0),
    CONSTRAINT ck_detalle_oc_precio      CHECK (precio_unitario >= 0),
    CONSTRAINT ck_detalle_oc_descuento   CHECK (descuento >= 0),
    CONSTRAINT ck_detalle_oc_subtotal    CHECK (subtotal >= 0)
);

-- ---------------------------------------------------------------------
-- 9) recepciones  (evento de recepcion asociado a una orden)
-- ---------------------------------------------------------------------
CREATE TABLE recepciones (
    recepcion_id    INTEGER     GENERATED ALWAYS AS IDENTITY,
    oc_id           INTEGER     NOT NULL,
    fecha_recepcion DATE        NOT NULL,
    estado          VARCHAR(20) NOT NULL DEFAULT 'REGISTRADA',
    CONSTRAINT pk_recepciones      PRIMARY KEY (recepcion_id),
    CONSTRAINT fk_recepciones_orden FOREIGN KEY (oc_id)
        REFERENCES ordenes_compra (oc_id) ON DELETE RESTRICT,
    -- dominio de estado confirmado por el equipo:
    CONSTRAINT ck_recepciones_estado CHECK
        (estado IN ('REGISTRADA','CONFORME','CON_DIFERENCIAS','ANULADA'))
);

-- ---------------------------------------------------------------------
-- 10) detalle_recepcion  (recibido/rechazado por cada linea/insumo)
--     Restriccion compuesta: una linea una sola vez por recepcion
-- ---------------------------------------------------------------------
CREATE TABLE detalle_recepcion (
    detalle_recepcion_id INTEGER       GENERATED ALWAYS AS IDENTITY,
    recepcion_id         INTEGER       NOT NULL,
    detalle_id           INTEGER       NOT NULL,
    cantidad_recibida    NUMERIC(12,2) NOT NULL DEFAULT 0,
    cantidad_rechazada   NUMERIC(12,2) NOT NULL DEFAULT 0,
    estado               VARCHAR(20),
    CONSTRAINT pk_detalle_recepcion     PRIMARY KEY (detalle_recepcion_id),
    CONSTRAINT fk_detrec_recepcion      FOREIGN KEY (recepcion_id)
        REFERENCES recepciones (recepcion_id) ON DELETE RESTRICT,
    CONSTRAINT fk_detrec_detalle        FOREIGN KEY (detalle_id)
        REFERENCES detalle_orden_compra (detalle_id) ON DELETE RESTRICT,
    CONSTRAINT uq_detrec_recepcion_detalle UNIQUE (recepcion_id, detalle_id),
    CONSTRAINT ck_detrec_recibida       CHECK (cantidad_recibida >= 0),
    CONSTRAINT ck_detrec_rechazada      CHECK (cantidad_rechazada >= 0),
    CONSTRAINT ck_detrec_estado         CHECK (estado IS NULL
                                               OR estado IN ('OK','PARCIAL','RECHAZADO'))
);

-- =====================================================================
--  INDICES (para los analisis del Trabajo v2: compras por proveedor,
--  insumo, centro/area, periodo; cumplimiento y diferencias de recepcion)
--  No se duplican los ya cubiertos por PK/UNIQUE.
-- =====================================================================
CREATE INDEX idx_oc_proveedor     ON ordenes_compra (proveedor_id);
CREATE INDEX idx_oc_centro        ON ordenes_compra (centro_costo_id);
CREATE INDEX idx_oc_comprador     ON ordenes_compra (comprador_id);
CREATE INDEX idx_oc_fecha         ON ordenes_compra (fecha_emision);
CREATE INDEX idx_det_insumo       ON detalle_orden_compra (insumo_id);
CREATE INDEX idx_rec_oc           ON recepciones (oc_id);
CREATE INDEX idx_detrec_detalle   ON detalle_recepcion (detalle_id);
CREATE INDEX idx_insumo_categoria ON insumos (categoria_id);

-- =====================================================================
--  TRIGGERS  (reglas de negocio que dependen de varias filas/tablas)
-- =====================================================================

-- (a) Subtotal de linea derivado: subtotal = cantidad * precio_unitario - descuento
CREATE OR REPLACE FUNCTION fn_detalle_oc_subtotal()
RETURNS TRIGGER AS $$
BEGIN
    NEW.subtotal := ROUND(NEW.cantidad * NEW.precio_unitario - NEW.descuento, 2);
    IF NEW.subtotal < 0 THEN
        RAISE EXCEPTION 'Subtotal negativo en detalle (cantidad*precio - descuento < 0)';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_detalle_oc_subtotal
    BEFORE INSERT OR UPDATE ON detalle_orden_compra
    FOR EACH ROW EXECUTE FUNCTION fn_detalle_oc_subtotal();

-- (b) La fecha de recepcion no puede ser anterior a la emision de la OC
CREATE OR REPLACE FUNCTION fn_recepcion_fecha()
RETURNS TRIGGER AS $$
DECLARE
    v_fecha_emision DATE;
BEGIN
    SELECT fecha_emision INTO v_fecha_emision
    FROM ordenes_compra WHERE oc_id = NEW.oc_id;
    IF NEW.fecha_recepcion < v_fecha_emision THEN
        RAISE EXCEPTION 'La fecha de recepcion (%) es anterior a la emision de la OC (%)',
            NEW.fecha_recepcion, v_fecha_emision;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_recepcion_fecha
    BEFORE INSERT OR UPDATE ON recepciones
    FOR EACH ROW EXECUTE FUNCTION fn_recepcion_fecha();

-- (c) detalle_recepcion: (i) la linea debe pertenecer a la misma OC de la
--     recepcion; (ii) la suma acumulada recibida+rechazada de la linea no
--     puede superar la cantidad solicitada en el detalle de la orden.
CREATE OR REPLACE FUNCTION fn_detrec_valida()
RETURNS TRIGGER AS $$
DECLARE
    v_oc_recepcion  INTEGER;
    v_oc_detalle    INTEGER;
    v_cant_pedida   NUMERIC(12,2);
    v_acumulado     NUMERIC(12,2);
BEGIN
    -- (i) coherencia de orden entre la recepcion y la linea
    SELECT oc_id INTO v_oc_recepcion FROM recepciones          WHERE recepcion_id = NEW.recepcion_id;
    SELECT oc_id, cantidad INTO v_oc_detalle, v_cant_pedida
        FROM detalle_orden_compra WHERE detalle_id = NEW.detalle_id;

    IF v_oc_recepcion IS DISTINCT FROM v_oc_detalle THEN
        RAISE EXCEPTION 'La linea % pertenece a otra orden de compra que la recepcion %',
            NEW.detalle_id, NEW.recepcion_id;
    END IF;

    -- (ii) suma acumulada (excluyendo la propia fila en UPDATE) + la nueva
    SELECT COALESCE(SUM(cantidad_recibida + cantidad_rechazada), 0) INTO v_acumulado
    FROM detalle_recepcion
    WHERE detalle_id = NEW.detalle_id
      AND detalle_recepcion_id IS DISTINCT FROM NEW.detalle_recepcion_id;

    IF v_acumulado + NEW.cantidad_recibida + NEW.cantidad_rechazada > v_cant_pedida THEN
        RAISE EXCEPTION 'Recepcion acumulada (%) supera lo solicitado (%) para la linea %',
            v_acumulado + NEW.cantidad_recibida + NEW.cantidad_rechazada,
            v_cant_pedida, NEW.detalle_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_detrec_valida
    BEFORE INSERT OR UPDATE ON detalle_recepcion
    FOR EACH ROW EXECUTE FUNCTION fn_detrec_valida();

-- Fin de schema.sql
