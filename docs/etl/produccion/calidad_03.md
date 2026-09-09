# Control de calidad ETL — Producción 0.3

## Objetivo

Documentar el control de calidad aplicado al archivo CSV complementario de Producción, incorporando detección explícita de duplicados, clasificación de hallazgos por severidad, reconciliación con MySQL y métricas reproducibles de profiling.

El archivo fuente no fue modificado.

## Correcciones realizadas durante el cierre

Durante la revisión del PR se detectaron y corrigieron dos problemas:

1. Los resultados `REVIEW` devueltos por la reconciliación MySQL no estaban siendo incorporados al profiling y podían terminar contándose como filas válidas.
2. Una fila podía quedar simultáneamente en los conjuntos de ERROR y WARNING, provocando una doble resta en el cálculo de filas válidas.

El cierre corrige ambos casos:

- `REVIEW` se registra como `WARNING` mediante la regla `RECONCILIACION_REVIEW`.
- ERROR tiene prioridad sobre WARNING.
- Las categorías del resumen son mutuamente excluyentes.
- `valid_rows` se calcula sobre la unión de filas con error o revisión.

## Profiling real

```text
CSV: 6 filas
MySQL: 17 filas
```

Resultado:

```text
procesados = 6
validos = 6
duplicados_exactos = 0
duplicados_clave = 0
errores = 0
warnings = 0
```

## Runner de cierre

Se agregó:

```text
etl/validate/produccion_runner.py
```

El runner registra `run_id`, timestamps, duración, estado, etapa, métricas, hallazgos y controles de error.

## Evidencia de ejecución real

Archivo:

```text
docs/etl/produccion/evidencia_ejecucion.json
```

Resultado:

```text
run_id = d61f4f33-a3cf-4922-aa97-3e6cbe3ab06d
status = OK
stage = null
procesados = 6
validos = 6
review = 0
errores = 0
warnings = 0
duplicados_exactos = 0
duplicados_clave = 0
controles_error = 0
```

Etapas:

```text
lectura_csv   -> OK (6 filas)
lectura_mysql -> OK (17 filas)
validacion    -> OK
```

## Fallo controlado

Se alteró solo en memoria una copia de la primera fila:

```text
cantidad_planificada = 10
cantidad_consumida = 12
```

Resultado:

```text
run_id = ba26fe80-dd09-459c-a287-950bb1b09f9a
status = ERROR
stage = validacion
procesados = 6
validos = 5
errores = 1
warnings = 0
controles_error = 1
```

Hallazgo:

```text
fila = 2
business_key = OP-2026-0001 / 1001 / 2026-08-01
regla = VALIDACION_CSV
severidad = ERROR
detalle = cantidad_consumida mayor que cantidad_planificada
```

## Pruebas

```text
test_produccion_calidad.py -> 9 passed
test_produccion_runner.py  -> 4 passed
Pruebas específicas        -> 13 passed
Suite global               -> 145 passed, 38 skipped
```

## Alcance

No se realizaron cambios en ETL Core, homologación, business keys, otros dominios, Data Warehouse ni archivos fuente originales.
