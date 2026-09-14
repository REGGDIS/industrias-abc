# ETL Asistencia → Data Warehouse

## 1. Objetivo

Implementar la carga del dominio Asistencia hacia el Data Warehouse de Industrias ABC reutilizando el ETL operacional ya cerrado y validado, sin duplicar sus reglas de extracción, staging ni calidad.

El destino principal es `dw.fact_asistencia`, con reutilización y carga idempotente de `dw.dim_turno`.

## 2. Fuentes y contrato de entrada

El flujo reutiliza directamente el componente vigente:

```text
etl.validate.asistencia.runner.obtener_datos()
etl.validate.asistencia.runner.validar_datos()
```

De esta forma, la carga DW consume las salidas CLEAN y las reglas de calidad ya aprobadas para Asistencia, evitando mantener una segunda implementación paralela.

La fuente operacional continúa siendo MySQL, pero la capa DW no reconstruye reglas nuevas sobre las tablas operacionales: reutiliza el runner ETL de Asistencia, que prepara RAW temporal, ejecuta los SQL CLEAN versionados y valida el dominio.

## 3. Destinos físicos

Se utilizan los contratos físicos ya integrados en `develop`:

- `dw.dim_fecha`
- `dw.dim_empleado`
- `dw.dim_area`
- `dw.dim_cargo`
- `dw.dim_centro_costo`
- `dw.dim_turno`
- `dw.fact_asistencia`

No se recrean dimensiones RRHH ni una FACT alternativa.

## 4. Grano de FACT_ASISTENCIA

El grano es:

```text
1 empleado empresarial + 1 fecha
```

La restricción física vigente es:

```sql
UNIQUE (empleado_key, fecha_key)
```

La carga usa `ON CONFLICT (empleado_key, fecha_key) DO UPDATE` y, además, clasifica cada fila como `inserted`, `updated` o `unchanged` antes de escribirla.

## 5. Resolución de empleado

La homologación usa exclusivamente:

```text
RUT normalizado + fecha_asistencia
```

La normalización reutiliza:

```text
etl.transform.rut.normalize_rut
```

La validación matemática del DV reutiliza la misma regla utilizada en la carga RRHH compartida.

La versión histórica se resuelve con semántica SCD2 semiabierta:

```text
fecha_desde <= fecha_asistencia
AND (fecha_hasta IS NULL OR fecha_asistencia < fecha_hasta)
```

Una vez resuelta la versión de `DIM_EMPLEADO`, `area_key`, `cargo_key` y `centro_costo_key` se toman de esa misma versión histórica.

No se homologa por nombre ni por IDs locales.

## 6. Casos REVIEW y ERROR

Los casos no determinísticos se mantienen fuera de la FACT y quedan trazados como `REVIEW`, evitando colisiones artificiales con el miembro desconocido `0` en un hecho cuyo grano es empleado + fecha.

Se clasifican como `REVIEW`:

- RUT con DV inválido;
- empleado sin versión histórica resoluble;
- turno no resoluble contra `DIM_TURNO`.

Se clasifican como `ERROR` / rechazo:

- trabajador inexistente en el conjunto validado;
- fecha sin correspondencia en `DIM_FECHA`;
- duplicado RUT + fecha dentro del lote;
- más de una versión SCD2 aplicable para el mismo RUT y fecha;
- errores de calidad ya detectados por el ETL Asistencia cerrado.

## 7. DIM_TURNO

Los turnos CLEAN de Asistencia se cargan en `dw.dim_turno` mediante SCD Tipo 1 e idempotencia por `turno_bk`.

La business key se construye de forma determinística:

```text
NOMBRE_TURNO|HORA_INICIO|HORA_FIN
```

Las horas provenientes de MySQL se normalizan explícitamente a `TIME` antes de construir la BK o enviarlas a PostgreSQL.

El `turno_id` operacional se conserva únicamente para resolver el registro de origen dentro del dominio Asistencia; no se utiliza como FK transversal.

## 8. Medidas de FACT_ASISTENCIA

Se cargan las medidas ya validadas por el ETL de Asistencia:

