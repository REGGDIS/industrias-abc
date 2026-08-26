-- ============================================================
-- INDUSTRIAS ABC
-- Sistema Operacional de Recursos Humanos
-- Motor: PostgreSQL 16
-- Archivo: validaciones.sql
-- Objetivo: comprobar estructura, carga e integridad
-- ============================================================


-- ============================================================
-- 1. CONTEOS GENERALES
-- ============================================================

SELECT
    (SELECT COUNT(*) FROM centros_costo) AS centros_costo,
    (SELECT COUNT(*) FROM areas) AS areas,
    (SELECT COUNT(*) FROM cargos) AS cargos,
    (SELECT COUNT(*) FROM empleados) AS empleados;

-- Resultado esperado:
-- centros_costo = 7
-- areas         = 7
-- cargos        = 12
-- empleados     = 80


-- ============================================================
-- 2. CENTROS DE COSTO
-- ============================================================

SELECT
    centro_costo_id,
    codigo_centro_costo,
    nombre_centro_costo
FROM centros_costo
ORDER BY codigo_centro_costo;


-- ============================================================
-- 3. ÁREAS Y CENTROS DE COSTO
-- ============================================================

SELECT
    a.codigo_area,
    a.nombre_area,
    a.gerencia,
    cc.codigo_centro_costo,
    cc.nombre_centro_costo
FROM areas a
JOIN centros_costo cc
    ON cc.centro_costo_id = a.centro_costo_id
ORDER BY a.codigo_area;

-- Resultado esperado:
-- 7 áreas, cada una asociada a un único centro de costo.


-- ============================================================
-- 4. CARGOS
-- ============================================================

SELECT
    codigo_cargo,
    nombre_cargo,
    nivel,
    sueldo_base_referencial
FROM cargos
ORDER BY codigo_cargo;

-- Resultado esperado:
-- 12 cargos.


-- ============================================================
-- 5. EMPLEADOS POR ESTADO
-- ============================================================

SELECT
    estado,
    COUNT(*) AS cantidad
FROM empleados
GROUP BY estado
ORDER BY estado;


-- ============================================================
-- 6. EMPLEADOS POR ÁREA
-- ============================================================

SELECT
    a.codigo_area,
    a.nombre_area,
    COUNT(e.empleado_id) AS cantidad_empleados
FROM areas a
LEFT JOIN empleados e
    ON e.area_id = a.area_id
GROUP BY
    a.codigo_area,
    a.nombre_area
ORDER BY a.codigo_area;

-- La suma total debe ser 80.


-- ============================================================
-- 7. EMPLEADOS POR CARGO
-- ============================================================

SELECT
    c.codigo_cargo,
    c.nombre_cargo,
    COUNT(e.empleado_id) AS cantidad_empleados
FROM cargos c
LEFT JOIN empleados e
    ON e.cargo_id = c.cargo_id
GROUP BY
    c.codigo_cargo,
    c.nombre_cargo
ORDER BY c.codigo_cargo;


-- ============================================================
-- 8. DETALLE EMPLEADO + ÁREA + CARGO
-- ============================================================

SELECT
    e.empleado_id,
    e.rut,
    e.nombres,
    e.apellido_paterno,
    e.apellido_materno,
    a.codigo_area,
    a.nombre_area,
    c.codigo_cargo,
    c.nombre_cargo,
    e.estado
FROM empleados e
JOIN areas a
    ON a.area_id = e.area_id
JOIN cargos c
    ON c.cargo_id = e.cargo_id
ORDER BY e.empleado_id;

-- Resultado esperado:
-- 80 filas.


-- ============================================================
-- 9. VALIDACIÓN DE RUT DUPLICADOS
-- ============================================================

SELECT
    rut,
    COUNT(*) AS cantidad
FROM empleados
GROUP BY rut
HAVING COUNT(*) > 1;

-- Resultado esperado:
-- 0 filas.


-- ============================================================
-- 10. VALIDACIÓN DE CÓDIGOS DUPLICADOS
-- ============================================================

SELECT
    codigo_area,
    COUNT(*) AS cantidad
FROM areas
GROUP BY codigo_area
HAVING COUNT(*) > 1;

SELECT
    codigo_cargo,
    COUNT(*) AS cantidad
FROM cargos
GROUP BY codigo_cargo
HAVING COUNT(*) > 1;

SELECT
    codigo_centro_costo,
    COUNT(*) AS cantidad
FROM centros_costo
GROUP BY codigo_centro_costo
HAVING COUNT(*) > 1;

-- Resultado esperado:
-- 0 filas en las tres consultas.


