-- =========================================================
-- VALIDACIONES.SQL
-- Sistema Operacional de Control de Asistencia
-- Industrias ABC
-- Motor: MySQL / InnoDB
--
-- Ejecutar después de:
-- 1. schema.sql
-- 2. seed.sql
-- =========================================================

USE sistemadeasistenciaindustriasabc;

-- =========================================================
-- 1. CONTEO DE REGISTROS
-- =========================================================

SELECT 'trabajador' AS tabla, COUNT(*) AS registros
FROM trabajador

UNION ALL

SELECT 'turnos', COUNT(*)
FROM turnos

UNION ALL

SELECT 'asistencia', COUNT(*)
FROM asistencia;


-- =========================================================
-- 2. DUPLICADOS DE TRABAJADORES POR RUT
-- Debe devolver 0 filas.
-- =========================================================

SELECT
    rut,
    COUNT(*) AS repeticiones
FROM trabajador
GROUP BY rut
HAVING COUNT(*) > 1;


-- =========================================================
-- 3. POSIBLES DUPLICADOS POR NOMBRE + APELLIDO
-- Debe devolver 0 filas en este seed.
-- =========================================================

SELECT
    nombre,
    apellido,
    COUNT(*) AS repeticiones
FROM trabajador
GROUP BY nombre, apellido
HAVING COUNT(*) > 1;


-- =========================================================
-- 4. CAMPOS OBLIGATORIOS DE TRABAJADOR
-- Debe devolver 0 filas.
-- =========================================================

SELECT *
FROM trabajador
WHERE rut IS NULL
   OR TRIM(rut) = ''
   OR nombre IS NULL
   OR TRIM(nombre) = ''
   OR apellido IS NULL
   OR TRIM(apellido) = ''
   OR fecha_ingreso IS NULL;


-- =========================================================
-- 5. ASISTENCIAS SIN TRABAJADOR VÁLIDO
-- Debe devolver 0 filas.
-- =========================================================

SELECT
    a.asistencia_id,
    a.trabajador_id
FROM asistencia a
LEFT JOIN trabajador t
    ON t.trabajador_id = a.trabajador_id
WHERE t.trabajador_id IS NULL;


-- =========================================================
-- 6. ASISTENCIAS SIN TURNO VÁLIDO
-- Debe devolver 0 filas.
-- =========================================================

SELECT
    a.asistencia_id,
    a.turno_id
FROM asistencia a
LEFT JOIN turnos tu
    ON tu.turno_id = a.turno_id
WHERE tu.turno_id IS NULL;


-- =========================================================
-- 7. DUPLICADOS DE ASISTENCIA POR TRABAJADOR + FECHA
-- Grano esperado: un trabajador por día.
-- Debe devolver 0 filas.
-- =========================================================

SELECT
    trabajador_id,
    fecha,
    COUNT(*) AS repeticiones
FROM asistencia
GROUP BY trabajador_id, fecha
HAVING COUNT(*) > 1;


-- =========================================================
-- 8. CAMPOS OBLIGATORIOS DE ASISTENCIA
-- Debe devolver 0 filas.
-- =========================================================

SELECT *
FROM asistencia
WHERE trabajador_id IS NULL
   OR turno_id IS NULL
   OR fecha IS NULL
   OR horas_trabajadas IS NULL
   OR horas_normales IS NULL
   OR horas_extras IS NULL
   OR atraso_minutos IS NULL
   OR ausentismo IS NULL
   OR estado IS NULL;


-- =========================================================
-- 9. VALORES NEGATIVOS
-- Debe devolver 0 filas.
-- =========================================================

SELECT *
FROM asistencia
WHERE horas_trabajadas < 0
   OR horas_normales < 0
   OR horas_extras < 0
   OR atraso_minutos < 0;


-- =========================================================
-- 10. AUSENTISMO INVÁLIDO
-- Debe devolver 0 filas.
-- =========================================================

SELECT *
FROM asistencia
WHERE ausentismo NOT IN (0, 1);


-- =========================================================
-- 11. ESTADOS FUERA DEL DOMINIO
-- Debe devolver 0 filas.
-- =========================================================

SELECT *
FROM asistencia
WHERE estado NOT IN ('PRESENTE', 'ATRASO', 'AUSENTE');


-- =========================================================
-- 12. ASISTENCIA PRESENTE / ATRASO SIN HORARIO
-- Debe devolver 0 filas.
-- =========================================================

