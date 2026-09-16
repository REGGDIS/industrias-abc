# Fuente Producción: MySQL + CSV

## Descripción general

El dominio de Producción utiliza una fuente heterogénea compuesta por MySQL como fuente operacional principal y archivos CSV como fuente complementaria.

## Fuente principal: MySQL

La fuente operacional principal es MySQL. La estructura física del dominio Producción está definida en los siguientes scripts:

- `sql/schema.sql`
- `sql/seed.sql`
- `sql/validaciones.sql`

Las tablas oficiales del dominio son:

- `productos`
- `ordenes_produccion`
- `consumo_insumos`

## Fuente complementaria: CSV

La fuente complementaria se encuentra en:

`csv/consumo_insumos_complementario.csv`

Este archivo representa consumos de insumos informados desde planta o provenientes de una exportación complementaria de Producción.

## Estructura del archivo CSV

El archivo contiene los siguientes campos:

| Campo | Descripción |
|---|---|
| `numero_orden` | Número de la orden de producción relacionada |
| `insumo_codigo_o_referencia` | Código o referencia operacional del insumo |
| `cantidad_planificada` | Cantidad de insumo planificada |
| `cantidad_consumida` | Cantidad de insumo efectivamente consumida |
| `fecha_consumo` | Fecha en que se registra el consumo |

## Relación conceptual con el modelo

Durante el proceso posterior de staging/ETL, la información del archivo CSV se relacionará conceptualmente con la tabla `consumo_insumos`.

La homologación de las órdenes y de los insumos se realizará posteriormente durante el proceso de integración.

No existen FK físicas desde el archivo CSV hacia Compras, Abastecimiento o Contabilidad.

Los identificadores y referencias externas se mantienen independientes entre las fuentes operacionales y serán homologados posteriormente.