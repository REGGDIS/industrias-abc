# Matriz de calidad — Contratos y Remuneraciones (v0.2)

**Dominio:** Contratos y Remuneraciones
**Responsable:** Luis Figueroa
**Alcance de esta versión:** Empleado, Contrato, Liquidación (las 3 entidades del Encargo 0.2)

Esta matriz refleja las reglas mínimas exigidas por el Encargo 0.2 e implementadas en `etl/validate/contratos_remuneraciones.py`, con pruebas en `etl/tests/test_contratos_remuneraciones_validate.py`.

| Entidad | Regla | Severidad | Dónde se implementa |
|---|---|---|---|
| Contrato | `fecha_inicio` > `fecha_termino` | **ERROR** | `rule_fecha_inicio_mayor_termino` |
| Contrato | `sueldo_base` negativo | **ERROR** | `rule_monto_negativo` |
| Contrato | Vencido (`fecha_termino` en el pasado) pero `estado = VIGENTE` | **WARNING** | `rule_contrato_vencido` + columna derivada `contrato_vencido` en staging |
| Liquidacion | Sin `empleado_id` asociado | **ERROR** | `rule_liquidacion_sin_empleado` |
| Liquidacion | Algún monto negativo (sueldo_base, horas_extras, sueldo_imponible, sueldo_liquido, costo_empresa) | **ERROR** | `rule_monto_negativo` |
| Empleado | `rut_referencia` nulo, vacío o con formato claramente inválido | **ERROR** | `rule_rut_invalido` |
| Todas | Texto con espacios extremos / mayúsculas inconsistentes | **CLEAN** (ya resuelto) | Limpieza aplicada en las vistas `staging.*` (`LTRIM`/`RTRIM`/`UPPER`) |

## Criterio de tratamiento

- **ERROR**: bloquea el avance del registro hacia ETL Core. No se descarta automáticamente el dato; queda reportado por `etl/validate/contratos_remuneraciones.py` para que el equipo decida cómo corregirlo en el origen.
- **WARNING**: el dato es válido a nivel de esquema, pero representa una situación operativa a revisar (un contrato vencido que nadie cerró). No bloquea el flujo.
- **CLEAN**: ya resuelto en la capa `staging` (vistas SQL), no requiere intervención adicional del script de validación.

## Cómo se ejecuta
