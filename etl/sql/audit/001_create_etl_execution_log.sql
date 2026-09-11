-- ============================================================================
-- Industrias ABC - Business Intelligence
-- ETL Audit transversal v0.1
--
-- Archivo:
--   etl/sql/audit/001_create_etl_execution_log.sql
--
-- Objetivo:
--   Crear o evolucionar de forma idempotente la tabla de auditoría
--   etl_execution_log.
--
-- Compatibilidad:
--   - Compatible con la tabla histórica creada por:
--       etl/sql/staging/rrhh/create_etl_audit.sql
--   - No elimina columnas ni datos existentes.
--   - Agrega las métricas transversales requeridas por el Bloque 6.
-- ============================================================================


-- ---------------------------------------------------------------------------
-- 1. Crear la tabla completa cuando todavía no existe
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS etl_execution_log (
    execution_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    source VARCHAR(50) NOT NULL,
    process VARCHAR(100) NOT NULL,

    started_at TIMESTAMP NOT NULL,
    finished_at TIMESTAMP,

    records_read BIGINT NOT NULL DEFAULT 0,
    records_valid BIGINT NOT NULL DEFAULT 0,
    records_inserted BIGINT NOT NULL DEFAULT 0,
    records_updated BIGINT NOT NULL DEFAULT 0,
    records_unchanged BIGINT NOT NULL DEFAULT 0,
    records_rejected BIGINT NOT NULL DEFAULT 0,
    records_review BIGINT NOT NULL DEFAULT 0,

    status VARCHAR(20) NOT NULL,
    message TEXT
);


-- ---------------------------------------------------------------------------
-- 2. Evolucionar una tabla antigua ya existente
-- ---------------------------------------------------------------------------

ALTER TABLE etl_execution_log
    ADD COLUMN IF NOT EXISTS records_inserted BIGINT NOT NULL DEFAULT 0;

ALTER TABLE etl_execution_log
    ADD COLUMN IF NOT EXISTS records_updated BIGINT NOT NULL DEFAULT 0;

ALTER TABLE etl_execution_log
    ADD COLUMN IF NOT EXISTS records_unchanged BIGINT NOT NULL DEFAULT 0;

ALTER TABLE etl_execution_log
    ADD COLUMN IF NOT EXISTS records_review BIGINT NOT NULL DEFAULT 0;


-- ---------------------------------------------------------------------------
-- 3. Homogeneizar contadores históricos a BIGINT
--
-- La versión RRHH original utilizaba INTEGER.
-- INTEGER -> BIGINT es una ampliación segura.
-- ---------------------------------------------------------------------------

ALTER TABLE etl_execution_log
    ALTER COLUMN records_read TYPE BIGINT
        USING records_read::BIGINT,
    ALTER COLUMN records_valid TYPE BIGINT
        USING records_valid::BIGINT,
    ALTER COLUMN records_rejected TYPE BIGINT
        USING records_rejected::BIGINT;


-- ---------------------------------------------------------------------------
-- 4. Asegurar defaults y obligatoriedad
-- ---------------------------------------------------------------------------

ALTER TABLE etl_execution_log
    ALTER COLUMN records_read SET DEFAULT 0,
    ALTER COLUMN records_valid SET DEFAULT 0,
    ALTER COLUMN records_inserted SET DEFAULT 0,
    ALTER COLUMN records_updated SET DEFAULT 0,
    ALTER COLUMN records_unchanged SET DEFAULT 0,
    ALTER COLUMN records_rejected SET DEFAULT 0,
    ALTER COLUMN records_review SET DEFAULT 0;

ALTER TABLE etl_execution_log
    ALTER COLUMN records_read SET NOT NULL,
    ALTER COLUMN records_valid SET NOT NULL,
    ALTER COLUMN records_inserted SET NOT NULL,
    ALTER COLUMN records_updated SET NOT NULL,
    ALTER COLUMN records_unchanged SET NOT NULL,
    ALTER COLUMN records_rejected SET NOT NULL,
    ALTER COLUMN records_review SET NOT NULL;


-- ---------------------------------------------------------------------------
-- 5. Validar compatibilidad de datos históricos
--
-- Antes de agregar restricciones se comprueba que los registros existentes
-- sean compatibles con el contrato transversal v0.1.
-- ---------------------------------------------------------------------------

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM etl_execution_log
        WHERE records_read < 0
           OR records_valid < 0
           OR records_rejected < 0
           OR status NOT IN (
               'RUNNING',
               'SUCCESS',
               'ERROR',
               'PARTIAL'
           )
           OR (
               finished_at IS NOT NULL
               AND finished_at < started_at
           )
    ) THEN
        RAISE EXCEPTION
            'etl_execution_log contiene datos históricos incompatibles con el contrato de auditoría v0.1';
    END IF;
END
$$;


-- ---------------------------------------------------------------------------
-- 6. Restricción de conteos no negativos
--
-- PostgreSQL no soporta ADD CONSTRAINT IF NOT EXISTS,
-- por lo que se consulta pg_constraint antes de crearla.
-- ---------------------------------------------------------------------------

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'ck_etl_execution_log_counts'
          AND conrelid = 'etl_execution_log'::regclass
    ) THEN
        ALTER TABLE etl_execution_log
            ADD CONSTRAINT ck_etl_execution_log_counts
            CHECK (
                records_read >= 0
                AND records_valid >= 0
                AND records_inserted >= 0
                AND records_updated >= 0
                AND records_unchanged >= 0
                AND records_rejected >= 0
                AND records_review >= 0
            );
    END IF;
END
$$;


-- ---------------------------------------------------------------------------
-- 7. Estados permitidos
--
-- RUNNING : ejecución iniciada
-- SUCCESS : ejecución terminada correctamente
-- ERROR   : ejecución fallida
-- PARTIAL : ejecución completada con incidencias/revisión pendiente
-- ---------------------------------------------------------------------------

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'ck_etl_execution_log_status'
          AND conrelid = 'etl_execution_log'::regclass
    ) THEN
        ALTER TABLE etl_execution_log
            ADD CONSTRAINT ck_etl_execution_log_status
            CHECK (
                status IN (
                    'RUNNING',
                    'SUCCESS',
                    'ERROR',
                    'PARTIAL'
                )
            );
    END IF;
END
$$;


-- ---------------------------------------------------------------------------
-- 8. Coherencia temporal
-- ---------------------------------------------------------------------------

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'ck_etl_execution_log_dates'
          AND conrelid = 'etl_execution_log'::regclass
    ) THEN
        ALTER TABLE etl_execution_log
            ADD CONSTRAINT ck_etl_execution_log_dates
            CHECK (
                finished_at IS NULL
                OR finished_at >= started_at
            );
    END IF;
END
$$;