# ETL Asistencia → Data Warehouse

## 1. Objetivo

Implementar la carga ETL de los datos de asistencia validados desde las
tablas de staging hacia `dw.fact_asistencia`, manteniendo el grano de un
trabajador por día, resolviendo las dimensiones mediante las claves del
Data Warehouse y evitando duplicados mediante una carga idempotente.

El proceso utiliza PostgreSQL 16 y se mantiene dentro del alcance del
dominio de Asistencia.

## 2. Fuentes

La carga utiliza las siguientes tablas de staging:

-   `stg_asistencia_asistencia_clean`: registros diarios de asistencia.
-   `stg_asistencia_trabajador_clean`: información del trabajador y RUT.
-   `stg_asistencia_turnos_clean`: información de los turnos.

Las dimensiones utilizadas en el DW son:

-   `dw.dim_fecha`
-   `dw.dim_empleado`
-   `dw.dim_area`
-   `dw.dim_cargo`
-   `dw.dim_centro_costo`
-   `dw.dim_turno`

El proceso no utiliza el `trabajador_id` operacional como clave del DW.

## 3. Grano

El grano de `dw.fact_asistencia` es:

> Un empleado por día.

La unicidad se controla mediante:

``` sql
UNIQUE (empleado_key, fecha_key)
```

Por lo tanto, un mismo empleado no puede tener más de un registro para
una misma fecha en la FACT.

## 4. Resolución del empleado

El empleado se resuelve mediante:

1.  Normalización del RUT.
2.  Validación del dígito verificador chileno.
3.  Búsqueda en `dw.dim_empleado` mediante `rut_normalizado`.
4.  Aplicación de la vigencia histórica SCD2 según la fecha de
    asistencia.

La condición temporal utilizada es:

``` sql
fecha_desde <= fecha_asistencia
AND (fecha_hasta IS NULL OR fecha_asistencia < fecha_hasta)
```

`fecha_desde` es inclusiva y `fecha_hasta` es exclusiva. Esto permite
seleccionar correctamente la versión histórica correspondiente al día
del hecho.

No se realiza homologación por nombre o apellido cuando el RUT no
encuentra correspondencia.

## 5. Resolución de dimensiones organizacionales

Una vez resuelta la versión histórica del empleado, se utilizan las
claves dimensionales asociadas a esa misma versión:

-   `area_key`
-   `cargo_key`
-   `centro_costo_key`

No se utilizan los identificadores operacionales de Asistencia como
claves dimensionales.

Esto permite mantener la consistencia histórica entre el empleado y su
contexto organizacional para la fecha del hecho.

## 6. Resolución del turno

El `turno_id` de Asistencia se utiliza únicamente para localizar el
registro correspondiente en `stg_asistencia_turnos_clean`.

A partir de nombre, hora de inicio y hora de término se construye el
`turno_bk`:

``` text
NOMBRE_TURNO|HORA_INICIO|HORA_FIN
```

Luego se obtiene el `turno_key` desde `dw.dim_turno`.

La reconciliación realizada confirmó que los 3 turnos de staging
encuentran correspondencia en la dimensión:

-   TURNO MAÑANA → `turno_key = 2`
-   TURNO TARDE → `turno_key = 1`
-   TURNO ADMINISTRATIVO → `turno_key = 3`

El `turno_key = 0` corresponde al miembro desconocido de la dimensión.

## 7. Mapeo de medidas y estado

La carga conserva las medidas disponibles en staging y no inventa
fórmulas laborales adicionales.

Se cargan:

-   `hora_entrada`
-   `hora_salida`
-   `horas_trabajadas`
-   `horas_normales`
-   `horas_extras`
-   `minutos_atraso`
-   `estado_asistencia`

Además, el estado determina las medidas de días:

-   `PRESENTE` → `dias_trabajados = 1`, `dias_ausentes = 0`
-   `ATRASO` → `dias_trabajados = 1`, `dias_ausentes = 0`
-   `AUSENTE` → `dias_trabajados = 0`, `dias_ausentes = 1`

`cantidad_registros` se mantiene en 1 para cada fila del grano
empleado-día.

## 8. Validaciones antes de cargar

El loader incorpora una validación de defensa para evitar cargar
registros inconsistentes.

Entre las reglas aplicadas están:

-   estado dentro de `PRESENTE`, `ATRASO` o `AUSENTE`;
-   horas trabajadas, normales y extras no negativas;
-   horas extras menores o iguales a horas trabajadas;
-   minutos de atraso no negativos;
-   horas normales + horas extras = horas trabajadas;
-   `AUSENTE` sin entrada ni salida y con horas y atraso en cero;
-   `PRESENTE` sin atraso positivo;
-   `ATRASO` con minutos de atraso positivos;
-   RUT válido;
-   empleado resoluble mediante RUT y fecha;
-   turno resoluble;
-   ausencia de duplicados RUT + fecha.

## 9. Idempotencia

La carga se implementa mediante `ON CONFLICT` sobre el grano de la FACT:

``` sql
ON CONFLICT (empleado_key, fecha_key)
DO UPDATE SET ...
```

Esto permite ejecutar nuevamente la misma carga sin generar registros
duplicados.

### Evidencia funcional

