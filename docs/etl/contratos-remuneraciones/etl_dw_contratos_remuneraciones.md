# ETL → DW — Contratos y Remuneraciones

## Alcance

Implementa la carga del dominio operacional de Contratos y Remuneraciones (SQL Server) hacia el Data Warehouse PostgreSQL de Industrias ABC.

El DW físico ya existe y está compuesto por:

- `dw.dim_contrato`
- `dw.fact_remuneraciones`

El flujo reutiliza el staging y las validaciones vigentes del dominio; no consulta las tablas operacionales directamente para construir el DW.

## Claves y homologación

- Empleado: RUT normalizado y con dígito verificador válido.
- DIM_EMPLEADO: resolución histórica por RUT + fecha del hecho, usando intervalo semiabierto `[fecha_desde, fecha_hasta)`.
- Contrato: `numero_contrato`.
- Cargo contractual: `codigo_cargo_ref` de la referencia local, resuelto contra `dw.dim_cargo`.
- Área, cargo y centro de costo de `FACT_REMUNERACIONES`: se obtienen de la misma versión histórica de `dw.dim_empleado`; no se infieren por nombre.
- Los IDs locales `empleado_id`, `contrato_id`, `liquidacion_id`, `concepto_id` y `detalle_id` no son claves empresariales del DW.

## DIM_CONTRATO

Tratamiento SCD Tipo 1. Se realiza UPSERT por `numero_contrato`.

Atributos cargados:

- empleado_key
- cargo_key
- tipo_contrato
- fecha_inicio / fecha_termino
- jornada
- sueldo_base_contractual
- cargo_contrato
- estado_contrato

Si empleado o cargo no se pueden resolver de forma determinística, se utiliza miembro 0 y se registra REVIEW para la ejecución.

## FACT_REMUNERACIONES

Grano: una fila por empleado empresarial y período mensual.

La fecha dimensional corresponde al primer día del período `YYYY-MM`.

Medidas de cabecera:

- sueldo_base
- horas_extras
- sueldo_imponible
- sueldo_liquido
- costo_empresa

Medidas derivadas del detalle:

- total_haberes = suma de conceptos `HABER`
- total_descuentos = suma de conceptos `DESCUENTO`
- total_aportes = suma de conceptos `APORTE`

No se recalculan los montos de cabecera desde fórmulas laborales; se conservan los valores informados por la fuente. Los totales de detalle se agregan únicamente según la clasificación de `ConceptoPago.tipo`.

Si la fecha no existe en DIM_FECHA, la liquidación se rechaza. Si no se puede resolver el empleado SCD2 o el contrato, la liquidación queda en REVIEW y no se fuerza a miembro 0, evitando colisiones en la unicidad `(empleado_key, periodo)`.

## Idempotencia

- `DIM_CONTRATO`: UPSERT por `numero_contrato`.
- `FACT_REMUNERACIONES`: UPSERT por `(empleado_key, periodo)`.
- El loader clasifica cada fila como inserted, updated o unchanged antes de escribir.

## Auditoría

Runner:

```bash
python -m etl.run_dw_contratos_remuneraciones
```

Valores de auditoría:

- `source = CONTRATOS_REMUNERACIONES`
- `process = ETL_DW_CONTRATOS_REMUNERACIONES`

Registra leídos, válidos, rechazados, REVIEW, insertados, actualizados y sin cambios. Los WARNING del control operacional se informan en el mensaje, pero no se confunden con un fallo de homologación del DW.

## Validación esperada

Antes de integrar:

1. ejecutar la validación operacional del dominio;
2. ejecutar `pytest` específico y global;
3. ejecutar el runner E2E dos veces;
4. comprobar idempotencia;
5. revisar las últimas filas de `etl_execution_log`;
6. reconciliar conteos y medidas entre staging y DW.
