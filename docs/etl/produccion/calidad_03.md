# Control de calidad ETL — Producción 0.3

## Objetivo

Documentar el control de calidad aplicado al archivo CSV complementario de Producción, incorporando detección explícita de duplicados, clasificación de hallazgos por severidad y métricas reproducibles de profiling.

El archivo fuente no fue modificado.

## Archivo analizado

```text
sources/produccion-mysql-csv/csv/consumo_insumos_complementario.csv
```

## Reglas aplicadas

| Regla                                                                           | Severidad |
| ------------------------------------------------------------------------------- | --------- |
| Duplicado exacto en CSV                                                         | ERROR     |
| Duplicado por clave `numero_orden + insumo_codigo_o_referencia + fecha_consumo` | ERROR     |
| Campos requeridos inválidos o ausentes                                          | ERROR     |
| Identificadores con formato inválido                                            | ERROR     |
| `cantidad_consumida > cantidad_planificada`                                     | ERROR     |
| Registro sin coincidencia en MySQL                                              | WARNING   |

Las validaciones existentes de Producción 0.2 fueron reutilizadas mediante las funciones existentes de `etl.validate.produccion`.

## Profiling del CSV

| Métrica                         | Resultado |
| ------------------------------- | --------: |
| Filas procesadas                |         6 |
| Filas válidas                   |         6 |
| Duplicados exactos              |         0 |
| Duplicados por clave de negocio |         0 |
| Filas con error                 |         0 |
| Filas con warning               |         0 |
| Hallazgos                       |         0 |

La suma de filas válidas, filas con error y filas con warning reconcilia con el total procesado:

```text
6 + 0 + 0 = 6
```

## Resultado

El CSV analizado no presenta duplicados exactos ni duplicados por clave de negocio.

Tampoco presenta errores de validación ni warnings en el profiling ejecutado.

No se modificó el archivo fuente durante el análisis.

## Trazabilidad

Cuando existen hallazgos, cada registro de calidad contiene:

* número de fila;
* clave de negocio;
* regla aplicada;
* severidad;
* detalle del hallazgo.

En la ejecución realizada sobre el CSV actual no se generaron hallazgos.

## Reproducibilidad

El resultado se obtiene ejecutando el lector existente del CSV junto con `profile_quality()` del módulo:

```text
etl/validate/reconcile_produccion.py
etl/validate/produccion_calidad.py
```

Los tests automatizados asociados al control de calidad se encuentran en:

```text
etl/tests/test_produccion_calidad.py
```

La suite combinada de Producción 0.2 y 0.3 finalizó correctamente:

```text
19 passed
```

## Alcance

Este control corresponde exclusivamente a Producción 0.3.

No se realizaron cambios en:

* `etl/transform/homologation.py`
* `etl/transform/business_keys.py`
* ETL Core
* otros dominios
* `data-warehouse/`
* `DIM_PRODUCTO`
* `FACT_PRODUCCION`
* archivos fuente originales