SELECT *
FROM asistencia
WHERE estado IN ('PRESENTE', 'ATRASO')
  AND (
      hora_entrada IS NULL
      OR hora_salida IS NULL
  );


-- =========================================================
-- 13. AUSENCIAS INCOHERENTES
--
-- Una ausencia debe tener:
-- - hora_entrada NULL
-- - hora_salida NULL
-- - horas trabajadas = 0
-- - horas normales = 0
-- - horas extras = 0
-- - atraso = 0
-- - ausentismo = 1
-- - estado AUSENTE
--
-- Debe devolver 0 filas.
-- =========================================================

SELECT *
FROM asistencia
WHERE estado = 'AUSENTE'
  AND (
      ausentismo <> 1
      OR hora_entrada IS NOT NULL
      OR hora_salida IS NOT NULL
      OR horas_trabajadas <> 0
      OR horas_normales <> 0
      OR horas_extras <> 0
      OR atraso_minutos <> 0
  );


-- =========================================================
-- 14. REGISTROS MARCADOS COMO AUSENTISMO SIN ESTADO AUSENTE
-- Debe devolver 0 filas.
-- =========================================================

SELECT *
FROM asistencia
WHERE ausentismo = 1
  AND estado <> 'AUSENTE';


-- =========================================================
-- 15. ATRASOS INCOHERENTES
--
-- Si atraso_minutos > 0, el estado debe ser ATRASO.
-- Si estado = ATRASO, debe existir atraso_minutos > 0.
--
-- Debe devolver 0 filas.
-- =========================================================

SELECT *
FROM asistencia
WHERE (atraso_minutos > 0 AND estado <> 'ATRASO')
   OR (estado = 'ATRASO' AND atraso_minutos <= 0);


-- =========================================================
-- 16. HORAS EXTRA INCONSISTENTES
-- Debe devolver 0 filas.
-- =========================================================

SELECT *
FROM asistencia
WHERE horas_extras > horas_trabajadas;


-- =========================================================
-- 17. COHERENCIA HORAS TRABAJADAS
--
-- horas_trabajadas debe equivaler a:
-- horas_normales + horas_extras
--
-- Se usa tolerancia de 0.01 por redondeos decimales.
-- Debe devolver 0 filas.
-- =========================================================

SELECT *
FROM asistencia
WHERE ABS(
    horas_trabajadas - (horas_normales + horas_extras)
) > 0.01;


-- =========================================================
-- 18. HORAS NORMALES SOBRE JORNADA DEL TURNO
--
-- Las horas normales no deberían superar horas_jornada.
-- Las horas adicionales deben ir a horas_extras.
--
-- Debe devolver 0 filas.
-- =========================================================

SELECT
    a.asistencia_id,
    a.trabajador_id,
    a.fecha,
    a.horas_normales,
    tu.horas_jornada
FROM asistencia a
JOIN turnos tu
    ON tu.turno_id = a.turno_id
WHERE a.horas_normales > tu.horas_jornada;


-- =========================================================
-- 19. FECHA DE ASISTENCIA ANTERIOR AL INGRESO
-- Debe devolver 0 filas.
-- =========================================================

SELECT
    a.asistencia_id,
    a.trabajador_id,
    t.fecha_ingreso,
    a.fecha
FROM asistencia a
JOIN trabajador t
    ON t.trabajador_id = a.trabajador_id
WHERE a.fecha < t.fecha_ingreso;


-- =========================================================
-- 20. ASISTENCIAS FUERA DEL PERÍODO DE REFERENCIA DEL MASTER
--
-- Universo Empresarial:
-- 2025-01-01 a 2026-07-31
--
-- Debe devolver 0 filas.
-- =========================================================

SELECT *
FROM asistencia
WHERE fecha < '2025-01-01'
   OR fecha > '2026-07-31';


-- =========================================================
-- 21. RUT CON FORMATO LOCAL ESPERADO
--
-- Para esta fuente se utiliza intencionalmente formato
-- XX.XXX.XXX-X, distinto de otras fuentes, para homologación.
--
-- Debe devolver 0 filas.
-- =========================================================

SELECT *
FROM trabajador
WHERE rut NOT REGEXP '^[0-9]{2}\\.[0-9]{3}\\.[0-9]{3}-[0-9Kk]$';


-- =========================================================
-- 22. RESUMEN DE ASISTENCIA POR TRABAJADOR
-- Consulta informativa.
-- =========================================================

