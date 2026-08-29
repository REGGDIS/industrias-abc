/* ============================================================================
   validaciones.sql — Verificación de la Base de Datos Operacional
   Dominio: Contratos y Remuneraciones
   Motor:   SQL Server
   ----------------------------------------------------------------------------
   Ejecutar después de schema.sql y seed.sql. Cada bloque debe revisarse
   manualmente: los conteos deben ser mayores a 0 y las consultas de
   "detección de problemas" deben devolver 0 filas (o filas justificadas).
   ============================================================================ */
USE ContratosRemuneraciones_ABC;
GO

-- ============================================================================
-- 1. CONTEOS GENERALES
-- ============================================================================
SELECT 'Empleado'            AS tabla, COUNT(*) AS total FROM dbo.Empleado
UNION ALL
SELECT 'Contrato',           COUNT(*) FROM dbo.Contrato
UNION ALL
SELECT 'Liquidacion',        COUNT(*) FROM dbo.Liquidacion
UNION ALL
SELECT 'ConceptoPago',       COUNT(*) FROM dbo.ConceptoPago
UNION ALL
SELECT 'DetalleLiquidacion', COUNT(*) FROM dbo.DetalleLiquidacion;
GO

-- ============================================================================
-- 2. DUPLICADOS (deben devolver 0 filas)
-- ============================================================================

-- 2.1 Contratos con número de contrato repetido
SELECT numero_contrato, COUNT(*) AS repeticiones
FROM dbo.Contrato
GROUP BY numero_contrato
HAVING COUNT(*) > 1;

-- 2.2 Más de una liquidación para el mismo empleado en el mismo período
SELECT empleado_id, periodo, COUNT(*) AS repeticiones
FROM dbo.Liquidacion
GROUP BY empleado_id, periodo
HAVING COUNT(*) > 1;

-- 2.3 Código de concepto de pago repetido
SELECT codigo, COUNT(*) AS repeticiones
FROM dbo.ConceptoPago
GROUP BY codigo
HAVING COUNT(*) > 1;
GO

-- ============================================================================
-- 3. VALORES NULOS EN CAMPOS OBLIGATORIOS (deben devolver 0 filas)
-- ============================================================================
SELECT contrato_id FROM dbo.Contrato
WHERE empleado_id IS NULL OR numero_contrato IS NULL OR tipo_contrato IS NULL
   OR fecha_inicio IS NULL OR jornada IS NULL OR sueldo_base IS NULL
   OR cargo_contrato IS NULL OR estado IS NULL;

SELECT liquidacion_id FROM dbo.Liquidacion
WHERE empleado_id IS NULL OR contrato_id IS NULL OR periodo IS NULL
   OR sueldo_base IS NULL OR sueldo_imponible IS NULL
   OR sueldo_liquido IS NULL OR costo_empresa IS NULL;
GO

-- ============================================================================
-- 4. RELACIONES SIN CORRESPONDENCIA / HUÉRFANAS (deben devolver 0 filas)
--    (la mayoría son redundantes gracias a las FK, pero sirven como evidencia
--    explícita de integridad referencial para la revisión del equipo)
-- ============================================================================

-- 4.1 Contratos que referencian un empleado inexistente
SELECT c.contrato_id, c.empleado_id
FROM dbo.Contrato c
LEFT JOIN dbo.Empleado e ON e.empleado_id = c.empleado_id
WHERE e.empleado_id IS NULL;

-- 4.2 Liquidaciones que referencian un contrato inexistente
SELECT l.liquidacion_id, l.contrato_id
FROM dbo.Liquidacion l
LEFT JOIN dbo.Contrato c ON c.contrato_id = l.contrato_id
WHERE c.contrato_id IS NULL;

-- 4.3 Detalle de liquidación que referencia un concepto inexistente
SELECT dl.detalle_id, dl.concepto_id
FROM dbo.DetalleLiquidacion dl
LEFT JOIN dbo.ConceptoPago cp ON cp.concepto_id = dl.concepto_id
WHERE cp.concepto_id IS NULL;

