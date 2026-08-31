# ETL RRHH 0.1

## Objetivo

Implementar el flujo inicial de extracción, transformación, validación,
staging y auditoría para la fuente operacional de Recursos Humanos de
Industrias ABC.

La fuente RRHH utiliza PostgreSQL.

## Entidades procesadas

El hito RRHH 0.1 procesa las siguientes entidades:

- empleados
- áreas
- cargos
- centros de costo

## Flujo implementado

```text
PostgreSQL RRHH
       |
       v
   Extracción
       |
       v
 Transformación
       |
       v
  Validación
       |
       v
 Staging RAW
       |
       v
 Staging CLEAN
       |
       v
   Auditoría
```

## Extracción

Los scripts SQL de extracción se encuentran en:

```text
etl/sql/extract/rrhh/
```

Actualmente se extraen:

- empleados
- áreas
- cargos
- centros de costo

La conexión PostgreSQL es reutilizable y se configura mediante variables
de entorno.

## Staging RAW

Las tablas RAW conservan los datos extraídos desde la fuente antes de
aplicar las reglas de limpieza de staging.

Tablas actuales:

- `stg_rrhh_empleados_raw`
- `stg_rrhh_areas_raw`
- `stg_rrhh_cargos_raw`
- `stg_rrhh_centros_costo_raw`

## Staging CLEAN

La capa CLEAN aplica preparación y limpieza de los datos mediante SQL.

Tablas actuales:

- `stg_rrhh_empleados_clean`
- `stg_rrhh_areas_clean`
- `stg_rrhh_cargos_clean`
- `stg_rrhh_centros_costo_clean`

Entre las transformaciones implementadas se encuentran:

- eliminación de espacios innecesarios;
- normalización de textos a mayúsculas;
- tratamiento de cadenas vacías como `NULL`;
- normalización del formato de RUT;
- conservación y conversión consistente de fechas.

## Validación

Actualmente se validan principalmente los registros de empleados.

Los resultados de validación se clasifican como:

- `VALID`
- `WARNING`
- `ERROR`

Las reglas implementadas incluyen validación de:

- presencia de identificadores obligatorios;
- formato canónico del RUT;
- nombres y apellido paterno;
- fechas de ingreso y salida;
- área y cargo;
- estado del empleado;
- coherencia entre fecha de salida y estado.

## Auditoría

Cada ejecución del ETL RRHH genera un registro en:

```text
etl_execution_log
```

La auditoría registra:

- identificador de ejecución;
- fuente;
- proceso;
- fecha de inicio;
- fecha de término;
- registros leídos;
- registros válidos;
- registros rechazados;
- estado;
- mensaje de ejecución.

## Ejecución

Desde la raíz del repositorio:

```powershell
python -m pip install -r .\etl\requirements.txt
python -m etl.run_rrhh
```

## Pruebas

Los tests se ejecutan mediante:

```powershell
python -m pytest etl/tests -v
```

## Alcance pendiente

Este hito no implementa todavía:

- dimensiones del Data Warehouse;
- tablas de hechos;
- claves subrogadas;
- homologación definitiva entre fuentes;
- carga incremental;
- Slowly Changing Dimensions (SCD);
- carga final al Data Warehouse.

Estas capacidades corresponden a etapas posteriores del ETL.
