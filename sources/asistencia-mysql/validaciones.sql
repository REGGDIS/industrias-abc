-- ============================================
-- VALIDACIONES - SISTEMA DE ASISTENCIA
-- Industrias ABC
-- ============================================

-- 1. Conteo de registros por tabla

SELECT 'Área' AS Tabla, COUNT(*) AS Cantidad
FROM area

UNION ALL

SELECT 'Cargo', COUNT(*)
FROM cargo

UNION ALL

SELECT 'Turno', COUNT(*)
FROM turno

UNION ALL

SELECT 'Trabajador', COUNT(*)
FROM trabajador

UNION ALL

SELECT 'Asistencia', COUNT(*)
FROM asistencia;

-- 2. Detección de trabajadores duplicados por RUT

SELECT Rut, COUNT(*) AS Cantidad
FROM trabajador
GROUP BY Rut
HAVING COUNT(*) > 1;

-- 3. Detección de posibles trabajadores duplicados

SELECT Nombre, Apellido, COUNT(*) AS Cantidad
FROM trabajador
GROUP BY Nombre, Apellido
HAVING COUNT(*) > 1;

-- 4. Trabajadores con datos obligatorios faltantes

SELECT *
FROM trabajador
WHERE Rut IS NULL
   OR Nombre IS NULL
   OR Apellido IS NULL
   OR FechaIngreso IS NULL
   OR IdArea IS NULL
   OR IdCargo IS NULL
   OR IdTurno IS NULL;

-- 5. Asistencias sin trabajador correspondiente

SELECT a.*
FROM asistencia a
LEFT JOIN trabajador t
    ON a.IdTrabajador = t.IdTrabajador
WHERE t.IdTrabajador IS NULL;

-- 6. Trabajadores sin área correspondiente

SELECT t.*
FROM trabajador t
LEFT JOIN area a
    ON t.IdArea = a.IdArea
WHERE a.IdArea IS NULL;

-- 7. Trabajadores sin cargo correspondiente

SELECT t.*
FROM trabajador t
LEFT JOIN cargo c
    ON t.IdCargo = c.IdCargo
WHERE c.IdCargo IS NULL;

-- 8. Trabajadores sin turno correspondiente

SELECT t.*
FROM trabajador t
LEFT JOIN turno tu
    ON t.IdTurno = tu.IdTurno
WHERE tu.IdTurno IS NULL;

-- 9. Validación de horas trabajadas

SELECT *
FROM asistencia
WHERE HorasTrabajadas < 0
   OR HorasExtra < 0
   OR Atraso < 0;

-- 10. Validación del indicador de ausentismo

SELECT *
FROM asistencia
WHERE Ausentismo NOT IN (0, 1);

-- 11. Asistencias con horario inconsistente

SELECT *
FROM asistencia
WHERE Ausentismo = 0
  AND (
      HoraEntrada IS NULL
      OR HoraSalida IS NULL
  );

-- 12. Validación de horas extra

SELECT *
FROM asistencia
WHERE HorasExtra > HorasTrabajadas;

-- 13. Resumen de asistencia por trabajador

SELECT
    t.IdTrabajador,
    t.Nombre,
    t.Apellido,
    COUNT(a.IdAsistencia) AS RegistrosAsistencia,
    SUM(a.HorasTrabajadas) AS TotalHorasTrabajadas,
    SUM(a.HorasExtra) AS TotalHorasExtra,
    SUM(a.Atraso) AS TotalMinutosAtraso
FROM trabajador t
LEFT JOIN asistencia a
    ON t.IdTrabajador = a.IdTrabajador
GROUP BY
    t.IdTrabajador,
    t.Nombre,
    t.Apellido
ORDER BY t.IdTrabajador;