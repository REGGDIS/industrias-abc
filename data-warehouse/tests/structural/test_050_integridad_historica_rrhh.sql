-- ============================================================
-- Industrias ABC - Data Warehouse
-- Test: test_050_integridad_historica_rrhh.sql
-- Objetivo:
--   Validar integridad histórica SCD Tipo 2 de DIM_EMPLEADO
--   y resolución temporal compatible con FACT_ASISTENCIA.
--
-- Motor:
--   PostgreSQL 16
--
-- Estrategia:
--   - Todas las pruebas se ejecutan dentro de una transacción.
--   - Se crean fixtures controlados.
--   - Al finalizar se ejecuta ROLLBACK.
--   - No se dejan datos persistentes.
-- ============================================================

\set ON_ERROR_STOP on

BEGIN;

-- ============================================================
-- 1. VALIDACIÓN DEL ESTADO ACTUAL DE DIM_EMPLEADO
-- ============================================================

DO $$
DECLARE
    v_cantidad INTEGER;
BEGIN
    -- --------------------------------------------------------
    -- 1.1 No debe existir más de una versión actual por RUT.
    -- --------------------------------------------------------
    SELECT COUNT(*)
    INTO v_cantidad
    FROM (
        SELECT rut_normalizado
        FROM dw.dim_empleado
        WHERE es_actual = TRUE
        GROUP BY rut_normalizado
        HAVING COUNT(*) > 1
    ) t;

    IF v_cantidad <> 0 THEN
        RAISE EXCEPTION
            'ERROR: existen RUT con más de una versión actual en DIM_EMPLEADO';
    END IF;

    -- --------------------------------------------------------
    -- 1.2 Toda versión cerrada debe tener vigencia válida.
    -- --------------------------------------------------------
    SELECT COUNT(*)
    INTO v_cantidad
    FROM dw.dim_empleado
    WHERE fecha_hasta IS NOT NULL
      AND fecha_hasta <= fecha_desde;

    IF v_cantidad <> 0 THEN
        RAISE EXCEPTION
            'ERROR: existen vigencias inválidas en DIM_EMPLEADO';
    END IF;

    -- --------------------------------------------------------
    -- 1.3 Coherencia entre es_actual y fecha_hasta.
    -- --------------------------------------------------------
    SELECT COUNT(*)
    INTO v_cantidad
    FROM dw.dim_empleado
    WHERE
        (es_actual = TRUE AND fecha_hasta IS NOT NULL)
        OR
        (es_actual = FALSE AND fecha_hasta IS NULL);

    IF v_cantidad <> 0 THEN
        RAISE EXCEPTION
            'ERROR: existe incoherencia entre es_actual y fecha_hasta';
    END IF;

    RAISE NOTICE
        'OK 1: estado base de DIM_EMPLEADO consistente';
END
$$;

-- ============================================================
-- 2. VALIDACIÓN DE SOLAPAMIENTOS EN LOS DATOS EXISTENTES
-- ============================================================

DO $$
DECLARE
    v_solapamientos INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO v_solapamientos
    FROM dw.dim_empleado a
    JOIN dw.dim_empleado b
      ON a.rut_normalizado = b.rut_normalizado
     AND a.empleado_key < b.empleado_key
     AND a.fecha_desde < COALESCE(b.fecha_hasta, DATE '9999-12-31')
     AND b.fecha_desde < COALESCE(a.fecha_hasta, DATE '9999-12-31');

    IF v_solapamientos <> 0 THEN
        RAISE EXCEPTION
            'ERROR: se detectaron % pares de versiones SCD2 solapadas',
            v_solapamientos;
    END IF;

    RAISE NOTICE
        'OK 2: no existen solapamientos históricos en DIM_EMPLEADO';
END
$$;

-- ============================================================
-- 3. FIXTURE SCD2 VÁLIDO
-- ============================================================
--
-- Se utiliza un RUT sintético reservado para el test.
-- Las dimensiones organizacionales utilizan miembro 0 para
-- evitar depender de datos empresariales todavía no cargados.
--
-- Versiones:
--
--   V1: [2026-01-01, 2026-02-01)
--   V2: [2026-02-01, infinito)
--
-- Esto permite comprobar el límite semiabierto.
-- ============================================================

INSERT INTO dw.dim_empleado (
    empleado_key,
    rut_normalizado,
    nombres,
    apellido_paterno,
    apellido_materno,
    fecha_nacimiento,
    fecha_ingreso,
    fecha_salida,
    area_key,
    cargo_key,
    centro_costo_key,
    estado_laboral,
    sexo,
    nacionalidad,
    fecha_desde,
    fecha_hasta,
    es_actual,
    contexto_historico_estimado
)
VALUES
(
    900001,
    '99999999-9',
    'Empleado',
    'Prueba',
    'Historico',
    NULL,
    DATE '2025-01-01',
    NULL,
    0,
    0,
    0,
    'ACTIVO',
    NULL,
    NULL,
    DATE '2026-01-01',
    DATE '2026-02-01',
    FALSE,
    FALSE
),
(
    900002,
    '99999999-9',
    'Empleado',
    'Prueba',
    'Historico',
    NULL,
    DATE '2025-01-01',
    NULL,
    0,
    0,
    0,
    'ACTIVO',
    NULL,
    NULL,
    DATE '2026-02-01',
    NULL,
    TRUE,
    FALSE
);

