# Cierre ETL de Compras

**Proyecto:** Business Intelligence — Industrias ABC (Equipo BInnova)
**Dominio:** Compras · **Responsable:** Raymond Civil
**Rama:** `feat/etl-compras-auditoria-05` · **Base:** `develop` · **Versión:** 0.1

## GAP ANALYSIS previo a la implementación

Compras ya contaba con extracción y staging (0.1), carga incremental (0.2),
calidad transaccional (0.3) y normalización/estandarización (0.4), todo probado
en PostgreSQL.

Para completar el cierre 0.5 faltaba una funcionalidad ejecutable que dejara
evidencia técnica de cada corrida del ETL: identificador único, tiempos,
estado final, métricas reales, etapas ejecutadas y detalle de error.

Se adopta la misma convención de cierre utilizada en Contabilidad y Asistencia:
un runner en `etl/validate/<dominio>/runner.py`, invocable con
`--output <json>`, acompañado de evidencia versionada:

- `docs/etl/compras/evidencia_ejecucion.json`
- `docs/etl/compras/evidencia_fallo_controlado.json`

## Implementación y reutilización

`etl/validate/compras/runner.py` orquesta las etapas del cierre reutilizando
los scripts existentes y sin duplicar reglas de negocio:

| Etapa                   | Script reutilizado                                             | Aporta                                            |
| ----------------------- | -------------------------------------------------------------- | ------------------------------------------------- |
| `normalizacion`         | `sql/staging/compras/ejecutar_normalizacion_compras.sql` (0.4) | preparación RAW interna, normalización y métricas |
| `validaciones_calidad`  | `validate/compras/validaciones_calidad_compras.sql` (0.3)      | controles transaccionales y métricas de calidad   |
| `pruebas_normalizacion` | `tests/compras/test_normalizacion_compras.sql` (0.4)           | pruebas de normalización                          |

La preparación RAW no se ejecuta como etapa independiente, ya que
`ejecutar_normalizacion_compras.sql` incluye internamente
`preparar_raw_compras.sql`. Esto evita una ejecución redundante y respeta el uso
de tablas temporales dentro de la misma sesión de `psql`.

Cada etapa se ejecuta con `psql -v ON_ERROR_STOP=1`. Un error técnico de `psql`
o SQL produce `status="ERROR"` y registra la etapa en que ocurrió.

Las métricas de normalización 0.4 y calidad 0.3 se registran por separado:

- **Normalización 0.4:** campos procesados, normalizados, en revisión y con error.
- **Calidad 0.3:** registros transaccionales procesados, válidos, en revisión y con error.

Las métricas generales del reporte corresponden a la **calidad transaccional
0.3**, no a la cantidad de campos evaluados por la normalización.

Un registro marcado como `REVISION` no bloquea el cierre. Si la etapa de calidad
detecta al menos un registro con severidad `ERROR`, el runner termina con:

```text
status = "ERROR"
stage = "validaciones_calidad"
controles_error = 1
```

### Seguridad

La contraseña se pasa mediante `PGPASSWORD`, sin incluirla en la línea de
comandos. Los errores inesperados se sanean para evitar registrar credenciales.

### Solo lectura

Los scripts reutilizados trabajan con consultas y tablas temporales. El runner
escribe únicamente el JSON de auditoría y no modifica tablas operacionales,
ETL Core ni Data Warehouse.

> Nota de implementación: a diferencia de Contabilidad y Asistencia, Compras
> ejecuta sus SQL mediante `psql` porque los scripts 0.3/0.4 contienen
> meta-comandos como `\ir` y `\echo`. Esto permite reutilizar las reglas
> existentes sin reimplementarlas.

## Contrato de salida

Cada corrida genera un objeto JSON con la siguiente información:

```text
run_id
proceso = "compras_etl"
status = "OK|ERROR"
stage
error

procesados
validos
review
errores
controles_error

normalizacion = {
    procesados,
    normalizados,
    review,
    errores
}

calidad = {
    procesados,
    validos,
    review,
    errores
}

etapas = [
    {
        nombre,
        resultado,
        duracion_ms
    }
]

started_at
finished_at
duration_seconds
duracion_ms
```