-- ============================================================
-- 11. VALIDACIÓN DE CAMPOS OBLIGATORIOS
-- ============================================================

SELECT *
FROM empleados
WHERE rut IS NULL
   OR nombres IS NULL
   OR apellido_paterno IS NULL
   OR fecha_nacimiento IS NULL
   OR fecha_ingreso IS NULL
   OR area_id IS NULL
   OR cargo_id IS NULL
   OR estado IS NULL;

-- Resultado esperado:
-- 0 filas.


-- ============================================================
-- 12. VALIDACIÓN DE FORMATO DE RUT
-- ============================================================

SELECT
    empleado_id,
    rut
FROM empleados
WHERE rut !~ '^[0-9]{7,8}-[0-9Kk]$';

-- Resultado esperado:
-- 0 filas.


-- ============================================================
-- 13. VALIDACIÓN DE ESTADOS
-- ============================================================

SELECT
    empleado_id,
    rut,
    estado
FROM empleados
WHERE estado NOT IN ('ACTIVO', 'INACTIVO');

-- Resultado esperado:
-- 0 filas.


-- ============================================================
-- 14. VALIDACIÓN DE FECHAS
-- ============================================================

SELECT
    empleado_id,
    rut,
    fecha_ingreso,
    fecha_salida
FROM empleados
WHERE fecha_salida IS NOT NULL
  AND fecha_salida < fecha_ingreso;

-- Resultado esperado:
-- 0 filas.


-- ============================================================
-- 15. EMPLEADOS INACTIVOS SIN FECHA DE SALIDA
-- ============================================================

SELECT
    empleado_id,
    rut,
    nombres,
    apellido_paterno,
    estado,
    fecha_salida
FROM empleados
WHERE estado = 'INACTIVO'
  AND fecha_salida IS NULL;

-- Resultado esperado:
-- idealmente 0 filas.


-- ============================================================
-- 16. EMPLEADOS ACTIVOS CON FECHA DE SALIDA
-- ============================================================

SELECT
    empleado_id,
    rut,
    nombres,
    apellido_paterno,
    estado,
    fecha_salida
FROM empleados
WHERE estado = 'ACTIVO'
  AND fecha_salida IS NOT NULL;

-- Resultado esperado:
-- idealmente 0 filas.


-- ============================================================
-- 17. INTEGRIDAD REFERENCIAL: ÁREA
-- ============================================================

SELECT
    e.empleado_id,
    e.rut,
    e.area_id
FROM empleados e
LEFT JOIN areas a
    ON a.area_id = e.area_id
WHERE a.area_id IS NULL;

-- Resultado esperado:
-- 0 filas.


-- ============================================================
-- 18. INTEGRIDAD REFERENCIAL: CARGO
-- ============================================================

SELECT
    e.empleado_id,
    e.rut,
    e.cargo_id
FROM empleados e
LEFT JOIN cargos c
    ON c.cargo_id = e.cargo_id
WHERE c.cargo_id IS NULL;

-- Resultado esperado:
-- 0 filas.


-- ============================================================
-- 19. INTEGRIDAD ÁREA - CENTRO DE COSTO
-- ============================================================

SELECT
    a.area_id,
    a.codigo_area,
    a.centro_costo_id
FROM areas a
LEFT JOIN centros_costo cc
    ON cc.centro_costo_id = a.centro_costo_id
WHERE cc.centro_costo_id IS NULL;

-- Resultado esperado:
-- 0 filas.


-- ============================================================
-- 20. VALIDACIÓN RELACIÓN 1:1 ÁREA - CENTRO DE COSTO
-- ============================================================

SELECT
    centro_costo_id,
    COUNT(*) AS cantidad_areas
FROM areas
GROUP BY centro_costo_id
HAVING COUNT(*) > 1;

-- Resultado esperado:
-- 0 filas.


-- ============================================================
-- 21. SUELDOS BASE REFERENCIALES INVÁLIDOS
-- ============================================================

SELECT
    codigo_cargo,
    nombre_cargo,
    sueldo_base_referencial
FROM cargos
WHERE sueldo_base_referencial < 0;

-- Resultado esperado:
-- 0 filas.


-- ============================================================
-- 22. RESUMEN GENERAL RRHH
-- ============================================================

SELECT
    COUNT(*) AS total_empleados,
    COUNT(*) FILTER (WHERE estado = 'ACTIVO') AS activos,
    COUNT(*) FILTER (WHERE estado = 'INACTIVO') AS inactivos,
    COUNT(DISTINCT area_id) AS areas_con_empleados,
    COUNT(DISTINCT cargo_id) AS cargos_utilizados
FROM empleados;