-- ============================================================
-- 4. RESOLUCIÓN TEMPORAL RUT + FECHA
-- ============================================================

DO $$
DECLARE
    v_empleado_key INTEGER;
    v_cantidad INTEGER;
BEGIN
    -- --------------------------------------------------------
    -- 4.1 Fecha interior de primera versión.
    -- --------------------------------------------------------
    SELECT COUNT(*), MIN(empleado_key)
    INTO v_cantidad, v_empleado_key
    FROM dw.dim_empleado
    WHERE rut_normalizado = '99999999-9'
      AND fecha_desde <= DATE '2026-01-15'
      AND (
          fecha_hasta IS NULL
          OR DATE '2026-01-15' < fecha_hasta
      );

    IF v_cantidad <> 1 OR v_empleado_key <> 900001 THEN
        RAISE EXCEPTION
            'ERROR: lookup histórico 2026-01-15 no resolvió exclusivamente empleado_key 900001';
    END IF;

    -- --------------------------------------------------------
    -- 4.2 Día anterior al cambio.
    -- --------------------------------------------------------
    SELECT COUNT(*), MIN(empleado_key)
    INTO v_cantidad, v_empleado_key
    FROM dw.dim_empleado
    WHERE rut_normalizado = '99999999-9'
      AND fecha_desde <= DATE '2026-01-31'
      AND (
          fecha_hasta IS NULL
          OR DATE '2026-01-31' < fecha_hasta
      );

    IF v_cantidad <> 1 OR v_empleado_key <> 900001 THEN
        RAISE EXCEPTION
            'ERROR: lookup histórico 2026-01-31 incorrecto';
    END IF;

    -- --------------------------------------------------------
    -- 4.3 Exactamente en el límite:
    --     2026-02-01 debe resolver V2, no V1.
    -- --------------------------------------------------------
    SELECT COUNT(*), MIN(empleado_key)
    INTO v_cantidad, v_empleado_key
    FROM dw.dim_empleado
    WHERE rut_normalizado = '99999999-9'
      AND fecha_desde <= DATE '2026-02-01'
      AND (
          fecha_hasta IS NULL
          OR DATE '2026-02-01' < fecha_hasta
      );

    IF v_cantidad <> 1 OR v_empleado_key <> 900002 THEN
        RAISE EXCEPTION
            'ERROR: límite semiabierto [desde,hasta) no resolvió empleado_key 900002';
    END IF;

    RAISE NOTICE
        'OK 3: lookup RUT + fecha y límite semiabierto funcionan correctamente';
END
$$;

-- ============================================================
-- 5. PRUEBA NEGATIVA:
--    DOS VERSIONES ACTUALES DEL MISMO RUT DEBEN SER RECHAZADAS
-- ============================================================

DO $$
BEGIN
    BEGIN
        INSERT INTO dw.dim_empleado (
            empleado_key,
            rut_normalizado,
            nombres,
            apellido_paterno,
            area_key,
            cargo_key,
            centro_costo_key,
            estado_laboral,
            fecha_desde,
            fecha_hasta,
            es_actual,
            contexto_historico_estimado
        )
        VALUES (
            900003,
            '99999999-9',
            'Empleado',
            'ActualDuplicado',
            0,
            0,
            0,
            'ACTIVO',
            DATE '2026-03-01',
            NULL,
            TRUE,
            FALSE
        );

        RAISE EXCEPTION
            'ERROR: PostgreSQL permitió dos versiones actuales para el mismo RUT';

    EXCEPTION
        WHEN unique_violation THEN
            RAISE NOTICE
                'OK 4: índice único parcial rechazó una segunda versión actual';
    END;
END
$$;

-- ============================================================
-- 6. PRUEBA NEGATIVA DE SOLAPAMIENTO
-- ============================================================
--
-- Actualmente el modelo físico no contiene una EXCLUDE
-- constraint para impedir solapamientos cerrados.
--
-- El objetivo de esta prueba es demostrar que el control de
-- calidad puede detectar un solapamiento antes de la carga
-- definitiva.
-- ============================================================

INSERT INTO dw.dim_empleado (
    empleado_key,
    rut_normalizado,
    nombres,
    apellido_paterno,
    area_key,
    cargo_key,
    centro_costo_key,
    estado_laboral,
    fecha_desde,
    fecha_hasta,
    es_actual,
    contexto_historico_estimado
)
VALUES (
    900004,
    '99999999-9',
    'Empleado',
    'Solapado',
    0,
    0,
    0,
    'ACTIVO',
    DATE '2026-01-15',
    DATE '2026-01-20',
    FALSE,
    FALSE
);