Se insertó el mismo registro fixture dos veces para el empleado
histórico `empleado_key = 1` y `fecha_key = 20260824`.

Resultado:

``` text
INSERT 0 1
INSERT 0 1

empleado_key | fecha_key | cantidad
-------------+-----------+---------
1            | 20260824  | 1
```

La segunda ejecución actualizó el registro existente en lugar de crear
un segundo registro.

Posteriormente se eliminó el registro de prueba y la FACT volvió a:

``` text
total_fact_asistencia
0
```

## 10. Resultado de ejecución real

La ejecución del loader sobre el staging actual produjo:

``` text
procesados=30
resueltos=0
cargados=0
errores=30
```

Los errores se distribuyeron de la siguiente forma:

-   13 registros con `RUT_INVALIDO`.
-   8 registros con `EMPLEADO_NO_RESUELTO`.
-   9 registros con `PRESENTE_CON_ATRASO`.

No se cargaron registros inválidos ni se realizaron correcciones
artificiales sobre los datos fuente.

## 11. Evidencia de incompatibilidad entre Asistencia y RRHH

La reconciliación mediante RUT normalizado + fecha histórica produjo:

``` text
empleados_resueltos
0
```

Esto demuestra que ninguno de los 30 registros actuales de Asistencia
encuentra una versión correspondiente en `dw.dim_empleado`.

Los RUT de Asistencia no coinciden con los RUT presentes en la dimensión
RRHH utilizada por el DW.

Ante esta situación, el proceso no realiza homologación por nombre ni
modifica la dimensión compartida. La carga real queda pendiente de la
integración de los datos maestros correspondientes.

## 12. Evidencia de turnos

La reconciliación de turnos produjo 3 correspondencias de 3:

    turno_id Turno                    turno_key
  ---------- ---------------------- -----------
           1 TURNO MAÑANA                     2
           2 TURNO TARDE                      1
           3 TURNO ADMINISTRATIVO             3

Por lo tanto, la dimensión de turnos no constituye el bloqueo actual de
la carga.

## 13. Evidencia de calidad del staging

El staging contiene:

  Estado        Cantidad
  ----------- ----------
  PRESENTE            27
  AUSENTE              3
  **Total**       **30**

Validaciones SQL realizadas:

  Regla                                Casos inválidos
  ---------------------------------- -----------------
  Horas negativas                                    0
  Horas extras \> horas trabajadas                   0
  Atrasos negativos                                  0

El problema de calidad detectado adicionalmente corresponde a 9
registros `PRESENTE` con minutos de atraso positivos, los cuales fueron
rechazados por el loader.

## 14. Reconciliaciones del Data Warehouse

Se verificó:

-   Staging asistencia: **30 registros**.
-   Staging trabajadores: **10 registros**.
-   `dw.dim_empleado`: **169 registros**, incluyendo el miembro
    desconocido.
-   `dw.dim_turno`: **4 registros**, incluyendo el miembro desconocido.
-   `dw.fact_asistencia`: **0 registros** después de la ejecución real.
-   Empleados resueltos mediante RUT + fecha: **0**.
-   Turnos resueltos: **3 de 3**.
-   Duplicados en `(empleado_key, fecha_key)`: **0**.

La FACT quedó vacía después de la ejecución real porque todos los
registros fueron rechazados por las reglas de calidad o resolución
dimensional.

## 15. Pruebas automatizadas

Se implementaron pruebas para:

1.  normalización de RUT;
2.  validación de RUT;
3.  rechazo de RUT inválido;
4.  validación del fixture;
5.  construcción de una fila de FACT;
6.  control del grano empleado-día;
7.  resolución SCD2 y turno;
8.  rechazo de RUT inválido;
9.  empleado no resuelto;
10. turno no resuelto;
11. rechazo de AUSENTE con horas;
12. rechazo de ATRASO sin minutos;
13. rechazo de horas que no cuadran;
14. rechazo de duplicado RUT + fecha;
15. límite exclusivo de `fecha_hasta`.

Resultado:

``` text
15 passed
```

Además, la idempotencia del SQL fue verificada mediante:

``` text
ON CONFLICT (empleado_key, fecha_key)
DO UPDATE SET
```

y mediante una prueba funcional de doble inserción con resultado final
de un solo registro.

## 16. PostgreSQL

La implementación y las evidencias se realizaron sobre PostgreSQL 16,
utilizando el puerto local `5437`.

No se modificó el esquema estructural de `dw.fact_asistencia` ni se creó
una FACT alternativa.

## 17. Conclusión

La ETL Asistencia → `dw.fact_asistencia` quedó implementada respetando
el grano empleado-día, la resolución histórica SCD2, las claves
dimensionales del DW, la resolución de turnos mediante `turno_bk`, las
validaciones de calidad y la idempotencia.

La ejecución real no cargó registros debido a que los datos actuales de
Asistencia presentan RUT que no tienen correspondencia en la dimensión
RRHH y además existen registros con inconsistencias de estado y atraso.

Esta situación fue detectada y reportada por el ETL sin modificar
artificialmente los datos maestros ni homologar trabajadores por nombre.
La estructura queda preparada para realizar la carga end-to-end cuando
exista la correspondencia correcta entre los datos de Asistencia y
`dw.dim_empleado`.
