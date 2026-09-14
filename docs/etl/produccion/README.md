# ETL Producción → Data Warehouse

## Objetivo

Implementar y documentar el flujo ETL del dominio de Producción de Industrias ABC hacia el Data Warehouse corporativo, integrando la fuente operacional MySQL y el archivo CSV complementario de consumos.

El proceso carga y mantiene las siguientes estructuras del DW:

- `dw.dim_producto`
- `dw.fact_produccion`
- `dw.fact_consumo_insumo`

El diseño prioriza trazabilidad, idempotencia y homologación explícita. Cuando una referencia operacional no dispone de una equivalencia empresarial validada, el ETL conserva el dato de origen, utiliza el miembro desconocido `0` en el DW y clasifica el registro para revisión en lugar de inferir equivalencias.

## Fuentes de datos

### MySQL Producción

La fuente operacional principal es MySQL y contiene:

- `productos`
- `ordenes_produccion`
- `consumo_insumos`

La configuración se obtiene desde las variables de entorno de Producción definidas para el ETL.

### CSV complementario de consumos

Producción incorpora además el archivo:

```text
sources/produccion-mysql-csv/csv/consumo_insumos_complementario.csv
```

El CSV contiene:

- `numero_orden`
- `insumo_codigo_o_referencia`
- `cantidad_planificada`
- `cantidad_consumida`
- `fecha_consumo`

Su función es enriquecer eventos de consumo provenientes de MySQL con una referencia textual de insumo cuando existe una coincidencia inequívoca.

## Flujo implementado

```text
MySQL Producción                  CSV complementario
       |                                 |
       v                                 v
 Extracción CLEAN                 Lectura y validación
       |                                 |
       +---------------+-----------------+
                       |
                       v
            Enriquecimiento consumos
                       |
                       v
              Homologación explícita
                       |
             +---------+---------+
             |                   |
             v                   v
      DIM_PRODUCTO        Miembro 0 / REVIEW
             |                   |
             +---------+---------+
                       |
                       v
               FACT_PRODUCCION
                       |
                       v
            FACT_CONSUMO_INSUMO
                       |
                       v
                    Auditoría
```

## Archivos principales

El flujo se implementa principalmente en:

```text
etl/load/dw_produccion.py
etl/run_dw_produccion.py
etl/extract/mysql.py
etl/sql/staging/produccion/
etl/config/mappings/produccion_centros_costo.csv
etl/config/mappings/produccion_insumos.csv
etl/tests/test_dw_produccion.py
```

## Reglas de limpieza de Producción

La extracción CLEAN se apoya en los SQL versionados bajo:

```text
etl/sql/staging/produccion/
```

Entre las reglas relevantes se encuentran:

- normalización de códigos y números de orden;
- rechazo de cantidades negativas;
- conservación de órdenes abiertas con `fecha_termino = NULL`;
- validación de que la fecha de consumo pertenezca al período de la orden cuando existe fecha de término;
- aceptación de sobreconsumo (`cantidad_consumida > cantidad_planificada`) como desviación válida del negocio;
- conservación de estados operacionales de Producción sin inferir estados nuevos.

## DIM_PRODUCTO

`dw.dim_producto` utiliza como clave de negocio:

```text
codigo_producto
```

La dimensión se carga desde la fuente MySQL de Producción.

Comportamiento implementado:

- inserta productos nuevos;
- mantiene actualización tipo SCD1 para atributos descriptivos;
- permite actualizar nombre y categoría;
- no modifica silenciosamente la unidad de medida;
- un cambio de unidad de medida se clasifica como `REVIEW`;
- utiliza el miembro desconocido `producto_key = 0` cuando una referencia no puede resolverse.

La carga fue validada con cinco productos operacionales además del miembro desconocido del DW.

### Codificación de caracteres

La fuente y la conexión deben utilizar UTF-8/`utf8mb4` de forma consistente.

Durante la validación se detectó y corrigió en la fuente demo un caso de doble codificación en las categorías `Línea Industrial` y `Línea Especial`. La corrección se realizó en la fuente y luego se propagó mediante la lógica SCD1 del ETL, evitando correcciones manuales aisladas en el DW.

## FACT_PRODUCCION

`dw.fact_produccion` representa una fila por orden de producción.

La identificación operacional es:

```text
numero_orden
```

El ETL resuelve:

- `producto_key`
- `centro_costo_key`
- `area_key`
- `fecha_inicio_key`
- `fecha_termino_key`
- cantidades planificadas, producidas y rechazadas;
- estado de la orden.

### Fechas

Las fechas se resuelven contra `dw.dim_fecha`.

Las órdenes abiertas utilizan:

```text
fecha_termino_key = 0
```

Este uso de `0` representa término no informado porque la orden continúa abierta y no constituye por sí mismo un error.

