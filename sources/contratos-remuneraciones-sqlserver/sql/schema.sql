/* ============================================================================
   schema.sql — Estructura de la Base de Datos Operacional
   Dominio: Contratos y Remuneraciones
   Sistema:        Sistema Operacional de Contratos y Remuneraciones
   Responsable:    Luis Figueroa
   Motor:          SQL Server
   Código:         ISI802_83-0-2026-081-PRE
   Basado en:      Modelo Conceptual v0.1 (aprobado) e IDF v0.2 (aprobado)
   Empresa:        Industrias ABC — Plataforma de Business Intelligence
   ============================================================================
   Este script crea el Modelo Físico v0.1 en SQL Server a partir del Modelo
   Conceptual v0.1: entidades Contrato, Liquidación, ConceptoPago y
   DetalleLiquidación, más una tabla local de referencia Empleado basada en
   datos de referencia del Universo Empresarial. La gestión operacional del
   trabajador corresponde al sistema RRHH y NO se administra aquí.
   ============================================================================ */

-- ----------------------------------------------------------------------------
-- 0. BASE DE DATOS
-- ----------------------------------------------------------------------------
IF DB_ID(N'ContratosRemuneraciones_ABC') IS NULL
BEGIN
    CREATE DATABASE ContratosRemuneraciones_ABC;
END
GO

USE ContratosRemuneraciones_ABC;
GO

-- ----------------------------------------------------------------------------
-- 0.5 DROP DE TABLAS (de hijas a padres) para permitir reejecutar el script
--     de forma reproducible. Si se eliminara primero Empleado, SQL Server
--     rechazaría el DROP mientras Contrato y Liquidacion aún dependan de ella.
-- ----------------------------------------------------------------------------
IF OBJECT_ID(N'dbo.DetalleLiquidacion', N'U') IS NOT NULL
    DROP TABLE dbo.DetalleLiquidacion;

IF OBJECT_ID(N'dbo.Liquidacion', N'U') IS NOT NULL
    DROP TABLE dbo.Liquidacion;

IF OBJECT_ID(N'dbo.Contrato', N'U') IS NOT NULL
    DROP TABLE dbo.Contrato;

IF OBJECT_ID(N'dbo.ConceptoPago', N'U') IS NOT NULL
    DROP TABLE dbo.ConceptoPago;

IF OBJECT_ID(N'dbo.Empleado', N'U') IS NOT NULL
    DROP TABLE dbo.Empleado;
GO

-- ----------------------------------------------------------------------------
-- 1. TABLA DE REFERENCIA: Empleado
--    No es dueña de este dominio. Utiliza datos de referencia del Universo
--    Empresarial, usados solo para poder construir
--    contratos y liquidaciones de prueba con datos coherentes con el resto del
--    equipo. La ficha real del trabajador la administra el sistema de RRHH.
-- ----------------------------------------------------------------------------
CREATE TABLE dbo.Empleado (
    empleado_id         VARCHAR(10)     NOT NULL,
    rut_referencia      VARCHAR(15)     NOT NULL,
    nombre_completo      NVARCHAR(150)   NOT NULL,
    codigo_area_ref     VARCHAR(10)     NULL,
    codigo_cargo_ref    VARCHAR(10)     NULL,
    fecha_ingreso_ref   DATE            NULL,
    CONSTRAINT PK_Empleado PRIMARY KEY (empleado_id)
);
GO

-- ----------------------------------------------------------------------------
-- 2. Contrato
-- ----------------------------------------------------------------------------
CREATE TABLE dbo.Contrato (
    contrato_id         INT             IDENTITY(1,1) NOT NULL,
    empleado_id         VARCHAR(10)     NOT NULL,
    numero_contrato     VARCHAR(20)     NOT NULL,
    tipo_contrato       VARCHAR(20)     NOT NULL,
    fecha_inicio        DATE            NOT NULL,
    fecha_termino       DATE            NULL,
    jornada             VARCHAR(30)     NOT NULL,
    sueldo_base         DECIMAL(12,2)   NOT NULL,
    cargo_contrato      VARCHAR(60)     NOT NULL,
    estado              VARCHAR(15)     NOT NULL CONSTRAINT DF_Contrato_estado DEFAULT ('VIGENTE'),

    CONSTRAINT PK_Contrato PRIMARY KEY (contrato_id),
    CONSTRAINT UQ_Contrato_numero UNIQUE (numero_contrato),
    CONSTRAINT FK_Contrato_Empleado FOREIGN KEY (empleado_id)
        REFERENCES dbo.Empleado (empleado_id),
    CONSTRAINT CK_Contrato_tipo CHECK (tipo_contrato IN ('INDEFINIDO','PLAZO_FIJO','TEMPORAL')),
    CONSTRAINT CK_Contrato_estado CHECK (estado IN ('VIGENTE','TERMINADO')),
    CONSTRAINT CK_Contrato_sueldo_base CHECK (sueldo_base > 0),
    -- Regla de negocio del IDF: plazo fijo / temporal deben registrar fecha_termino
    CONSTRAINT CK_Contrato_fecha_termino CHECK (
        (tipo_contrato = 'INDEFINIDO') OR (fecha_termino IS NOT NULL)
    ),
    CONSTRAINT CK_Contrato_fechas CHECK (
        fecha_termino IS NULL OR fecha_termino >= fecha_inicio
    )
);
GO
CREATE INDEX IX_Contrato_Empleado ON dbo.Contrato (empleado_id);
GO