`duracion_ms` se conserva explícitamente como métrica de auditoría de ejecución.

## Reproducción

### Corrida real

```bash
python -m etl.validate.compras.runner \
  --output docs/etl/compras/evidencia_ejecucion.json
```

Requiere:

- `COMPRAS_DB_HOST`
- `COMPRAS_DB_PORT`
- `COMPRAS_DB_NAME`
- `COMPRAS_DB_USER`
- `COMPRAS_DB_PASSWORD`
- cliente `psql`

La configuración de conexión se obtiene desde `etl/config/settings.py`; no se
incluyen credenciales en el código.

### Pruebas

```bash
pytest etl/tests/compras/test_compras_runner.py -v
```

Los tests que requieren PostgreSQL y el cliente local `psql` se omiten cuando
esas dependencias no están disponibles.

## Verificación realizada

La validación final se ejecutó sobre PostgreSQL 16 utilizando el contenedor:

```text
industrias-abc-compras-db
base de datos: compras_abc
puerto host: 5436
```

### Corrida OK

Archivo:

```text
docs/etl/compras/evidencia_ejecucion.json
```

Resultado real:

```text
run_id = d5895ac7-8567-4a82-8032-19f5a9e0637e
status = OK
stage = null
error = null
controles_error = 0
```

#### Normalización 0.4

La normalización evalúa campos individuales.

```text
procesados   = 120
normalizados = 120
review       = 0
errores      = 0
```

Resumen real:

```text
TOTAL | 120 | 120 | 0 | 0
```

#### Calidad transaccional 0.3

La validación de calidad evalúa registros de:

- `ordenes_compra`
- `detalle_orden_compra`
- `recepciones`
- `detalle_recepcion`

Resultado real:

```text
procesados = 55
validos    = 53
review     = 2
errores    = 0
```

Resumen real:

```text
TOTAL | 55 | 53 | 2 | 0
```

Las dos incidencias de revisión corresponden a diferencias entre cantidades
solicitadas y recibidas:

```text
detalle_orden_compra 6  -> FALTANTE
detalle_orden_compra 13 -> FALTANTE
```

Ambas poseen severidad `REVISION`, por lo que no bloquean el cierre.

Las tres etapas terminaron correctamente:

```text
normalizacion          -> OK
validaciones_calidad   -> OK
pruebas_normalizacion  -> OK
```

La evidencia real quedó registrada con:

```json
{
  "run_id": "d5895ac7-8567-4a82-8032-19f5a9e0637e",
  "proceso": "compras_etl",
  "status": "OK",
  "stage": null,
  "error": null,
  "procesados": 55,
  "validos": 53,
  "review": 2,
  "errores": 0,
  "controles_error": 0,
  "normalizacion": {
    "procesados": 120,
    "normalizados": 120,
    "review": 0,
    "errores": 0
  },
  "calidad": {
    "procesados": 55,
    "validos": 53,
    "review": 2,
    "errores": 0
  }
}
```

## Evidencia de fallo controlado de calidad

Archivo:

```text
docs/etl/compras/evidencia_fallo_controlado.json
```

Para demostrar que un error de calidad real bloquea el cierre se ejecutó una
prueba sobre copias temporales de las tablas operacionales.

Se modificó únicamente una copia temporal de `detalle_orden_compra`, estableciendo:

```text
cantidad = 0
```

Esto activó reglas reales ya existentes en
`validaciones_calidad_compras.sql`, entre ellas:

```text
CANTIDAD_POSITIVA        -> ERROR
SUBTOTAL_LINEA_COHERENTE -> ERROR
```

La modificación produjo además una incidencia `REVISION` adicional en la regla
`SOLICITADO_VS_RECIBIDO`.

Las tablas operacionales originales no fueron modificadas.

Resultado real:

```text
run_id = 14e77245-9177-42ce-b13d-c6e05542332e
status = ERROR
stage = validaciones_calidad

procesados = 55
validos    = 52
review     = 3
errores    = 1

controles_error = 1
```

Resumen:

```text
TOTAL | 55 | 52 | 3 | 1
```

Aunque un mismo registro incumplió más de una regla `ERROR`, la métrica
`con_error` cuenta registros distintos. Por ello el resultado corresponde a un
registro con error.

El runner registró correctamente:

```text
Se detectaron registros con errores en los controles de calidad de Compras.
```

La etapa posterior `pruebas_normalizacion` no se ejecuta después de detectarse
el error de calidad.

La evidencia quedó registrada como:

```json
{
  "run_id": "14e77245-9177-42ce-b13d-c6e05542332e",
  "proceso": "compras_etl",
  "status": "ERROR",
  "stage": "validaciones_calidad",
  "error": "Se detectaron registros con errores en los controles de calidad de Compras.",
  "procesados": 55,
  "validos": 52,
  "review": 3,
  "errores": 1,
  "controles_error": 1,
  "normalizacion": {
    "procesados": 120,
    "normalizados": 120,
    "review": 0,
    "errores": 0
  },
  "calidad": {
    "procesados": 55,
    "validos": 52,
    "review": 3,
    "errores": 1
  }
}
```

## Pruebas automatizadas

Archivo:

```text
etl/tests/compras/test_compras_runner.py
```

Incluye pruebas de:

- saneo de credenciales ante fallos;
- generación de `run_id` único;
- corrida de integración OK;
- falla técnica controlada;
- `REVISION` de calidad no bloqueante;
- `ERROR` de calidad bloqueante.

En un entorno Windows sin cliente local `psql`, el módulo de Compras obtuvo:

```text
4 passed, 2 skipped
```

Los dos tests omitidos corresponden únicamente a pruebas de integración que
requieren la BD y el cliente `psql`.

Después de las correcciones, la suite completa del repositorio obtuvo:

```text
94 passed, 38 skipped
```

sin errores de colección ni fallos funcionales.

## Trazabilidad

| Requisito                         | Evidencia                                                      | Estado |
| --------------------------------- | -------------------------------------------------------------- | ------ |
| `run_id` único                    | identificador UUID distinto por corrida                        | ✅     |
| inicio, término y duración        | `started_at`, `finished_at`, `duration_seconds`, `duracion_ms` | ✅     |
| estado OK/ERROR                   | corrida normal y fallo controlado                              | ✅     |
| métricas de normalización         | 120 / 120 / 0 / 0                                              | ✅     |
| métricas de calidad               | 55 / 53 / 2 / 0                                                | ✅     |
| `REVISION` no bloqueante          | corrida real termina OK con 2 revisiones                       | ✅     |
| `ERROR` bloqueante                | fallo controlado termina ERROR con 1 registro con error        | ✅     |
| etapas y resultado                | lista `etapas[]`                                               | ✅     |
| error saneado                     | evidencia sin credenciales                                     | ✅     |
| salida JSON                       | archivos `evidencia_*.json` válidos                            | ✅     |
| no modifica operacionales/Core/DW | validación temporal y salida JSON                              | ✅     |
| pruebas automatizadas             | 94 passed / 38 skipped en suite global                         | ✅     |

## Límites del cierre

- El parseo depende de la fila `TOTAL` entregada por los scripts de
  normalización 0.4 y calidad 0.3. Si cambia el contrato de salida de esos
  scripts, deberá ajustarse el parser.
- Compras utiliza `psql` porque los SQL reutilizados contienen meta-comandos
  como `\ir` y `\echo`.
- Los tests de integración requieren PostgreSQL y el cliente `psql`; los tests
  de lógica y auditoría pueden ejecutarse sin ellos.
- Este cierre no construye hechos ni dimensiones del Data Warehouse.

Con la integración de este PR, el **ETL de Compras queda cerrado**. El trabajo
posterior del dominio corresponde a la integración con Data Warehouse, salvo
correcciones necesarias del ETL existente.