### Centros de costo y áreas

La fuente de Producción utiliza identificadores locales de centro de costo (`101` a `105`). Estos identificadores no se consideran claves empresariales.

La homologación se controla mediante:

```text
etl/config/mappings/produccion_centros_costo.csv
```

Solo se consumen mappings con:

```text
estado = APROBADO
```

Mientras no exista una equivalencia empresarial validada:

- `centro_costo_key = 0`
- `area_key = 0`
- la fila queda clasificada para `REVIEW`.

No se debe asumir equivalencia por secuencia numérica, por ejemplo `101 → CC001`, si dicha relación no ha sido validada explícitamente.

## FACT_CONSUMO_INSUMO

`dw.fact_consumo_insumo` conserva un evento de consumo por `consumo_id` de la fuente MySQL.

Se preservan:

- `consumo_id`
- `numero_orden`
- `insumo_codigo_origen`
- `cantidad_planificada`
- `cantidad_consumida`
- `fecha_consumo_key`
- claves dimensionales de producto, insumo, centro de costo y área.

El uso de `consumo_id` permite distinguir eventos repetidos y evita colapsar consumos diferentes que puedan compartir orden, insumo y fecha.

## Enriquecimiento MySQL ↔ CSV

El CSV complementario no se usa para inventar eventos nuevos. Su función es enriquecer eventos ya existentes en MySQL.

La coincidencia utiliza la combinación:

```text
numero_orden
cantidad_planificada
cantidad_consumida
fecha_consumo
```

Solo se acepta una referencia CSV cuando existe una coincidencia uno-a-uno inequívoca.

En la validación actual:

- 17 consumos MySQL fueron procesados;
- 6 consumos tuvieron coincidencia inequívoca con el CSV;
- 11 consumos no tuvieron referencia CSV equivalente;
- 0 filas del CSV fueron rechazadas;
- 0 filas del CSV quedaron sin correspondencia en la muestra validada.

Para los seis matches se conserva una referencia como:

```text
INS-1001
INS-1002
INS-1003
INS-1004
INS-1006
```

Cuando no existe match inequívoco, se conserva trazabilidad mediante:

```text
ID_LOCAL:<insumo_id>
```

Ejemplo:

```text
ID_LOCAL:1005
```

Estos valores no representan una homologación empresarial; son únicamente una referencia de origen trazable.

## Homologación de insumos

La homologación de referencias de Producción con `dw.dim_insumo` se controla mediante:

```text
etl/config/mappings/produccion_insumos.csv
```

Solo se utilizan equivalencias cuyo estado sea:

```text
APROBADO
```

Mientras una referencia permanezca en `REVIEW` o no tenga código destino validado:

```text
insumo_key = 0
```

El registro de consumo queda igualmente cargado, conservando `insumo_codigo_origen` para trazabilidad.

No se debe inferir una equivalencia por similitud textual o numérica. Por ejemplo, una referencia como `INS-1001` no se debe asociar automáticamente con otro código empresarial solo porque comparte numeración o nombre parecido.

## Miembro desconocido `0`

El modelo utiliza el miembro desconocido `0` para mantener integridad referencial sin inventar claves de negocio.

En Producción se utiliza `0` cuando no puede resolverse de manera validada alguna de las siguientes dimensiones:

- producto;
- centro de costo;
- área;
- insumo;
- fecha.

Para órdenes abiertas, `fecha_termino_key = 0` tiene además el significado válido de término todavía no informado.

El uso del miembro desconocido permite cargar hechos trazables mientras una homologación queda pendiente de revisión.

## Estado `REVIEW`

`REVIEW` no significa necesariamente que el registro sea inválido.

En este ETL se utiliza para identificar datos técnicamente procesables que requieren una decisión de integración empresarial, por ejemplo:

- centro de costo local sin equivalencia aprobada;
- área no resuelta por falta de mapping;
- referencia de insumo sin homologación aprobada;
- consumo MySQL sin match inequívoco en el CSV complementario;
- cambio de unidad de medida en `DIM_PRODUCTO`.

Mientras existan filas en revisión, el runner completo puede finalizar con estado:

```text
PARTIAL
```

Esto es comportamiento esperado y no debe confundirse con `ERROR`.

## Auditoría

El runner:

```text
etl/run_dw_produccion.py
```

registra la ejecución mediante la infraestructura transversal de auditoría:

```text
etl_execution_log
```

La ejecución se identifica con:

```text
source  = PRODUCCION
process = ETL_DW_PRODUCCION
```

Se registran, entre otras métricas:

- registros leídos;
- registros válidos;
- registros rechazados;
- registros insertados;
- registros actualizados;
- registros sin cambios;
- registros enviados a revisión;
- estado final;
- mensaje de ejecución.