-- ----------------------------------------------------------------------------
-- 3. ConceptoPago (catálogo)
-- ----------------------------------------------------------------------------
CREATE TABLE dbo.ConceptoPago (
    concepto_id         INT             IDENTITY(1,1) NOT NULL,
    codigo              VARCHAR(15)     NOT NULL,
    descripcion         NVARCHAR(100)   NOT NULL,
    tipo                VARCHAR(10)     NOT NULL,
    afecta_imponible    BIT             NOT NULL,

    CONSTRAINT PK_ConceptoPago PRIMARY KEY (concepto_id),
    CONSTRAINT UQ_ConceptoPago_codigo UNIQUE (codigo),
    CONSTRAINT CK_ConceptoPago_tipo CHECK (tipo IN ('HABER','DESCUENTO','APORTE'))
);
GO

-- ----------------------------------------------------------------------------
-- 4. Liquidacion
-- ----------------------------------------------------------------------------
CREATE TABLE dbo.Liquidacion (
    liquidacion_id      INT             IDENTITY(1,1) NOT NULL,
    empleado_id         VARCHAR(10)     NOT NULL,
    contrato_id         INT             NOT NULL,
    periodo             CHAR(7)         NOT NULL,  -- formato 'YYYY-MM'
    sueldo_base         DECIMAL(12,2)   NOT NULL,
    horas_extras        DECIMAL(6,2)    NOT NULL CONSTRAINT DF_Liquidacion_horas_extras DEFAULT (0),
    sueldo_imponible    DECIMAL(12,2)   NOT NULL,
    sueldo_liquido      DECIMAL(12,2)   NOT NULL,
    costo_empresa       DECIMAL(12,2)   NOT NULL,

    CONSTRAINT PK_Liquidacion PRIMARY KEY (liquidacion_id),
    CONSTRAINT UQ_Liquidacion_empleado_periodo UNIQUE (empleado_id, periodo),
    CONSTRAINT FK_Liquidacion_Empleado FOREIGN KEY (empleado_id)
        REFERENCES dbo.Empleado (empleado_id),
    CONSTRAINT FK_Liquidacion_Contrato FOREIGN KEY (contrato_id)
        REFERENCES dbo.Contrato (contrato_id),
    -- Formato 'YYYY-MM'; se restringe además el mes al rango 01-12
    CONSTRAINT CK_Liquidacion_periodo CHECK (
        periodo LIKE '[0-9][0-9][0-9][0-9]-[0-9][0-9]'
        AND SUBSTRING(periodo, 6, 2) BETWEEN '01' AND '12'
    ),
    CONSTRAINT CK_Liquidacion_horas_extras CHECK (horas_extras >= 0),
    CONSTRAINT CK_Liquidacion_montos CHECK (
        sueldo_base >= 0 AND sueldo_imponible >= 0 AND sueldo_liquido >= 0 AND costo_empresa >= 0
    )
);
GO
CREATE INDEX IX_Liquidacion_Empleado ON dbo.Liquidacion (empleado_id);
CREATE INDEX IX_Liquidacion_Contrato ON dbo.Liquidacion (contrato_id);
CREATE INDEX IX_Liquidacion_Periodo ON dbo.Liquidacion (periodo);
GO

-- ----------------------------------------------------------------------------
-- 5. DetalleLiquidacion (entidad asociativa N:M entre Liquidacion y ConceptoPago)
-- ----------------------------------------------------------------------------
CREATE TABLE dbo.DetalleLiquidacion (
    detalle_id          INT             IDENTITY(1,1) NOT NULL,
    liquidacion_id      INT             NOT NULL,
    concepto_id         INT             NOT NULL,
    monto               DECIMAL(12,2)   NOT NULL,

    CONSTRAINT PK_DetalleLiquidacion PRIMARY KEY (detalle_id),
    CONSTRAINT UQ_Detalle_liquidacion_concepto UNIQUE (liquidacion_id, concepto_id),
    -- Sin ON DELETE CASCADE: una liquidación y sus conceptos son información
    -- histórica y no deben borrarse automáticamente (comportamiento NO ACTION).
    CONSTRAINT FK_Detalle_Liquidacion FOREIGN KEY (liquidacion_id)
        REFERENCES dbo.Liquidacion (liquidacion_id),
    CONSTRAINT FK_Detalle_Concepto FOREIGN KEY (concepto_id)
        REFERENCES dbo.ConceptoPago (concepto_id),
    CONSTRAINT CK_Detalle_monto CHECK (monto >= 0)
);
GO
CREATE INDEX IX_Detalle_Liquidacion ON dbo.DetalleLiquidacion (liquidacion_id);
CREATE INDEX IX_Detalle_Concepto ON dbo.DetalleLiquidacion (concepto_id);
GO