SELECT
    t.trabajador_id,
    t.rut,
    t.nombre,
    t.apellido,
    COUNT(a.asistencia_id) AS registros_asistencia,
    SUM(a.horas_trabajadas) AS total_horas_trabajadas,
    SUM(a.horas_normales) AS total_horas_normales,
    SUM(a.horas_extras) AS total_horas_extras,
    SUM(a.atraso_minutos) AS total_minutos_atraso,
    SUM(a.ausentismo) AS total_ausencias
FROM trabajador t
LEFT JOIN asistencia a
    ON a.trabajador_id = t.trabajador_id
GROUP BY
    t.trabajador_id,
    t.rut,
    t.nombre,
    t.apellido
ORDER BY t.trabajador_id;


-- =========================================================
-- 23. DISTRIBUCIÓN POR ESTADO
-- Consulta informativa.
-- =========================================================

SELECT
    estado,
    COUNT(*) AS registros
FROM asistencia
GROUP BY estado
ORDER BY estado;


-- =========================================================
-- 24. DISTRIBUCIÓN POR TURNO
-- Consulta informativa.
-- =========================================================

SELECT
    tu.turno_id,
    tu.nombre_turno,
    COUNT(a.asistencia_id) AS registros_asistencia
FROM turnos tu
LEFT JOIN asistencia a
    ON a.turno_id = tu.turno_id
GROUP BY
    tu.turno_id,
    tu.nombre_turno
ORDER BY tu.turno_id;


-- =========================================================
-- 25. RESUMEN FINAL DE CONTROLES CRÍTICOS
--
-- Todos deben mostrar resultado = OK.
-- =========================================================

SELECT
    'Duplicados de RUT' AS validacion,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM trabajador
            GROUP BY rut
            HAVING COUNT(*) > 1
        )
        THEN 'ERROR'
        ELSE 'OK'
    END AS resultado

UNION ALL

SELECT
    'Duplicados trabajador-fecha',
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM asistencia
            GROUP BY trabajador_id, fecha
            HAVING COUNT(*) > 1
        )
        THEN 'ERROR'
        ELSE 'OK'
    END

UNION ALL

SELECT
    'FK trabajador válida',
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM asistencia a
            LEFT JOIN trabajador t
                ON t.trabajador_id = a.trabajador_id
            WHERE t.trabajador_id IS NULL
        )
        THEN 'ERROR'
        ELSE 'OK'
    END

UNION ALL

SELECT
    'FK turno válida',
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM asistencia a
            LEFT JOIN turnos tu
                ON tu.turno_id = a.turno_id
            WHERE tu.turno_id IS NULL
        )
        THEN 'ERROR'
        ELSE 'OK'
    END

UNION ALL

SELECT
    'Valores no negativos',
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM asistencia
            WHERE horas_trabajadas < 0
               OR horas_normales < 0
               OR horas_extras < 0
               OR atraso_minutos < 0
        )
        THEN 'ERROR'
        ELSE 'OK'
    END

UNION ALL

SELECT
    'Estados válidos',
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM asistencia
            WHERE estado NOT IN ('PRESENTE', 'ATRASO', 'AUSENTE')
        )
        THEN 'ERROR'
        ELSE 'OK'
    END

UNION ALL

SELECT
    'Ausencias coherentes',
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM asistencia
            WHERE estado = 'AUSENTE'
              AND (
                  ausentismo <> 1
                  OR hora_entrada IS NOT NULL
                  OR hora_salida IS NOT NULL
                  OR horas_trabajadas <> 0
                  OR horas_normales <> 0
                  OR horas_extras <> 0
                  OR atraso_minutos <> 0
              )
        )
        THEN 'ERROR'
        ELSE 'OK'
    END

UNION ALL

SELECT
    'Atrasos coherentes',
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM asistencia
            WHERE (atraso_minutos > 0 AND estado <> 'ATRASO')
               OR (estado = 'ATRASO' AND atraso_minutos <= 0)
        )
        THEN 'ERROR'
        ELSE 'OK'
    END

UNION ALL

SELECT
    'Horas coherentes',
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM asistencia
            WHERE ABS(
                horas_trabajadas - (horas_normales + horas_extras)
            ) > 0.01
        )
        THEN 'ERROR'
        ELSE 'OK'
    END

UNION ALL

SELECT
    'Fechas dentro del período',
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM asistencia
            WHERE fecha < '2025-01-01'
               OR fecha > '2026-07-31'
        )
        THEN 'ERROR'
        ELSE 'OK'
    END;