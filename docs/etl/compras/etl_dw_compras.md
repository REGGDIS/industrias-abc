# ETL → DW de Compras y Abastecimiento

## Objetivo

Cerrar la integración del dominio Compras con el Data Warehouse físico existente de Industrias ABC, cargando `DIM_PROVEEDOR`, `DIM_INSUMO` y `FACT_COMPRAS` desde la fuente operacional PostgreSQL ya validada.

## Fuentes y grano

La fuente autoritativa es el Sistema Operacional de Compras. El hecho mantiene el grano definido por el DW: **una fila por línea de detalle de una orden de compra**, identificada analíticamente por `numero_oc + insumo_key`.

El staging histórico de Compras no está materializado como tablas CLEAN persistentes: las tareas previas lo implementaron como consultas sobre fixtures. Por eso el loader del DW lee una fotografía consistente de las tablas operacionales y aplica solamente la limpieza segura ya aprobada (`TRIM`/`UPPER`). Antes de cargar, el runner reutiliza los controles transaccionales oficiales de `etl/validate/compras/validaciones_calidad_compras.sql`.

## Reglas de dimensiones

### DIM_PROVEEDOR

- Business key: RUT normalizado.
- Se eliminan puntos, se conserva guion y DV.
- El DV se valida matemáticamente antes de cargar.
- SCD Tipo 1 para atributos descriptivos.
- Un RUT inválido o duplicado después de normalizar se rechaza.
- `codigo_proveedor_ref` queda `NULL` mientras no exista una equivalencia empresarial explícita; no se inventa desde el ID local.

### DIM_INSUMO

- Business key: `codigo_insumo`.
- La categoría se aplana en la dimensión mediante `codigo_categoria` y `nombre_categoria`.
- SCD Tipo 1 para atributos descriptivos.
- Un cambio de `unidad_medida` para la misma business key **no** se aplica automáticamente: se deriva a `REVIEW`, porque cambia el significado histórico de las cantidades.

## Resolución dimensional de FACT_COMPRAS

- `fecha_emision_key`: resuelta por fecha; si no existe, la línea se rechaza.
- `fecha_requerida_key`: usa 0 solo cuando la fecha no viene informada. Si viene informada y no se resuelve, la línea se rechaza.
- `proveedor_key`: por RUT normalizado. Si no se resuelve, usa 0 y genera `REVIEW`.
- `insumo_key`: por `codigo_insumo`. Si no se resuelve, la línea se rechaza para proteger la unicidad `(numero_oc, insumo_key)` y evitar colisiones de varias líneas en el miembro 0.
- `centro_costo_key`: por `codigo_centro` contra `DIM_CENTRO_COSTO`; si no se resuelve, usa 0 y genera `REVIEW`.
- `area_key`: por `codigo_area` asociado al centro de costo; si no se resuelve, usa 0 y genera `REVIEW`.
- `codigo_comprador` se conserva como atributo local descriptivo; no se fuerza homologación con RRHH sin una business key común confirmada.

## Medidas y prorrateo

La fuente guarda `subtotal`, `impuesto` y `total` en la cabecera de la OC, mientras el DW requiere medidas a nivel de línea. El impuesto se prorratea según el diseño físico:

`impuesto_linea = impuesto_oc × subtotal_linea / subtotal_oc`

El cálculo usa `Decimal`, redondeo a centavos y asigna el residuo de redondeo a la última línea de cada OC para que la suma de `impuesto_linea` cuadre exactamente con `impuesto_oc`.

`total_linea = subtotal_linea + impuesto_linea`.

Si el subtotal de cabecera difiere de la suma de líneas, el caso queda en `REVIEW` para no ocultar una discrepancia de origen.

Las cantidades recibidas y rechazadas se agregan primero por `detalle_id` y luego se unen a la línea de compra; así se evita multiplicar la cantidad solicitada cuando una línea tiene varias recepciones.

## Tratamiento de REVIEW operacional

Los controles oficiales de Compras identifican dos líneas del seed como `REVIEW` por recepción parcial. Son casos legítimos y no bloquean la carga del hecho: la línea se carga con sus cantidades recibidas/rechazadas reales y el runner registra el proceso como `PARTIAL` mientras existan revisiones pendientes.

## Idempotencia

Las tres cargas comparan el estado actual del DW antes de ejecutar el `UPSERT`:

- primera corrida: clasifica como `inserted` o `updated`;
- segunda corrida sin cambios: clasifica como `unchanged` y no reescribe la fila;
- el grano de `FACT_COMPRAS` permanece único por `numero_oc + insumo_key`.

## Auditoría

Runner oficial:

```bash
python -m etl.run_dw_compras
```

Registra en `etl_execution_log`:

- `source=COMPRAS`
- `process=ETL_DW_COMPRAS`
- registros leídos, válidos, rechazados y en revisión;
- insertados, actualizados y sin cambios;
- `SUCCESS`, `PARTIAL` o `ERROR`.

## Pruebas

Pruebas unitarias del loader:

```bash
python -m pytest etl/tests/test_dw_compras.py -q
```

Suite global:

```bash
python -m pytest -q
```

## Cierre y evidencia final — 2026-09-14

### Validación de origen

El runner de validación de Compras fue ejecutado satisfactoriamente con cliente PostgreSQL 16.15 y PostgreSQL 16.11 en el contenedor de Compras.

Resultado:

```text
status = OK
normalizacion = 120 procesados / 120 normalizados / 0 review / 0 errores
calidad       = 55 procesados / 53 validos / 2 review / 0 errores
```

Los dos registros en `REVIEW` corresponden a recepciones parciales ya conocidas en `detalle_orden_compra` 6 y 13. No existe ningún error bloqueante de calidad.

### Pruebas automatizadas

```text
etl/tests/test_dw_compras.py: 10 passed
suite global:               230 passed, 36 skipped
```

No se detectaron regresiones en la suite global.

### Ejecución E2E e idempotencia

Se ejecutó dos veces `python -m etl.run_dw_compras`.

Primera ejecución (`execution_id=19`):

```text
status             = PARTIAL
records_read       = 111
records_valid      = 109
records_rejected   = 0
records_review     = 2
records_inserted   = 49
records_updated    = 0
records_unchanged  = 0

DIM_PROVEEDOR      = 15 inserted
DIM_INSUMO         = 15 inserted
FACT_COMPRAS       = 19 inserted
```

Segunda ejecución (`execution_id=20`):

```text
status             = PARTIAL
records_read       = 111
records_valid      = 109
records_rejected   = 0
records_review     = 2
records_inserted   = 0
records_updated    = 0
records_unchanged  = 49

DIM_PROVEEDOR      = 15 unchanged
DIM_INSUMO         = 15 unchanged
FACT_COMPRAS       = 19 unchanged
```

Esto demuestra idempotencia: una segunda corrida sin cambios no genera duplicados ni reescrituras innecesarias.

El estado `PARTIAL` no representa una falla del ETL→DW. Se debe exclusivamente a los dos `SOURCE_REVIEW` de recepción parcial; la propia carga al DW terminó con `DW_REVIEW=0` y `REJECTED=0`.

### Reconciliación del Data Warehouse

Conteos físicos:

```text
DIM_PROVEEDOR reales = 15
DIM_INSUMO reales    = 15
FACT_COMPRAS         = 19
```

Claves desconocidas en `FACT_COMPRAS`:

```text
proveedor_key = 0      -> 0 filas
insumo_key = 0         -> 0 filas
centro_costo_key = 0   -> 0 filas
area_key = 0           -> 0 filas
```

La homologación dimensional quedó completamente resuelta para el dataset actual.

### Reconciliación monetaria por moneda

Los importes se mantienen separados por moneda de origen; no se mezclan monedas sin conversión explícita.

| Moneda | Líneas | Subtotal | Impuesto | Total | Recibido | Rechazado |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| CLP | 16 | 16.764.000,00 | 3.185.160,00 | 19.949.160,00 | 9.120,00 | 20,00 |
| EUR | 2 | 1.650,00 | 313,50 | 1.963,50 | 0,00 | 0,00 |
| USD | 1 | 1.260,00 | 239,40 | 1.499,40 | 300,00 | 0,00 |

En cada moneda se conserva la igualdad `subtotal + impuesto = total`.

### Auditoría persistida

`public.etl_execution_log` registró correctamente:

```text
execution_id 19 | COMPRAS | ETL_DW_COMPRAS | PARTIAL | inserted=49 | unchanged=0  | rejected=0 | review=2
execution_id 20 | COMPRAS | ETL_DW_COMPRAS | PARTIAL | inserted=0  | unchanged=49 | rejected=0 | review=2
```

Mensajes de auditoría:

```text
ETL Compras -> DW ejecutado. SOURCE_REVIEW=2 DW_REVIEW=0 REJECTED=0.
```

## Estado final

El **ETL→DW de Compras queda técnicamente cerrado y apto para integración a `develop`**. Se comprobó:

- validación fuente sin errores bloqueantes;
- carga de `DIM_PROVEEDOR`, `DIM_INSUMO` y `FACT_COMPRAS`;
- homologación completa de claves empresariales del dataset actual;
- prorrateo monetario consistente;
- recepción agregada sin multiplicación de líneas;
- idempotencia en segunda ejecución;
- auditoría persistida;
- suite específica y global en verde.

Los dos casos de recepción parcial permanecen como `REVIEW` operacional conocido y no requieren corrección del ETL.
