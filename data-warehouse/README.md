# Data Warehouse — Industrias ABC

Este directorio contiene la definición e implementación del Data Warehouse corporativo de Industrias ABC.

El objetivo es centralizar y homologar información proveniente de múltiples fuentes operacionales, aplicando un modelo dimensional integrado y preparado para cargas ETL, análisis y posterior consumo desde herramientas de Business Intelligence.

## Motor y esquema

Motor oficial:

- PostgreSQL 16

Base utilizada para validación local:

- `industrias_abc_dw`

Esquema principal:

- `dw`

Todos los objetos dimensionales y de hechos del Data Warehouse deben crearse dentro del esquema `dw`.

## Estado actual

Actualmente se encuentra implementado y validado el DW-CORE físico.

El CORE contiene las dimensiones comunes que serán reutilizadas por distintos dominios y tablas de hechos del Data Warehouse.

Dimensiones implementadas:

- `dw.dim_fecha`
- `dw.dim_area`
- `dw.dim_centro_costo`
- `dw.dim_cargo`
- `dw.dim_empleado`
- `dw.dim_turno`

## Estructura principal

```text
data-warehouse/
├── README.md
├── sql/
│   ├── 00_schema/
│   │   └── 001_crear_esquema_dw.sql
│   ├── 10_technical/
│   ├── 20_dimensions/
│   │   ├── 020_crear_dim_fecha.sql
│   │   ├── 021_poblar_dim_fecha.sql
│   │   ├── 030_crear_dim_area.sql
│   │   ├── 040_crear_dim_centro_costo.sql
│   │   ├── 050_crear_dim_cargo.sql
│   │   ├── 060_crear_dim_empleado.sql
│   │   └── 070_crear_dim_turno.sql
│   ├── 30_indexes/
│   │   └── 080_crear_indices_dimensiones.sql
│   └── 99_install/
│       └── 999_instalar_dw_core.sql
├── templates/
└── tests/
    └── structural/
        ├── test_001_esquema_dw.sql
        ├── test_020_dimensiones.sql
        └── test_030_restricciones_indices.sql
```

La carpeta `10_technical` queda reservada para futuras estructuras técnicas del Data Warehouse.

Las tablas de auditoría ETL, revisión, watermark y homologaciones específicas no forman parte del DDL inicial del CORE y serán tratadas en la etapa de integración y carga ETL.

## Convenciones de modelado

### Claves subrogadas

Las dimensiones utilizan claves subrogadas con el sufijo:

```text
*_key
```

Ejemplos:

```text
empleado_key
area_key
cargo_key
centro_costo_key
```

Las claves operacionales locales de las fuentes no deben utilizarse como claves transversales del Data Warehouse.

### Business keys

Cada dimensión debe definir una business key empresarial o una clave estable homologada.

Ejemplos:

```text
codigo_area
codigo_centro_costo
codigo_cargo
rut_normalizado
turno_bk
```

### Miembro desconocido

Las dimensiones CORE utilizan el valor subrogado:

```text
0
```

para representar el miembro desconocido.

Este registro debe existir antes de cargar hechos o dimensiones dependientes.

Ejemplo conceptual:

```text
*_key = 0
codigo = DESCONOCIDO
nombre = No informado
```

El miembro desconocido permite preservar integridad referencial cuando una relación todavía no puede ser resuelta de forma válida.

## Tratamiento histórico

### SCD Tipo 1

Las siguientes dimensiones se manejan como Slowly Changing Dimension Tipo 1:

- `dim_area`
- `dim_centro_costo`
- `dim_cargo`
- `dim_turno`

Los cambios válidos reemplazan el valor anterior sin generar una nueva versión histórica.

### DIM_EMPLEADO — SCD Tipo 2

`dw.dim_empleado` implementa historial mediante SCD Tipo 2.

Los atributos organizacionales y de estado laboral pueden generar nuevas versiones históricas.

La vigencia utiliza intervalos semiabiertos:

```text
[fecha_desde, fecha_hasta)
```

Para resolver una versión histórica:

```text
fecha_desde <= fecha_hecho
AND (
    fecha_hasta IS NULL
    OR fecha_hecho < fecha_hasta
)
```

La versión actual debe cumplir:

```text
es_actual = TRUE
fecha_hasta IS NULL
```

Se utiliza un índice único parcial para asegurar que exista como máximo una versión actual por RUT normalizado.

## DIM_FECHA