DO $$
DECLARE
    v_solapamientos INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO v_solapamientos
    FROM dw.dim_empleado a
    JOIN dw.dim_empleado b
      ON a.rut_normalizado = b.rut_normalizado
     AND a.empleado_key < b.empleado_key
     AND a.fecha_desde < COALESCE(b.fecha_hasta, DATE '9999-12-31')
     AND b.fecha_desde < COALESCE(a.fecha_hasta, DATE '9999-12-31')
    WHERE a.rut_normalizado = '99999999-9';

    IF v_solapamientos = 0 THEN
        RAISE EXCEPTION
            'ERROR: el control no detectó el solapamiento SCD2 intencional';
    END IF;

    RAISE NOTICE
        'OK 5: control de calidad detectó correctamente el solapamiento SCD2';
END
$$;

-- Eliminar sólo el fixture solapado para continuar probando
-- un escenario temporal válido.
DELETE FROM dw.dim_empleado
WHERE empleado_key = 900004;

-- ============================================================
-- 7. UN RUT + FECHA DEBE RESOLVER COMO MÁXIMO UNA VERSIÓN
-- ============================================================

DO $$
DECLARE
    v_max_versiones INTEGER;
BEGIN
    SELECT COALESCE(MAX(cantidad), 0)
    INTO v_max_versiones
    FROM (
        SELECT
            f.fecha,
            COUNT(*) AS cantidad
        FROM (
            VALUES
                (DATE '2026-01-01'),
                (DATE '2026-01-15'),
                (DATE '2026-01-31'),
                (DATE '2026-02-01'),
                (DATE '2026-03-01')
        ) AS f(fecha)
        JOIN dw.dim_empleado e
          ON e.rut_normalizado = '99999999-9'
         AND e.fecha_desde <= f.fecha
         AND (
             e.fecha_hasta IS NULL
             OR f.fecha < e.fecha_hasta
         )
        GROUP BY f.fecha
    ) t;

    IF v_max_versiones > 1 THEN
        RAISE EXCEPTION
            'ERROR: RUT + fecha resolvió más de una versión histórica';
    END IF;

    RAISE NOTICE
        'OK 6: cada RUT + fecha resuelve como máximo una versión';
END
$$;

-- ============================================================
-- 8. COMPATIBILIDAD CON FACT_ASISTENCIA
-- ============================================================
--
-- Se insertan dos hechos temporales:
--
-- 2026-01-31 -> empleado_key 900001
-- 2026-02-01 -> empleado_key 900002
--
-- Ambos representan el mismo empleado empresarial en versiones
-- históricas distintas.
-- ============================================================

INSERT INTO dw.fact_asistencia (
    fecha_key,
    empleado_key,
    area_key,
    cargo_key,
    centro_costo_key,
    turno_key,
    hora_entrada,
    hora_salida,
    estado_asistencia,
    horas_trabajadas,
    horas_normales,
    horas_extras,
    minutos_atraso,
    dias_trabajados,
    dias_ausentes,
    cantidad_registros
)
VALUES
(
    20260131,
    900001,
    0,
    0,
    0,
    0,
    TIME '08:00',
    TIME '17:00',
    'PRESENTE',
    8,
    8,
    0,
    0,
    1,
    0,
    1
),
(
    20260201,
    900002,
    0,
    0,
    0,
    0,
    TIME '08:05',
    TIME '17:05',
    'ATRASO',
    8,
    8,
    0,
    5,
    1,
    0,
    1
);

DO $$
DECLARE
    v_inconsistencias INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO v_inconsistencias
    FROM dw.fact_asistencia f
    JOIN dw.dim_fecha df
      ON df.fecha_key = f.fecha_key
    JOIN dw.dim_empleado e
      ON e.empleado_key = f.empleado_key
    WHERE f.empleado_key IN (900001, 900002)
      AND NOT (
          e.fecha_desde <= df.fecha
          AND (
              e.fecha_hasta IS NULL
              OR df.fecha < e.fecha_hasta
          )
      );

    IF v_inconsistencias <> 0 THEN
        RAISE EXCEPTION
            'ERROR: FACT_ASISTENCIA contiene empleado_key fuera de su vigencia histórica';
    END IF;

    RAISE NOTICE
        'OK 7: FACT_ASISTENCIA es compatible con la versión histórica correcta de DIM_EMPLEADO';
END
$$;

-- ============================================================
-- 9. MIEMBRO DESCONOCIDO
-- ============================================================

DO $$
DECLARE
    v_cantidad INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO v_cantidad
    FROM dw.dim_empleado
    WHERE empleado_key = 0
      AND rut_normalizado = 'DESCONOCIDO'
      AND es_actual = TRUE
      AND fecha_hasta IS NULL;

    IF v_cantidad <> 1 THEN
        RAISE EXCEPTION
            'ERROR: miembro desconocido de DIM_EMPLEADO no cumple contrato esperado';
    END IF;

    RAISE NOTICE
        'OK 8: miembro desconocido de DIM_EMPLEADO válido';
END
$$;

-- ============================================================
-- RESULTADO FINAL
-- ============================================================

DO $$
BEGIN
    RAISE NOTICE
        'TEST OK: integridad histórica SCD2 de RRHH y compatibilidad con FACT_ASISTENCIA verificadas.';
END
$$;

ROLLBACK;