-- 4.4 Liquidaciones cuyo contrato pertenece a OTRO empleado (inconsistencia cruzada)
SELECT l.liquidacion_id, l.empleado_id AS empleado_liquidacion, c.empleado_id AS empleado_contrato
FROM dbo.Liquidacion l
JOIN dbo.Contrato c ON c.contrato_id = l.contrato_id
WHERE l.empleado_id <> c.empleado_id;
GO

-- ============================================================================
-- 5. REGLAS DE NEGOCIO (heredadas del IDF y el Modelo Conceptual)
-- ============================================================================

-- 5.1 Contratos plazo fijo/temporal sin fecha_termino (el CHECK ya lo impide;
--     esta consulta es evidencia adicional de que la regla se respeta)
SELECT contrato_id, tipo_contrato, fecha_termino
FROM dbo.Contrato
WHERE tipo_contrato IN ('PLAZO_FIJO','TEMPORAL') AND fecha_termino IS NULL;

-- 5.2 Contratos vencidos (fecha_termino en el pasado) que siguen marcados VIGENTE
--     — señal de que el dato debería actualizarse antes de la siguiente liquidación
SELECT contrato_id, numero_contrato, fecha_termino, estado
FROM dbo.Contrato
WHERE fecha_termino IS NOT NULL AND fecha_termino < CAST(GETDATE() AS DATE) AND estado = 'VIGENTE';

-- 5.3 Liquidaciones cuyo sueldo_base no coincide con el sueldo_base del contrato
--     vigente que referencian (alerta, no error duro: podría deberse a un
--     reajuste registrado después de la liquidación)
SELECT l.liquidacion_id, l.sueldo_base AS sueldo_liquidacion, c.sueldo_base AS sueldo_contrato
FROM dbo.Liquidacion l
JOIN dbo.Contrato c ON c.contrato_id = l.contrato_id
WHERE l.sueldo_base <> c.sueldo_base;

-- 5.4 Liquidaciones donde sueldo_liquido es mayor que sueldo_imponible + no imponibles
--     esperado (validación gruesa: el líquido no debería superar el imponible)
SELECT liquidacion_id, sueldo_imponible, sueldo_liquido
FROM dbo.Liquidacion
WHERE sueldo_liquido > sueldo_imponible;
GO

-- ============================================================================
-- 6. TOTALES RELEVANTES PARA EL NEGOCIO (respaldan las preguntas de BI del IDF)
-- ============================================================================

-- 6.1 Costo laboral total y promedio por período
SELECT periodo,
       COUNT(*)                    AS liquidaciones,
       SUM(costo_empresa)          AS costo_total,
       AVG(costo_empresa)          AS costo_promedio
FROM dbo.Liquidacion
GROUP BY periodo
ORDER BY periodo;

-- 6.2 Costo laboral por área (vía Empleado → codigo_area_ref)
SELECT e.codigo_area_ref,
       COUNT(*)           AS liquidaciones,
       SUM(l.costo_empresa) AS costo_total
FROM dbo.Liquidacion l
JOIN dbo.Empleado e ON e.empleado_id = l.empleado_id
GROUP BY e.codigo_area_ref
ORDER BY costo_total DESC;

-- 6.3 % que representan las horas extra sobre el costo total (pregunta de negocio del IDF)
SELECT
    SUM(dl.monto) AS costo_horas_extra,
    (SELECT SUM(costo_empresa) FROM dbo.Liquidacion) AS costo_total_empresa,
    CAST(SUM(dl.monto) * 100.0 / (SELECT SUM(costo_empresa) FROM dbo.Liquidacion) AS DECIMAL(5,2)) AS porcentaje_horas_extra
FROM dbo.DetalleLiquidacion dl
JOIN dbo.ConceptoPago cp ON cp.concepto_id = dl.concepto_id
WHERE cp.codigo = 'HORAS_EXTRA';

-- 6.4 Contratos vigentes vs. terminados
SELECT estado, COUNT(*) AS total
FROM dbo.Contrato
GROUP BY estado;
GO