- `hora_entrada`
- `hora_salida`
- `estado_asistencia`
- `horas_trabajadas`
- `horas_normales`
- `horas_extras`
- `minutos_atraso`
- `dias_trabajados`
- `dias_ausentes`
- `cantidad_registros`

Reglas de días:

- `PRESENTE` / `ATRASO` → `dias_trabajados = 1`, `dias_ausentes = 0`
- `AUSENTE` → `dias_trabajados = 0`, `dias_ausentes = 1`

No se inventan fórmulas laborales adicionales en la carga DW.

## 9. Auditoría transversal

El runner oficial es:

```powershell
python -m etl.run_dw_asistencia
```

Registra la ejecución mediante la infraestructura transversal `etl_execution_log` con:

```text
source  = ASISTENCIA
process = ETL_DW_ASISTENCIA
```

Métricas registradas:

- `records_read`
- `records_valid`
- `records_inserted`
- `records_updated`
- `records_unchanged`
- `records_rejected`
- `records_review`

Estados:

- `SUCCESS`: sin rechazados ni REVIEW;
- `PARTIAL`: existen rechazados o REVIEW;
- `ERROR`: falla técnica de ejecución.

No se crea una auditoría paralela dentro del esquema `dw`.

## 10. Idempotencia

La idempotencia se controla en dos niveles:

1. `DIM_TURNO`: business key `turno_bk`.
2. `FACT_ASISTENCIA`: grano `(empleado_key, fecha_key)`.

Una segunda ejecución del mismo lote debe producir `0 inserted` y `0 updated` si no hubo cambios, contabilizando las filas como `unchanged`.

## 11. Pruebas

Las pruebas específicas están en:

```text
etl/tests/asistencia/test_dw_asistencia.py
```

Cubren al menos:

- normalización y validación de RUT;
- resolución SCD2;
- frontera exclusiva de `fecha_hasta`;
- coherencia del contexto organizacional;
- RUT inválido → REVIEW;
- empleado no resoluble → REVIEW;
- turno no resoluble → REVIEW;
- fecha no resoluble → ERROR;
- SCD2 ambiguo → ERROR;
- duplicado RUT + fecha;
- construcción de la fila de FACT;
- presencia de UPSERT por grano.

Los tests de resolución no dependen de claves subrogadas reales de una instalación local del DW.

## 12. Correcciones realizadas durante la revisión del PR #62

La revisión del coordinador detectó y corrigió los siguientes puntos antes del merge:

- el loader consultaba tablas `stg_asistencia_*_clean` dentro de la base DW, aunque esas salidas no forman parte del contrato reproducible del DW;
- se duplicaban reglas de calidad ya existentes en `etl.validate.asistencia.validator`;
- había funciones de test copiadas accidentalmente al final del módulo productivo `dw_asistencia.py`;
- los tests dependían de claves subrogadas y datos locales concretos;
- `cargar_dim_turno.sql` existía, pero no formaba parte efectiva del flujo reproducible;
- faltaba integración con la auditoría transversal `etl_execution_log`;
- las horas MySQL requerían normalización explícita antes de insertarlas en PostgreSQL.

La implementación corregida reutiliza el ETL fuente vigente, carga `DIM_TURNO`, resuelve las dimensiones conformadas y ejecuta `FACT_ASISTENCIA` bajo un único runner auditable.

## 13. Validación pendiente antes del merge

Después de las correcciones del coordinador se deben reejecutar localmente:

```powershell
python -m pytest etl/tests/asistencia/test_dw_asistencia.py -q
python -m pytest -q
python -m etl.run_dw_asistencia
```

Luego se debe comprobar la última fila de `etl_execution_log` para `source = 'ASISTENCIA'` y verificar la idempotencia mediante una segunda ejecución del runner.

La evidencia anterior del PR (`30 procesados / 0 cargados`) ya no se considera evidencia de cierre, porque provenía de un staging local no reproducible y de una versión previa del loader.

## 14. Criterio de cierre

Asistencia queda lista para merge cuando:

- la suite específica esté en verde;
- la suite global no introduzca regresiones;
- el runner real complete sin fallo técnico;
- los REVIEW/rechazos, si existen, estén explicados;
- una segunda ejecución confirme idempotencia;
- la auditoría transversal quede registrada correctamente.
