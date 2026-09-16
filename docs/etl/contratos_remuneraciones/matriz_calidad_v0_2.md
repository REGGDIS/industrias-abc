# Matriz de calidad — Contratos y Remuneraciones

**Dominio:** Contratos y Remuneraciones
**Responsable:** Luis Figueroa
**Alcance final:** cinco entidades del dominio

La matriz corresponde a las reglas implementadas en:

```text
etl/validate/contratos_remuneraciones/validator.py
```

y verificadas mediante:

```text
etl/tests/test_contratos_remuneraciones_validate.py
```

## Reglas por entidad

| Entidad            | Regla                                  | Severidad |
| ------------------ | -------------------------------------- | --------- |
| Empleado           | RUT nulo, vacío o con formato inválido | ERROR     |
| Contrato           | `fecha_inicio > fecha_termino`         | ERROR     |
| Contrato           | `sueldo_base < 0`                      | ERROR     |
| Contrato           | vencido pero aún `VIGENTE`             | WARNING   |
| Liquidacion        | empleado ausente                       | ERROR     |
| Liquidacion        | montos negativos                       | ERROR     |
| ConceptoPago       | código obligatorio vacío               | ERROR     |
| ConceptoPago       | descripción obligatoria vacía          | ERROR     |
| ConceptoPago       | tipo fuera de `HABER/DESCUENTO/APORTE` | ERROR     |
| DetalleLiquidacion | `liquidacion_id` nulo                  | ERROR     |
| DetalleLiquidacion | `concepto_id` nulo                     | ERROR     |
| DetalleLiquidacion | monto nulo                             | ERROR     |
| DetalleLiquidacion | monto negativo                         | ERROR     |

## Reglas cruzadas

| Control                                              | Severidad |
| ---------------------------------------------------- | --------- |
| Contrato referencia empleado inexistente             | ERROR     |
| Liquidacion referencia empleado inexistente          | ERROR     |
| Liquidacion referencia contrato inexistente          | ERROR     |
| Contrato de la liquidación pertenece a otro empleado | ERROR     |
| Detalle referencia liquidación inexistente           | ERROR     |
| Detalle referencia concepto inexistente              | ERROR     |
| Número de contrato duplicado                         | ERROR     |
| Empleado + período duplicado en liquidaciones        | ERROR     |
| Código de concepto duplicado                         | ERROR     |
| Liquidación + concepto duplicado en detalle          | ERROR     |

## Tratamiento

**ERROR** bloquea el cierre del ETL. Si existe al menos un error:

```text
status = ERROR
stage = validacion
controles_error = 1
```

**WARNING** registra una situación que requiere revisión pero no bloquea el flujo. Por ejemplo, un contrato cuyo `fecha_termino` ya pasó pero continúa marcado como `VIGENTE`.

Las transformaciones identificadas como limpieza superficial se realizan en STAGING y no se registran como defectos cuando quedaron corregidas de manera determinística.

## Evidencia base

La corrida real sobre SQL Server produjo:

```text
procesados = 235
validos = 235
errores = 0
warnings = 0
status = OK
```

## Evidencia de detección

Se ejecutó un fallo controlado sobre una copia en memoria de `DetalleLiquidacion`, asignando:

```text
monto = -100
```

Resultado:

```text
procesados = 235
validos = 234
errores = 1
warnings = 0
status = ERROR
stage = validacion
controles_error = 1
```

Regla detectada:

```text
monto_negativo
```

Esto confirma tanto ausencia de falsos positivos en la corrida base como la capacidad del ETL para bloquear un error real de calidad.
