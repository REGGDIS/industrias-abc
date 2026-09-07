Evidencia de validación — Contratos y Remuneraciones (v0.2)

⚠️ Esta evidencia se generó revisando el código y ejecutando las pruebas unitarias (que no requieren base de datos). La ejecución real de etl/validate/contratos_remuneraciones.py contra SQL Server debe hacerla el responsable del dominio y actualizar los resultados reales abajo antes de cerrar el PR.

Pruebas unitarias (sin base de datos)
pytest etl/tests/test_contratos_remuneraciones_validate.py -v

============================= test session starts ==============================
collected 26 items

... 26 passed in 0.04s

Todas las funciones de regla (rule_rut_invalido, rule_fecha_inicio_mayor_termino, rule_contrato_vencido, rule_liquidacion_sin_empleado, rule_monto_negativo) y las funciones de clasificación por entidad (evaluar_empleado, evaluar_contrato, evaluar_liquidacion) están cubiertas, incluyendo casos límite (RUT vacío/nulo/formato inválido, contrato vencido vs. terminado, montos negativos, ausencia de fecha_termino en indefinidos).

Ejecución contra la base de datos real — PENDIENTE DE COMPLETAR

Ejecutar en orden y pegar aquí los resultados reales:

-- 1) Cargar RAW
etl/sql/load/contratos_remuneraciones/empleado.sql
etl/sql/load/contratos_remuneraciones/contrato.sql
etl/sql/load/contratos_remuneraciones/liquidacion.sql

-- 2) Crear vistas de staging
etl/sql/staging/contratos_remuneraciones/empleado.sql
etl/sql/staging/contratos_remuneraciones/contrato.sql
etl/sql/staging/contratos_remuneraciones/liquidacion.sql

-- 3) Validar
python etl/validate/contratos_remuneraciones.py

Resultado esperado (a confirmar con los datos reales del seed.sql, 80 empleados / 21 contratos / 19 liquidaciones):

 raw.contratos_remuneraciones_empleado: ___ filas
 raw.contratos_remuneraciones_contrato: ___ filas
 raw.contratos_remuneraciones_liquidacion: ___ filas
 Hallazgos ERROR: ___
 Hallazgos WARNING: ___
 Detalle de hallazgos (pegar salida completa del script aquí)
Nota sobre datos de prueba "limpios"

El seed.sql de la base operacional (v0.1/v0.2 corregido) se generó sin inconsistencias intencionales (sueldos, fechas y RUTs válidos). Por lo tanto, es esperable que la ejecución real contra esos datos arroje 0 ERROR y 0 WARNING — lo cual demuestra que las reglas no generan falsos positivos, pero no prueba por sí solo que detecten problemas reales. Se recomienda, antes de la entrega final del equipo, insertar 2-3 filas de prueba con inconsistencias deliberadas (ver sección 15 del Informe Universo Empresarial) y volver a correr etl/validate/contratos_remuneraciones.py para confirmar que las reglas sí las detectan, y documentar esa segunda corrida aquí también.