`dw.dim_fecha` utiliza una clave inteligente en formato:

```text
YYYYMMDD
```

Ejemplo:

```text
20260907
```

El miembro desconocido utiliza:

```text
fecha_key = 0
```

El rango inicial implementado es:

```text
2016-01-01 a 2030-12-31
```

El rango puede ampliarse posteriormente sin recrear la dimensión.

Los nombres de días y meses se generan explícitamente en español y no dependen de la configuración regional del servidor.

## Instalación del DW-CORE

El instalador principal es:

```text
data-warehouse/sql/99_install/999_instalar_dw_core.sql
```

Debe ejecutarse mediante `psql`.

Ejemplo:

```bash
psql -U dw_user -d industrias_abc_dw \
  -f data-warehouse/sql/99_install/999_instalar_dw_core.sql
```

El instalador utiliza:

```text
\set ON_ERROR_STOP on
```

y ejecuta el CORE dentro de una transacción:

```text
BEGIN
...
COMMIT
```

Si ocurre un error durante la instalación, la operación no debe quedar parcialmente aplicada.

El instalador utiliza `\ir`, por lo que las rutas se resuelven relativamente al propio archivo SQL.

## Validación estructural

Los tests estructurales se encuentran en:

```text
data-warehouse/tests/structural/
```

Actualmente se validan:

- existencia del esquema `dw`;
- existencia de las dimensiones CORE;
- claves primarias;
- restricciones `UNIQUE`;
- claves foráneas;
- índices críticos;
- índice único parcial de `dim_empleado`.

Tests disponibles:

```text
test_001_esquema_dw.sql
test_020_dimensiones.sql
test_030_restricciones_indices.sql
```

## Convenciones de restricciones e índices

Se utilizan los siguientes prefijos:

```text
pk_   PRIMARY KEY
fk_   FOREIGN KEY
uq_   UNIQUE
ck_   CHECK
idx_  INDEX
```

Ejemplos:

```text
pk_dim_empleado
fk_dim_empleado_area
uq_dim_area_codigo
ck_dim_empleado_vigencia
idx_dim_empleado_rut_vigencia
```

## Separación entre DW y ETL

Este directorio contiene principalmente:

- modelo físico del Data Warehouse;
- DDL;
- dimensiones;
- tablas de hechos;
- índices;
- instaladores;
- plantillas;
- tests estructurales.

Las cargas y procesos ETL se implementarán principalmente bajo:

```text
etl/
```

Las futuras cargas hacia el Data Warehouse deberán ubicarse preferentemente en:

```text
etl/sql/load/dw/
```

No se deben duplicar tablas de auditoría o control ya existentes en los procesos ETL sin una decisión explícita de integración.

## Fuentes y homologación

El Data Warehouse integra múltiples fuentes operacionales.

Reglas principales:

- no utilizar IDs locales como claves empresariales transversales;
- homologar áreas mediante códigos empresariales;
- homologar empleados mediante RUT normalizado y validado;
- homologar centros de costo mediante códigos empresariales;
- utilizar mappings explícitos cuando una fuente no comparta la misma business key;
- enviar a revisión los casos no resolubles de forma determinística.

Los nombres descriptivos pueden utilizarse como apoyo de validación, pero no deben ser la clave principal de homologación cuando exista una business key formal.

## Próximas etapas

Después del DW-CORE se incorporarán las dimensiones y tablas de hechos específicas de negocio, entre ellas:

```text
DIM_PROVEEDOR
DIM_INSUMO
DIM_PRODUCTO
DIM_CUENTA_CONTABLE
DIM_CONTRATO

FACT_ASISTENCIA
FACT_REMUNERACIONES
FACT_COMPRAS
FACT_CONTABILIDAD
FACT_PRODUCCION
FACT_CONSUMO_INSUMO
```

Posteriormente se implementarán las cargas ETL hacia el Data Warehouse y las validaciones integrales antes del consumo desde Power BI.

## Regla de trabajo

Antes de incorporar una nueva dimensión o tabla de hechos:

1. definir claramente su grano;
2. identificar su business key;
3. determinar la fuente autoritativa;
4. definir el tratamiento histórico;
5. establecer miembro desconocido cuando corresponda;
6. definir PK, FK, UNIQUE y CHECK necesarios;
7. crear índices sólo cuando aporten integridad o rendimiento;
8. agregar pruebas estructurales;
9. validar la instalación en PostgreSQL antes de integrar cambios.