Los estados esperados son:

- `SUCCESS`: ejecución sin rechazos ni revisiones pendientes;
- `PARTIAL`: ejecución correcta con registros rechazados o en revisión;
- `ERROR`: falla de ejecución.

En la validación de punta a punta realizada con mappings aún pendientes se obtuvo:

```text
records_read:      36
records_valid:     36
records_rejected:  0
records_inserted:  0
records_updated:   0
records_unchanged: 30
records_review:    25
status:            PARTIAL
```

Los 30 registros sin cambios corresponden a:

- 5 productos;
- 8 órdenes de producción;
- 17 consumos de insumo.

Las 25 revisiones corresponden a:

- 8 órdenes con centro de costo/área aún no homologados;
- 17 consumos con referencias dimensionales aún pendientes de homologación.

## Idempotencia

La carga fue validada ejecutando nuevamente los mismos datos de origen.

Resultados esperados y comprobados:

### FACT_PRODUCCION

```text
insertadas:   0
actualizadas: 0
sin cambios:  8
```

### FACT_CONSUMO_INSUMO

```text
insertados:   0
actualizados: 0
sin cambios: 17
```

### Runner completo

Con el DW ya cargado:

```text
records_inserted:  0
records_updated:   0
records_unchanged: 30
```

Esto confirma que una ejecución repetida no duplica hechos ni dimensiones.

## Ejecución

Desde la raíz del repositorio y con el entorno virtual activo:

```powershell
python -m etl.run_dw_produccion
```

Antes de ejecutar deben estar disponibles:

- la fuente MySQL de Producción;
- el Data Warehouse PostgreSQL;
- la infraestructura transversal de auditoría.

En el entorno de desarrollo validado se utilizaron los contenedores:

```text
industrias-abc-produccion-db
industrias-abc-dw-db
industrias-abc-rrhh-db
```

Los puertos y credenciales no deben codificarse en el código; deben obtenerse desde las variables de entorno.

## Pruebas

Las pruebas específicas de Producción se ejecutan con:

```powershell
python -m pytest etl/tests/test_dw_produccion.py -q
```

Resultado validado:

```text
6 passed
```

La suite completa del proyecto se ejecuta con:

```powershell
python -m pytest -q
```

Resultado de regresión validado al cierre de este hito:

```text
188 passed, 38 skipped
```

Los tests específicos cubren, entre otros puntos:

- generación de claves de fecha;
- orden abierta con `fecha_termino_key = 0`;
- propagación de miembro desconocido y `REVIEW`;
- enriquecimiento único CSV ↔ MySQL;
- fallback `ID_LOCAL:<insumo_id>`;
- aceptación de sobreconsumo;
- conservación de `insumo_key = 0` cuando no existe homologación aprobada.

## Mappings pendientes

Los archivos siguientes constituyen contratos de homologación explícita:

```text
etl/config/mappings/produccion_centros_costo.csv
etl/config/mappings/produccion_insumos.csv
```

Al cierre del hito, las equivalencias empresariales permanecen en `REVIEW` porque no existe evidencia suficiente para aprobarlas automáticamente.

Para promover una fila a `APROBADO` se debe contar con evidencia de negocio o documentación maestra que establezca de forma inequívoca la relación entre el identificador local y la clave empresarial del DW.

No se deben aprobar mappings por:

- orden o secuencia numérica;
- parecido visual de códigos;
- similitud de nombres;
- coincidencia parcial de números;
- suposición basada en posición de filas.

## Estado del hito

El ETL de Producción se considera técnicamente implementado y validado para el alcance actual:

- extracción MySQL operativa;
- lectura del CSV complementario operativa;
- limpieza y validación operativas;
- `DIM_PRODUCTO` cargada y validada;
- `FACT_PRODUCCION` cargada y validada;
- `FACT_CONSUMO_INSUMO` cargada y validada;
- auditoría transversal operativa;
- idempotencia comprobada;
- regresión completa del proyecto en verde.

El estado `PARTIAL` de la ejecución actual es deliberado y se debe exclusivamente a homologaciones empresariales pendientes, no a errores técnicos del ETL.

## Próximos pasos

Para cerrar las revisiones pendientes se requiere:

1. validar explícitamente las equivalencias entre `centro_costo_id` local de Producción y los códigos empresariales de centro de costo y área;
2. validar explícitamente las equivalencias entre las referencias de insumo de Producción y `dw.dim_insumo`;
3. actualizar los CSV de mapping marcando como `APROBADO` únicamente las relaciones respaldadas por evidencia;
4. volver a ejecutar el ETL;
5. verificar la reducción de registros `REVIEW` y la actualización de las claves desconocidas `0` por las claves dimensionales correctas;
6. ejecutar nuevamente las pruebas específicas y la suite completa de regresión.
