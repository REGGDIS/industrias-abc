# Cierre ETL — Producción

**Proyecto:** Business Intelligence — Industrias ABC  
**Equipo:** BInnova  
**Dominio:** Producción  
**Responsable del dominio:** Joaquín  
**Base de integración:** `develop`

## Objetivo

Completar y validar el ETL de Producción dejando controles de calidad consistentes, reconciliación contra MySQL, auditoría reproducible y evidencia de una corrida real correcta y de un fallo controlado.

## Brechas detectadas

Durante la revisión del PR #43 se detectó que:

- los estados `REVIEW` del reconciliador no se incorporaban al profiling;
- una fila podía contarse simultáneamente como ERROR y WARNING;
- no existía runner formal ni evidencia JSON de ejecución real.

## Correcciones

Se corrigió el tratamiento de reconciliación para que:

```text
NO_MATCH -> WARNING
REVIEW   -> WARNING
ERROR    -> tiene prioridad sobre WARNING
```

Las categorías del resumen quedaron mutuamente excluyentes y `valid_rows` se calcula sobre la unión de filas con error o revisión.

También se agregó:

```text
etl/validate/produccion_runner.py
etl/tests/test_produccion_runner.py
```

## Ejecución real

Entorno utilizado:

```text
contenedor = industrias-abc-produccion-db
host = 127.0.0.1
puerto = 3310
base = industrias_abc_produccion
CSV = sources/produccion-mysql-csv/csv/consumo_insumos_complementario.csv
```

La configuración utiliza `get_produccion_db_config()` de ETL Core.

## Corrida OK

```text
run_id = d61f4f33-a3cf-4922-aa97-3e6cbe3ab06d
status = OK
stage = null
CSV = 6 filas
MySQL = 17 filas
procesados = 6
validos = 6
review = 0
errores = 0
warnings = 0
duplicados_exactos = 0
duplicados_clave = 0
controles_error = 0
```

Evidencia:

```text
docs/etl/produccion/evidencia_ejecucion.json
```

## Fallo controlado

Se alteró únicamente en memoria:

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
regla = VALIDACION_CSV
severidad = ERROR
detalle = cantidad_consumida mayor que cantidad_planificada
```

Evidencia:

```text
docs/etl/produccion/evidencia_fallo_controlado.json
```

## Pruebas

```text
Calidad Producción = 9 passed
Runner             = 4 passed
Específicas        = 13 passed
Suite global       = 145 passed, 38 skipped
```

## Resultado

El ETL de Producción queda cerrado con profiling reproducible, reconciliación MySQL/CSV, control de duplicados, manejo consistente de ERROR/WARNING/REVIEW, auditoría por runner, evidencia real y fallo controlado.
