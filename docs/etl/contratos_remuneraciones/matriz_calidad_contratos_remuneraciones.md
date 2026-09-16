# Matriz de calidad — Contratos y Remuneraciones

**Dominio:** Contratos y Remuneraciones
**Responsable:** Luis Figueroa
**Motor de origen:** SQL Server
**Fuente física:** `sources/contratos-remuneraciones-sqlserver/sql/` (`schema.sql`, `seed.sql`, `validaciones.sql`)

Esta matriz distingue entre **ERROR** (bloquea el avance del dato hacia ETL Core: debe dar 0 filas) y **ADVERTENCIA/ALERTA** (no bloquea, pero debe quedar registrada y revisada por el equipo). Las consultas que sustentan cada control ya existen en `validaciones.sql`.

| Entidad | Control | Esperado | Tratamiento |
|---|---|---|---|
| Empleado | `empleado_id` / `rut_referencia` / `nombre_completo` obligatorios | 0 faltantes | ERROR |
| Contrato | `numero_contrato` duplicado | 0 filas | ERROR |
| Contrato | `tipo_contrato` fuera de INDEFINIDO/PLAZO_FIJO/TEMPORAL | 0 filas | ERROR |
| Contrato | `estado` fuera de VIGENTE/TERMINADO | 0 filas | ERROR |
| Contrato | `sueldo_base` ≤ 0 | 0 filas | ERROR |
| Contrato | PLAZO_FIJO/TEMPORAL sin `fecha_termino` | 0 filas | ERROR |
| Contrato | `fecha_termino` < `fecha_inicio` | 0 filas | ERROR |
| Contrato | `empleado_id` inexistente (huérfano) | 0 filas | ERROR |
| Contrato | Contrato vencido (`fecha_termino` en el pasado) pero sigue `VIGENTE` | 0 filas ideal | ADVERTENCIA |
| ConceptoPago | `codigo` duplicado | 0 filas | ERROR |
| ConceptoPago | `tipo` fuera de HABER/DESCUENTO/APORTE | 0 filas | ERROR |
| Liquidacion | Duplicado `empleado_id` + `periodo` | 0 filas | ERROR |
| Liquidacion | `periodo` fuera de formato YYYY-MM o mes fuera de 01–12 | 0 filas | ERROR |
| Liquidacion | `empleado_id` o `contrato_id` inexistente (huérfano) | 0 filas | ERROR |
| Liquidacion | El `contrato_id` referenciado pertenece a otro empleado | 0 filas | ERROR |
| Liquidacion | `horas_extras` o montos negativos | 0 filas | ERROR |
| Liquidacion | `sueldo_base` distinto al `sueldo_base` del contrato vigente | 0 filas ideal | ADVERTENCIA |
| Liquidacion | `sueldo_liquido` > `sueldo_imponible` | 0 filas ideal | ALERTA / revisar |
| DetalleLiquidacion | Duplicado `liquidacion_id` + `concepto_id` | 0 filas | ERROR |
| DetalleLiquidacion | `liquidacion_id` o `concepto_id` inexistente (huérfano) | 0 filas | ERROR |
| DetalleLiquidacion | `monto` < 0 | 0 filas | ERROR |

## Criterio de tratamiento

- **ERROR**: el registro no debería avanzar a staging/ETL Core sin corregirse en el origen. Corresponde a una violación de una restricción ya declarada en `schema.sql` (PK, FK, UNIQUE, CHECK) o a una regla de negocio explícita del dominio.
- **ADVERTENCIA / ALERTA**: el dato es válido según el esquema físico, pero representa una situación que el equipo debe revisar (por ejemplo, un contrato vencido que aún no se marcó como `TERMINADO`, o una liquidación cuyo sueldo base ya no coincide con el contrato porque hubo un reajuste posterior). No se descarta ni se "corrige" automáticamente en esta etapa.

## Trazabilidad con validaciones.sql

Cada fila de esta matriz corresponde a una o más consultas ya existentes en `sources/contratos-remuneraciones-sqlserver/sql/validaciones.sql` (secciones 2 a 5: duplicados, nulos, relaciones huérfanas y reglas de negocio). Esta matriz no reemplaza esas consultas: las documenta como criterio de aceptación para que ETL Core sepa qué esperar del dominio antes de homologar y cargar al Data Warehouse.
