# Cierre ETL — RRHH

**Proyecto:** Business Intelligence — Industrias ABC  
**Equipo:** BInnova  
**Dominio:** Recursos Humanos (RRHH)  
**Base de integración:** `develop`  
**Rama de cierre:** `fix/etl-rrhh-cierre`

## Objetivo

Formalizar el cierre del ETL de RRHH con el mismo estándar aplicado al resto de los dominios del proyecto, sin rehacer la lógica existente ni modificar ETL Core o Data Warehouse.

El cierre incorpora:

- runner auditable de cierre;
- verificación de conteos entre extracción, RAW y CLEAN;
- evidencia JSON de ejecución real;
- evidencia JSON de fallo controlado;
- pruebas automatizadas específicas;
- validación de la suite global del proyecto.

## ETL existente reutilizado

El cierre reutiliza el flujo ya existente de RRHH:

```text
etl/run_rrhh.py
```

Este flujo ejecuta:

1. extracción de empleados;
2. extracción de áreas;
3. extracción de cargos;
4. extracción de centros de costo;
5. transformación de empleados;
6. validación de empleados;
7. carga RAW;
8. creación de tablas CLEAN;
9. auditoría de ejecución.

No se reemplaza ni duplica esta lógica.

## Runner formal de cierre

Se agregó:

```text
etl/validate/rrhh_runner.py
```

Su objetivo es envolver la ejecución existente y agregar controles de cierre reproducibles.

El runner registra:

```text
run_id
proceso
started_at
finished_at
duration_seconds
duracion_ms
status
stage
error
procesados
validos
errores
warnings
controles_error
execution_id_origen
entidades
etapas
```

Además, evita persistir el texto completo de excepciones técnicas en la evidencia de cierre, reduciendo el riesgo de exponer información sensible.

## Entidades verificadas

El cierre verifica las cuatro entidades principales de RRHH:

```text
empleados
areas
cargos
centros_costo
```

Para cada una se comparan:

```text
extraidos
RAW
CLEAN
```

## Línea base real

Antes del cierre se ejecutó el ETL RRHH existente con resultado satisfactorio:

```text
execution_id = 7
records_read = 80
records_valid = 80
records_rejected = 0
areas = 7
cargos = 12
centros_costo = 7
status = SUCCESS
```

## Ejecución formal real

Evidencia:

```text
docs/etl/rrhh/evidencia_ejecucion.json
```

Resultado:

```text
run_id = 9c5885e1-0531-40db-b073-591317bed947
status = OK
stage = null
procesados = 80
validos = 80
errores = 0
warnings = 0
controles_error = 0
execution_id_origen = 8
```

### Reconciliación por entidad

| Entidad          | Extraídos | RAW | CLEAN | RAW OK | CLEAN OK |
| ---------------- | --------: | --: | ----: | ------ | -------- |
| empleados        |        80 |  80 |    80 | Sí     | Sí       |
| áreas            |         7 |   7 |     7 | Sí     | Sí       |
| cargos           |        12 |  12 |    12 | Sí     | Sí       |
| centros de costo |         7 |   7 |     7 | Sí     | Sí       |

Etapas:

```text
etl_rrhh             -> OK
verificacion_staging -> OK
```

## Fallo controlado

Evidencia:

```text
docs/etl/rrhh/evidencia_fallo_controlado.json
```

El fallo controlado se realizó sin modificar PostgreSQL ni los datos reales.

Se simuló exclusivamente en memoria un descuadre en el conteo CLEAN de áreas:

```text
extraidos = 7
raw = 7
clean = 6
```

Resultado:

```text
run_id = d32c4619-09fe-482f-b1fc-6852befa4e6d
status = ERROR
stage = verificacion_staging
procesados = 80
validos = 80
errores = 0
controles_error = 1
```

Detalle de la entidad:

```text
areas = {
    extraidos: 7,
    raw: 7,
    clean: 6,
    raw_ok: true,
    clean_ok: false
}
```

Esto demuestra que el runner detecta correctamente una pérdida o discrepancia entre extracción, RAW y CLEAN.

## Pruebas automatizadas

Archivo:

```text
etl/tests/test_rrhh_runner.py
```

Casos cubiertos:

- ejecución exitosa;
- detección de descuadre RAW;
- detección de descuadre CLEAN;
- saneamiento de errores técnicos;
- generación de `run_id` único.

Resultado:

```text
5 passed
```

Suite global:

```text
150 passed, 38 skipped
```

## Alcance

Este cierre no modifica:

- ETL Core;
- homologación transversal;
- business keys;
- Data Warehouse;
- dimensiones;
- tablas de hechos;
- fuentes operacionales;
- credenciales.

## Resultado final

Con este cierre, RRHH queda formalmente alineado con el estándar aplicado a los demás dominios ETL del proyecto:

- ejecución real validada;
- conteos de extracción, RAW y CLEAN reconciliados;
- auditoría reproducible;
- manejo de fallos;
- evidencia versionable;
- pruebas automatizadas;
- suite global sin regresiones.

El ETL de RRHH queda cerrado y preparado para continuar con la integración/carga hacia el Data Warehouse.
