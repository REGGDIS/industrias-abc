-- ============================================================
-- Industrias ABC - Data Warehouse
-- Script: 020_crear_dim_fecha.sql
-- Objetivo:
--   Crear la dimensión calendario del Data Warehouse.
-- Motor:
--   PostgreSQL
-- Esquema:
--   dw
-- ============================================================

CREATE TABLE IF NOT EXISTS dw.dim_fecha (
    fecha_key INTEGER NOT NULL,
    fecha DATE,
    anio SMALLINT NOT NULL,
    semestre SMALLINT NOT NULL,
    trimestre SMALLINT NOT NULL,
    mes SMALLINT NOT NULL,
    nombre_mes VARCHAR(15) NOT NULL,
    anio_mes CHAR(7) NOT NULL,
    dia_mes SMALLINT NOT NULL,
    dia_anio SMALLINT NOT NULL,
    dia_semana SMALLINT NOT NULL,
    nombre_dia VARCHAR(15) NOT NULL,
    anio_iso SMALLINT NOT NULL,
    semana_iso SMALLINT NOT NULL,
    es_dia_laboral_semana BOOLEAN NOT NULL,

    CONSTRAINT pk_dim_fecha
        PRIMARY KEY (fecha_key),

    CONSTRAINT uq_dim_fecha_fecha
        UNIQUE (fecha),

    CONSTRAINT ck_dim_fecha_desconocido
        CHECK (
            (fecha_key = 0 AND fecha IS NULL)
            OR
            (fecha_key > 0 AND fecha IS NOT NULL)
        ),

    CONSTRAINT ck_dim_fecha_key_consistente
        CHECK (
            fecha_key = 0
            OR fecha_key =
                (
                    EXTRACT(YEAR FROM fecha)::INTEGER * 10000
                    + EXTRACT(MONTH FROM fecha)::INTEGER * 100
                    + EXTRACT(DAY FROM fecha)::INTEGER
                )
        ),

    CONSTRAINT ck_dim_fecha_anio
        CHECK (
            fecha_key = 0
            OR anio BETWEEN 1 AND 9999
        ),

    CONSTRAINT ck_dim_fecha_semestre
        CHECK (
            fecha_key = 0
            OR semestre BETWEEN 1 AND 2
        ),

    CONSTRAINT ck_dim_fecha_trimestre
        CHECK (
            fecha_key = 0
            OR trimestre BETWEEN 1 AND 4
        ),

    CONSTRAINT ck_dim_fecha_mes
        CHECK (
            fecha_key = 0
            OR mes BETWEEN 1 AND 12
        ),

    CONSTRAINT ck_dim_fecha_anio_mes
        CHECK (
            fecha_key = 0
            OR anio_mes ~ '^[0-9]{4}-[0-9]{2}$'
        ),

    CONSTRAINT ck_dim_fecha_dia_mes
        CHECK (
            fecha_key = 0
            OR dia_mes BETWEEN 1 AND 31
        ),

    CONSTRAINT ck_dim_fecha_dia_anio
        CHECK (
            fecha_key = 0
            OR dia_anio BETWEEN 1 AND 366
        ),

    CONSTRAINT ck_dim_fecha_dia_semana
        CHECK (
            fecha_key = 0
            OR dia_semana BETWEEN 1 AND 7
        ),

    CONSTRAINT ck_dim_fecha_anio_iso
        CHECK (
            fecha_key = 0
            OR anio_iso BETWEEN 1 AND 9999
        ),

    CONSTRAINT ck_dim_fecha_semana_iso
        CHECK (
            fecha_key = 0
            OR semana_iso BETWEEN 1 AND 53
        )
);

COMMENT ON TABLE dw.dim_fecha IS
'Dimensión calendario del Data Warehouse de Industrias ABC. Una fila por día.';

COMMENT ON COLUMN dw.dim_fecha.fecha_key IS
'Clave primaria inteligente YYYYMMDD. El valor 0 representa fecha desconocida.';

COMMENT ON COLUMN dw.dim_fecha.fecha IS
'Fecha calendario. NULL únicamente para el miembro desconocido.';

COMMENT ON COLUMN dw.dim_fecha.anio_iso IS
'Año ISO-8601 asociado a semana_iso. Puede diferir del año calendario en límites de año.';

COMMENT ON COLUMN dw.dim_fecha.semana_iso IS
'Número de semana ISO-8601, entre 1 y 53.';

COMMENT ON COLUMN dw.dim_fecha.es_dia_laboral_semana IS
'TRUE para lunes a viernes. No considera feriados oficiales.';

INSERT INTO dw.dim_fecha (
    fecha_key,
    fecha,
    anio,
    semestre,
    trimestre,
    mes,
    nombre_mes,
    anio_mes,
    dia_mes,
    dia_anio,
    dia_semana,
    nombre_dia,
    anio_iso,
    semana_iso,
    es_dia_laboral_semana
)
VALUES (
    0,
    NULL,
    0,
    0,
    0,
    0,
    'Desconocido',
    '0000-00',
    0,
    0,
    0,
    'Desconocido',
    0,
    0,
    FALSE
)
ON CONFLICT (fecha_key) DO NOTHING;
