# Data Warehouse — Industrias ABC

Este directorio contiene la definición e implementación del Data Warehouse corporativo de Industrias ABC.

El objetivo es centralizar y homologar información proveniente de múltiples fuentes operacionales, aplicando un modelo dimensional integrado y preparado para cargas ETL, análisis y posterior consumo desde herramientas de Business Intelligence y desde la aplicación analítica del proyecto.

## Motor y esquema

Motor oficial:

- PostgreSQL 16

Base utilizada para validación local:

- `industrias_abc_dw`

Esquema principal:

- `dw`

Todos los objetos dimensionales y de hechos del Data Warehouse deben crearse dentro del esquema `dw`.

## Estado actual

Actualmente se encuentran implementados y validados el DW-CORE físico, el dominio analítico RRHH y el modelo físico del dominio analítico Compras en su estado actual.

El CORE contiene las dimensiones comunes reutilizadas por distintos dominios y tablas de hechos del Data Warehouse.

Dimensiones implementadas:

- `dw.dim_fecha`
- `dw.dim_area`
- `dw.dim_centro_costo`
- `dw.dim_cargo`
- `dw.dim_empleado`
- `dw.dim_turno`
- `dw.dim_contrato`
- `dw.dim_proveedor`
- `dw.dim_insumo`

Tablas de hechos implementadas:

- `dw.fact_asistencia`
- `dw.fact_remuneraciones`
- `dw.fact_compras`

### FACT_ASISTENCIA

**Grano:** una fila por empleado empresarial y fecha con registro de asistencia.

**Fuente principal:** Sistema Operacional de Asistencia (MySQL).

**Dimensiones relacionadas:**

- `dw.dim_fecha`
- `dw.dim_empleado`
- `dw.dim_area`
- `dw.dim_cargo`
- `dw.dim_centro_costo`
- `dw.dim_turno`

**Medidas principales:**

- `horas_trabajadas`
- `horas_normales`
- `horas_extras`
- `minutos_atraso`
- `dias_trabajados`
- `dias_ausentes`
- `cantidad_registros`

`FACT_ASISTENCIA` utiliza la versión histórica correcta de `DIM_EMPLEADO`. La resolución futura durante la carga ETL deberá realizarse mediante RUT normalizado + fecha del hecho, aplicando la vigencia SCD Tipo 2 de la dimensión.

### DIM_CONTRATO

`dw.dim_contrato` forma parte del dominio analítico RRHH y representa los contratos laborales provenientes del Sistema Operacional de Contratos y Remuneraciones.

**Business key:**

```text
numero_contrato
```

Los identificadores locales del sistema SQL Server, como `contrato_id` y `empleado_id`, no se utilizan como claves transversales del Data Warehouse.

`DIM_CONTRATO` utiliza tratamiento SCD Tipo 1 debido a las limitaciones de historial disponibles en la fuente operacional.

La dimensión se relaciona con:

- `dw.dim_empleado`
- `dw.dim_cargo`

Atributos principales:

- `numero_contrato`
- `empleado_key`
- `cargo_key`
- `tipo_contrato`
- `fecha_inicio`
- `fecha_termino`
- `jornada`
- `sueldo_base_contractual`
- `cargo_contrato`
- `estado_contrato`

`cargo_contrato` se conserva como texto descriptivo de trazabilidad. No debe utilizarse como sustituto de `cargo_key` ni homologarse por similitud textual. La resolución de `cargo_key` debe realizarse mediante códigos empresariales o mappings explícitos durante la carga ETL.

### FACT_REMUNERACIONES

`dw.fact_remuneraciones` representa las liquidaciones mensuales del dominio analítico RRHH.

**Grano:**

```text
1 fila por empleado empresarial y período mensual de liquidación
```

**Fuente principal:** Sistema Operacional de Contratos y Remuneraciones (SQL Server).

La granularidad queda protegida mediante:

```text
UNIQUE (empleado_key, periodo)
```

La tabla se relaciona con:

- `dw.dim_fecha`
- `dw.dim_empleado`
- `dw.dim_area`
- `dw.dim_cargo`
- `dw.dim_centro_costo`
- `dw.dim_contrato`

`fecha_key` representa el primer día del período mensual. Por ejemplo:

```text
periodo   = 2026-08
fecha_key = 20260801
```

Medidas base provenientes de la liquidación:

- `sueldo_base`
- `horas_extras`
- `sueldo_imponible`
- `sueldo_liquido`
- `costo_empresa`

Medidas derivadas desde el detalle de liquidación:

- `total_haberes`
- `total_descuentos`
- `total_aportes`

Estas tres medidas se obtendrán durante la carga ETL agregando `DetalleLiquidacion` junto con `ConceptoPago`, según los tipos operacionales `HABER`, `DESCUENTO` y `APORTE`.

No se introducen reglas contables o remuneracionales no soportadas por la fuente. Por ejemplo, el modelo físico no fuerza relaciones matemáticas entre sueldo imponible, sueldo líquido, haberes, descuentos y costo empresa cuando la fuente no garantiza dichas relaciones como invariantes.

### DIM_PROVEEDOR

`dw.dim_proveedor` forma parte del dominio analítico Compras y representa los proveedores empresariales provenientes del Sistema Operacional de Compras.

**Business key:**

```text
rut_proveedor_normalizado
```

El RUT se normaliza y valida (dígito verificador) durante la carga ETL. No se utilizan `razon_social` ni identificadores locales de la fuente (`proveedor_id`) como claves transversales del Data Warehouse.

`DIM_PROVEEDOR` utiliza tratamiento SCD Tipo 1: los cambios descriptivos válidos reemplazan el valor anterior sin generar versiones históricas.

Atributos principales:

- `rut_proveedor_normalizado`
- `razon_social`
- `nombre_fantasia`
- `categoria`
- `region`
- `comuna`
- `estado`
- `codigo_proveedor_ref`

`codigo_proveedor_ref` es una referencia opcional al Universo Master y no reemplaza al RUT como business key.

### DIM_INSUMO

`dw.dim_insumo` forma parte del dominio analítico Compras y representa los insumos empresariales homologados provenientes del Sistema Operacional de Compras.

**Business key:**

```text
codigo_insumo
```

`DIM_INSUMO` utiliza tratamiento SCD Tipo 1. La categoría se conserva desnormalizada dentro de la propia dimensión (`codigo_categoria` y `nombre_categoria`); no se crea `DIM_CATEGORIA_INSUMO`.

Atributos principales:

- `codigo_insumo`
- `nombre_insumo`
- `codigo_categoria`
- `nombre_categoria`
- `unidad_medida`
- `stock_minimo`
- `estado`

Un cambio de `unidad_medida` para una misma business key **no** se aplica como SCD Tipo 1 silencioso, porque altera el significado histórico de las cantidades. Ese caso debe derivarse a REVIEW durante la carga ETL (Bloque 6). El modelo físico documenta esta regla; no la fuerza mediante restricción.

### FACT_COMPRAS

`dw.fact_compras` representa las órdenes de compra a nivel de detalle del dominio analítico Compras.

**Grano:**

```text
1 fila por línea de detalle de una orden de compra (un insumo dentro de una OC)
```

**Fuente principal:** Sistema Operacional de Compras (PostgreSQL).

La granularidad queda protegida mediante:

```text
UNIQUE (numero_oc, insumo_key)
```

La tabla se relaciona con:

- `dw.dim_fecha` (role-playing: fecha de emisión y fecha requerida)
- `dw.dim_proveedor`
- `dw.dim_insumo`
- `dw.dim_centro_costo`
- `dw.dim_area`

`numero_oc` se conserva como dimensión degenerada (identificador empresarial de la orden de compra). `codigo_comprador` se conserva como atributo local descriptivo y no se homologa a empleado sin una business key común.

Medidas de la línea:

- `cantidad`
- `precio_unitario`
- `descuento`
- `subtotal`
- `impuesto`
- `total`
- `cantidad_recibida`
- `cantidad_rechazada`
- `cantidad_lineas`

#### Prorrateo de impuesto y total

`impuesto` y `total` existen en la **cabecera** de la orden de compra, no en la línea. El modelo físico define las columnas a nivel de línea, pero **no** calcula el prorrateo: ese cálculo corresponde a la carga ETL (Bloque 6), aplicando:

```text
impuesto_linea = impuesto_oc * subtotal_linea / subtotal_oc
total_linea    = subtotal_linea + impuesto_linea
```

La carga ETL deberá garantizar, por orden de compra:

```text
SUM(subtotal_linea) = subtotal_oc
SUM(impuesto_linea) = impuesto_oc
SUM(total_linea)    = total_oc
```

El residuo por redondeo debe asignarse de forma determinística a una línea, para preservar la cuadratura contra la cabecera.

#### Moneda de origen

`moneda_origen` preserva la moneda real de la OC (`CLP`, `USD` o `EUR`). No se suman montos de monedas distintas sin una conversión aprobada. La conversión a moneda de reporte, si se requiere, corresponde a la carga ETL o a la capa de consumo, no al modelo físico.

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
│   │   ├── 070_crear_dim_turno.sql
│   │   ├── 120_crear_dim_contrato.sql
│   │   ├── 160_crear_dim_proveedor.sql
│   │   └── 170_crear_dim_insumo.sql
│   ├── 30_indexes/
│   │   ├── 080_crear_indices_dimensiones.sql
│   │   ├── 110_crear_indices_fact_asistencia.sql
│   │   ├── 130_crear_indices_dim_contrato.sql
│   │   ├── 150_crear_indices_fact_remuneraciones.sql
│   │   └── 190_crear_indices_compras.sql
│   ├── 40_facts/
│   │   ├── 100_crear_fact_asistencia.sql
│   │   ├── 140_crear_fact_remuneraciones.sql
│   │   └── 180_crear_fact_compras.sql
│   └── 99_install/
│       ├── 996_instalar_dw_compras.sql
│       ├── 997_instalar_dw_rrhh_contratos_remuneraciones.sql
│       ├── 998_instalar_dw_rrhh_asistencia.sql
│       └── 999_instalar_dw_core.sql
├── templates/
│   └── plantilla_dimension_ddl.sql
└── tests/
    └── structural/
        ├── test_001_esquema_dw.sql
        ├── test_020_dimensiones.sql
        ├── test_030_restricciones_indices.sql
        ├── test_040_fact_asistencia.sql
        ├── test_050_integridad_historica_rrhh.sql
        ├── test_060_dim_contrato.sql
        ├── test_070_reglas_dim_contrato.sql
        ├── test_080_fact_remuneraciones.sql
        ├── test_090_reglas_fact_remuneraciones.sql
        ├── test_100_dim_proveedor_insumo.sql
        └── test_110_fact_compras.sql
```

La carpeta `10_technical` queda reservada para futuras estructuras técnicas del Data Warehouse.

Las tablas de auditoría ETL, revisión, watermark y homologaciones específicas no forman parte del DDL inicial del CORE y serán tratadas en la etapa de integración y carga ETL.

> **Nota de numeración (coordinación):** el dominio Compras utiliza el rango de numeración `160`–`190` y `996`. Otros dominios pendientes del Bloque 5 (Producción, Contabilidad) deben elegir rangos posteriores para evitar colisiones. Antes del PR final, re-sincronizar `develop` (`git merge origin/develop`) y verificar que ningún archivo comparta número.

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
contrato_key
proveedor_key
insumo_key
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
numero_contrato
rut_proveedor_normalizado
codigo_insumo
```

En `DIM_CONTRATO`, la business key es `numero_contrato`. En `DIM_PROVEEDOR`, la business key es `rut_proveedor_normalizado`. En `DIM_INSUMO`, la business key es `codigo_insumo`.

### Miembro desconocido

Las dimensiones utilizan el valor subrogado:

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

`DIM_CONTRATO` también implementa su miembro desconocido con:

```text
contrato_key = 0
numero_contrato = DESCONOCIDO
```

`DIM_PROVEEDOR` y `DIM_INSUMO` implementan su miembro desconocido con:

```text
proveedor_key = 0    rut_proveedor_normalizado = DESCONOCIDO
insumo_key    = 0    codigo_insumo             = DESCONOCIDO
```

## Tratamiento histórico

### SCD Tipo 1

Las siguientes dimensiones se manejan como Slowly Changing Dimension Tipo 1:

- `dim_area`
- `dim_centro_costo`
- `dim_cargo`
- `dim_turno`
- `dim_contrato`
- `dim_proveedor`
- `dim_insumo`

Los cambios válidos reemplazan el valor anterior sin generar una nueva versión histórica.

Para `DIM_CONTRATO`, este tratamiento se adopta debido a que la fuente operacional actual no entrega un historial estructural suficiente para reconstruir versiones contractuales SCD2 confiables.

Para `DIM_INSUMO`, aunque el tratamiento general es SCD Tipo 1, un cambio de `unidad_medida` se deriva a REVIEW en el ETL en lugar de aplicarse de forma silenciosa, porque altera el significado histórico de las cantidades.

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

Los solapamientos históricos entre versiones de un mismo RUT se consideran un error de calidad y deben detectarse durante la carga SCD2 y las validaciones ETL. En el modelo físico actual no se incorpora una restricción `EXCLUDE` adicional para este caso.

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

## FACT_ASISTENCIA

`dw.fact_asistencia` representa los eventos diarios de asistencia del dominio analítico RRHH.

Su grano es:

```text
1 fila por empleado empresarial y fecha con registro de asistencia
```

La tabla se relaciona con:

```text
dw.dim_fecha
dw.dim_empleado
dw.dim_area
dw.dim_cargo
dw.dim_centro_costo
dw.dim_turno
```

La granularidad queda protegida mediante:

```text
UNIQUE (empleado_key, fecha_key)
```

La tabla incluye medidas de horas trabajadas, horas normales, horas extras, atraso, días trabajados, días ausentes y cantidad de registros.

Se implementan controles de coherencia para:

- estados `PRESENTE`, `ATRASO` y `AUSENTE`;
- horas no negativas;
- `horas_extras <= horas_trabajadas`;
- minutos de atraso no negativos;
- coherencia entre estado y días trabajados/ausentes;
- ausencia con horas y marcaciones en cero o nulas según corresponda.

## DIM_CONTRATO — reglas físicas

`dw.dim_contrato` utiliza una clave subrogada:

```text
contrato_key
```

y una business key empresarial:

```text
numero_contrato
```

La business key queda protegida por una restricción `UNIQUE`.

Relaciones dimensionales:

```text
empleado_key -> dw.dim_empleado
cargo_key    -> dw.dim_cargo
```

Reglas físicas principales:

- `contrato_key >= 0`;
- miembro desconocido coherente con `contrato_key = 0`;
- tipos admitidos: `INDEFINIDO`, `PLAZO_FIJO`, `TEMPORAL`, más `DESCONOCIDO` para el miembro 0;
- estados admitidos: `VIGENTE`, `TERMINADO`, más `DESCONOCIDO` para el miembro 0;
- sueldo base contractual no negativo;
- `fecha_termino >= fecha_inicio` cuando exista;
- los contratos `PLAZO_FIJO` y `TEMPORAL` deben registrar `fecha_termino`.

Índices complementarios:

- empleado;
- cargo;
- estado;
- vigencia contractual por `fecha_inicio, fecha_termino`.

## FACT_REMUNERACIONES — reglas físicas

`dw.fact_remuneraciones` utiliza una clave técnica:

```text
remuneracion_fact_key
```

Su grano se protege mediante:

```text
UNIQUE (empleado_key, periodo)
```

Relaciones dimensionales:

```text
fecha_key        -> dw.dim_fecha
empleado_key     -> dw.dim_empleado
area_key         -> dw.dim_area
cargo_key        -> dw.dim_cargo
centro_costo_key -> dw.dim_centro_costo
contrato_key     -> dw.dim_contrato
```

El período debe cumplir:

```text
YYYY-MM
```

con mes válido entre `01` y `12`.

Todas las medidas monetarias y de horas definidas en la tabla deben ser no negativas.

`cantidad_registros` debe ser siempre igual a `1`.

Índices complementarios:

- fecha;
- contrato;
- área;
- cargo;
- centro de costo.

No se crea un índice independiente por `empleado_key`, ya que la restricción `UNIQUE (empleado_key, periodo)` genera un índice cuyo primer componente es `empleado_key`.

## DIM_PROVEEDOR — reglas físicas

`dw.dim_proveedor` utiliza una clave subrogada:

```text
proveedor_key
```

y una business key empresarial:

```text
rut_proveedor_normalizado
```

La business key queda protegida por una restricción `UNIQUE`.

Reglas físicas principales:

- `proveedor_key >= 0`;
- miembro desconocido coherente con `proveedor_key = 0` y `rut_proveedor_normalizado = 'DESCONOCIDO'`;
- un registro real (`proveedor_key > 0`) no puede usar el RUT `'DESCONOCIDO'`.

La dimensión no crea índices adicionales: la business key ya queda indexada por su restricción `UNIQUE`.

## DIM_INSUMO — reglas físicas

`dw.dim_insumo` utiliza una clave subrogada:

```text
insumo_key
```

y una business key empresarial:

```text
codigo_insumo
```

La business key queda protegida por una restricción `UNIQUE`.

Reglas físicas principales:

- `insumo_key >= 0`;
- miembro desconocido coherente con `insumo_key = 0` y `codigo_insumo = 'DESCONOCIDO'`;
- un registro real (`insumo_key > 0`) no puede usar el código `'DESCONOCIDO'`;
- `stock_minimo` nulo o no negativo;
- categoría desnormalizada dentro de la dimensión (`codigo_categoria`, `nombre_categoria`), sin `DIM_CATEGORIA_INSUMO`.

La dimensión no crea índices adicionales: la business key ya queda indexada por su restricción `UNIQUE`.

## FACT_COMPRAS — reglas físicas

`dw.fact_compras` utiliza una clave técnica:

```text
compra_fact_key
```

Su grano se protege mediante:

```text
UNIQUE (numero_oc, insumo_key)
```

Relaciones dimensionales:

```text
fecha_emision_key   -> dw.dim_fecha
fecha_requerida_key -> dw.dim_fecha
proveedor_key       -> dw.dim_proveedor
insumo_key          -> dw.dim_insumo
centro_costo_key    -> dw.dim_centro_costo
area_key            -> dw.dim_area
```

`dim_fecha` se utiliza como dimensión role-playing (emisión y requerida). Cuando la fecha requerida no esté informada, se utiliza `0` (miembro desconocido).

Reglas físicas principales:

- `moneda_origen` admitida: `CLP`, `USD`, `EUR`;
- `estado_oc` nulo o dentro del dominio `EMITIDA`, `PARCIAL`, `RECIBIDA`, `CERRADA`, `ANULADA`;
- todas las medidas de cantidad y monto no negativas;
- `cantidad_lineas` siempre igual a `1`;
- `numero_oc` como dimensión degenerada obligatoria.

`impuesto` y `total` se prorratean al grano de línea durante la carga ETL (Bloque 6); el DDL define las columnas pero no calcula el prorrateo.

Índices complementarios (una `FOREIGN KEY` no genera índice automático en PostgreSQL):

- fecha de emisión;
- fecha requerida;
- proveedor;
- insumo;
- centro de costo;
- área.

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

### Instalación del paquete DW-RRHH / Asistencia

`FACT_ASISTENCIA` se instala después del DW-CORE, ya que depende de las dimensiones conformadas comunes.

Instalador:

```text
data-warehouse/sql/99_install/998_instalar_dw_rrhh_asistencia.sql
```

Ejemplo:

```bash
psql -U dw_user -d industrias_abc_dw \
  -f data-warehouse/sql/99_install/998_instalar_dw_rrhh_asistencia.sql
```

El instalador ejecuta, dentro de una transacción:

1. `100_crear_fact_asistencia.sql`
2. `110_crear_indices_fact_asistencia.sql`

El script utiliza `ON_ERROR_STOP`, `BEGIN` y `COMMIT`, por lo que un error durante la instalación impide dejar el paquete parcialmente aplicado.

El paquete requiere que previamente existan:

- `dw.dim_fecha`
- `dw.dim_empleado`
- `dw.dim_area`
- `dw.dim_cargo`
- `dw.dim_centro_costo`
- `dw.dim_turno`

### Instalación del paquete DW-RRHH 0.3 — Contratos y Remuneraciones

El instalador específico es:

```text
data-warehouse/sql/99_install/997_instalar_dw_rrhh_contratos_remuneraciones.sql
```

Debe ejecutarse después del DW-CORE.

Ejemplo:

```bash
psql -U dw_user -d industrias_abc_dw \
  -f data-warehouse/sql/99_install/997_instalar_dw_rrhh_contratos_remuneraciones.sql
```

El instalador ejecuta, dentro de una transacción:

1. `120_crear_dim_contrato.sql`
2. `130_crear_indices_dim_contrato.sql`
3. `140_crear_fact_remuneraciones.sql`
4. `150_crear_indices_fact_remuneraciones.sql`

El script utiliza:

```text
\set ON_ERROR_STOP on
BEGIN
...
COMMIT
```

por lo que un error durante la instalación impide dejar el paquete parcialmente aplicado.

El paquete depende previamente de las dimensiones del DW-CORE:

- `dw.dim_fecha`
- `dw.dim_empleado`
- `dw.dim_area`
- `dw.dim_cargo`
- `dw.dim_centro_costo`

La instalación reproducible de DW-RRHH 0.3 fue validada sobre PostgreSQL 16 eliminando previamente `dw.fact_remuneraciones` y `dw.dim_contrato`, ejecutando el instalador `997` y volviendo a ejecutar los tests estructurales y funcionales asociados.

Resultado:

```text
DW-RRHH 0.3 instalado correctamente.
```

### Instalación del paquete DW-COMPRAS

El instalador específico es:

```text
data-warehouse/sql/99_install/996_instalar_dw_compras.sql
```

Debe ejecutarse después del DW-CORE, ya que `FACT_COMPRAS` depende de las dimensiones conformadas comunes (`dim_fecha`, `dim_area`, `dim_centro_costo`).

Ejemplo:

```bash
psql -U dw_user -d industrias_abc_dw \
  -f data-warehouse/sql/99_install/996_instalar_dw_compras.sql
```

El instalador ejecuta, dentro de una transacción:

1. `160_crear_dim_proveedor.sql`
2. `170_crear_dim_insumo.sql`
3. `180_crear_fact_compras.sql`
4. `190_crear_indices_compras.sql`

El script utiliza:

```text
\set ON_ERROR_STOP on
BEGIN
...
COMMIT
```

por lo que un error durante la instalación impide dejar el paquete parcialmente aplicado.

El paquete depende previamente de las dimensiones del DW-CORE:

- `dw.dim_fecha`
- `dw.dim_area`
- `dw.dim_centro_costo`

La instalación reproducible de DW-COMPRAS fue validada sobre PostgreSQL 16 sobre una base limpia `industrias_abc_dw`: instalación del CORE, ejecución del instalador `996`, ejecución de los tests estructurales `test_100` y `test_110`, y re-ejecución idempotente del instalador. El paquete utiliza `CREATE TABLE IF NOT EXISTS`, `CREATE INDEX IF NOT EXISTS` e inserts de miembro desconocido con `ON CONFLICT DO NOTHING`, por lo que puede re-ejecutarse sin error.

Resultado:

```text
DW-COMPRAS instalado correctamente.
```

## Validación estructural y funcional

Los tests se encuentran en:

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
- índice único parcial de `dim_empleado`;
- estructura completa de `FACT_ASISTENCIA`;
- integridad histórica SCD2 de `DIM_EMPLEADO`;
- compatibilidad temporal entre `DIM_EMPLEADO` y `FACT_ASISTENCIA`;
- estructura física de `DIM_CONTRATO`;
- reglas funcionales de `DIM_CONTRATO`;
- estructura física de `FACT_REMUNERACIONES`;
- reglas funcionales de `FACT_REMUNERACIONES`;
- estructura y reglas de `DIM_PROVEEDOR` y `DIM_INSUMO`;
- estructura y reglas de `FACT_COMPRAS`;
- ejecución de pruebas funcionales con `ROLLBACK` o limpieza posterior para evitar contaminación del DW.

Tests disponibles:

```text
test_001_esquema_dw.sql
test_020_dimensiones.sql
test_030_restricciones_indices.sql
test_040_fact_asistencia.sql
test_050_integridad_historica_rrhh.sql
test_060_dim_contrato.sql
test_070_reglas_dim_contrato.sql
test_080_fact_remuneraciones.sql
test_090_reglas_fact_remuneraciones.sql
test_100_dim_proveedor_insumo.sql
test_110_fact_compras.sql
```

### Test estructural de FACT_ASISTENCIA

Archivo:

```text
data-warehouse/tests/structural/test_040_fact_asistencia.sql
```

El test verifica automáticamente:

- existencia de `dw.fact_asistencia`;
- `pk_fact_asistencia`;
- unicidad del grano mediante `uq_fact_asistencia_empleado_fecha`;
- las seis claves foráneas hacia dimensiones;
- los CHECK de dominio y coherencia;
- los índices complementarios de fecha, turno, área y centro de costo.

La implementación fue validada contra PostgreSQL 16 real con resultado:

```text
TEST OK: FACT_ASISTENCIA, restricciones e índices verificados.
```

La tabla también fue inspeccionada directamente en PostgreSQL, confirmándose:

- 6 claves foráneas;
- 12 restricciones CHECK;
- 1 primary key;
- 1 restricción UNIQUE para `empleado_key + fecha_key`;
- 4 índices complementarios.

### Validación histórica SCD2 de RRHH

Archivo:

```text
data-warehouse/tests/structural/test_050_integridad_historica_rrhh.sql
```

El test valida la integridad temporal de `DIM_EMPLEADO` y su compatibilidad con `FACT_ASISTENCIA`.

Se comprueba:

- que no exista más de una versión actual por RUT;
- que las vigencias sean válidas;
- que no existan solapamientos históricos en los datos actuales;
- que el lookup `RUT + fecha del hecho` resuelva correctamente una única versión;
- que el intervalo de vigencia se interprete como `[fecha_desde, fecha_hasta)`;
- que una segunda versión actual del mismo RUT sea rechazada;
- que un solapamiento SCD2 intencional sea detectado por el control de calidad;
- que `FACT_ASISTENCIA` pueda relacionarse con la versión histórica correcta de `DIM_EMPLEADO`;
- que el miembro desconocido de `DIM_EMPLEADO` mantenga su contrato.

La prueba se ejecuta íntegramente dentro de una transacción y finaliza con `ROLLBACK`, por lo que no deja fixtures ni registros temporales persistentes.

Resultado validado sobre PostgreSQL 16:

```text
TEST OK: integridad histórica SCD2 de RRHH y compatibilidad con FACT_ASISTENCIA verificadas.
```

También se comprobó posteriormente que no quedaran filas de fixture en `DIM_EMPLEADO` ni en `FACT_ASISTENCIA`.

Como decisión de diseño, los solapamientos históricos se controlarán en la etapa de carga SCD2 y validación ETL. No se incorpora por ahora una restricción física adicional de exclusión en PostgreSQL.

### Test estructural de DIM_CONTRATO

Archivo:

```text
data-warehouse/tests/structural/test_060_dim_contrato.sql
```

El test verifica:

- existencia de `dw.dim_contrato`;
- primary key `pk_dim_contrato`;
- business key única mediante `uq_dim_contrato_numero`;
- claves foráneas hacia `DIM_EMPLEADO` y `DIM_CARGO`;
- CHECKs de clave, miembro desconocido, tipo, estado, sueldo y fechas;
- índices complementarios;
- existencia y coherencia del miembro desconocido.

Resultado validado sobre PostgreSQL 16:

```text
TEST OK: DIM_CONTRATO, restricciones, índices y miembro desconocido verificados.
```

### Validación funcional de DIM_CONTRATO

Archivo:

```text
data-warehouse/tests/structural/test_070_reglas_dim_contrato.sql
```

La prueba valida ocho casos funcionales:

1. contrato indefinido válido aceptado;
2. contrato a plazo fijo válido aceptado;
3. business key duplicada rechazada;
4. sueldo contractual negativo rechazado;
5. rango de fechas inválido rechazado;
6. contrato `PLAZO_FIJO` sin fecha de término rechazado;
7. tipo de contrato fuera del dominio rechazado;
8. estado de contrato fuera del dominio rechazado.

La prueba finaliza con `ROLLBACK`.

Resultado:

```text
TEST OK: reglas funcionales de DIM_CONTRATO verificadas.
```

Después de la ejecución se comprobó explícitamente que no quedaran fixtures en el rango de claves de prueba de `DIM_CONTRATO`.

### Test estructural de FACT_REMUNERACIONES

Archivo:

```text
data-warehouse/tests/structural/test_080_fact_remuneraciones.sql
```

El test verifica:

- existencia de `dw.fact_remuneraciones`;
- primary key;
- unicidad del grano `empleado_key + periodo`;
- las seis claves foráneas;
- los CHECKs de período y medidas;
- `cantidad_registros = 1`;
- los cinco índices complementarios.

Resultado validado sobre PostgreSQL 16:

```text
TEST OK: FACT_REMUNERACIONES, restricciones e índices verificados.
```

### Validación funcional de FACT_REMUNERACIONES

Archivo:

```text
data-warehouse/tests/structural/test_090_reglas_fact_remuneraciones.sql
```

La prueba valida ocho casos funcionales:

1. registro válido de remuneraciones aceptado;
2. duplicidad `empleado + período` rechazada;
3. período inválido rechazado;
4. sueldo base negativo rechazado;
5. horas extras negativas rechazadas;
6. total de descuentos negativo rechazado;
7. `cantidad_registros` distinta de 1 rechazada;
8. `contrato_key` inexistente rechazado.

La prueba finaliza con `ROLLBACK`.

Resultado:

```text
TEST OK: reglas funcionales de FACT_REMUNERACIONES verificadas.
```

Después de la ejecución se comprobó explícitamente que no quedaran fixtures en el rango de claves de prueba de `FACT_REMUNERACIONES`.

### Test estructural de DIM_PROVEEDOR y DIM_INSUMO

Archivo:

```text
data-warehouse/tests/structural/test_100_dim_proveedor_insumo.sql
```

El test verifica:

- existencia de `dw.dim_proveedor` y `dw.dim_insumo`;
- las restricciones esperadas por nombre (PK, UNIQUE de business key, CHECK de clave, miembro desconocido y `stock_minimo`);
- existencia y coherencia del miembro desconocido en ambas dimensiones;
- que un registro real de `DIM_PROVEEDOR` no acepte RUT `'DESCONOCIDO'`;
- que `DIM_INSUMO` rechace `stock_minimo` negativo.

Los casos funcionales se ejecutan dentro de bloques `DO` con sub-transacciones que revierten los inserts de prueba, sin dejar residuos.

Resultado validado sobre PostgreSQL 16:

```text
== TEST 100: TODOS LOS CHEQUEOS OK ==
```

### Test estructural de FACT_COMPRAS

Archivo:

```text
data-warehouse/tests/structural/test_110_fact_compras.sql
```

El test verifica:

- existencia de `dw.fact_compras`;
- conteo de restricciones (`PK=1`, `UNIQUE=1`, `FK=6`, `CHECK>=11`);
- las seis claves foráneas por nombre;
- los seis índices de FK por nombre;
- que una fila válida referenciando los miembros desconocidos (`key=0`) sea aceptada;
- que una FK a proveedor inexistente sea rechazada;
- que una moneda fuera del dominio sea rechazada;
- que un grano duplicado (`numero_oc`, `insumo_key`) sea rechazado.

Los inserts de prueba se limpian dentro del propio test, sin dejar datos de negocio.

Resultado validado sobre PostgreSQL 16:

```text
== TEST 110: TODOS LOS CHEQUEOS OK ==
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
pk_dim_contrato
uq_dim_contrato_numero
pk_fact_remuneraciones
uq_fact_remuneraciones_empleado_periodo
pk_dim_proveedor
uq_dim_proveedor_rut
pk_dim_insumo
uq_dim_insumo_codigo
pk_fact_compras
uq_fact_compras_oc_insumo
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
- tests estructurales y funcionales.

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

### Contratos y Remuneraciones

Para el Sistema Operacional de Contratos y Remuneraciones:

- `empleado_id` es un identificador local de la fuente;
- `contrato_id` es un identificador local de la fuente;
- `liquidacion_id` es un identificador local de la fuente;
- `numero_contrato` es la business key utilizada por `DIM_CONTRATO`;
- la referencia de empleado debe homologarse mediante RUT normalizado;
- `codigo_area_ref` y `codigo_cargo_ref` son referencias operacionales que deben validarse contra los catálogos empresariales;
- el texto `cargo_contrato` se conserva para trazabilidad, no como regla principal de homologación;
- `periodo` se conserva con semántica `YYYY-MM`;
- los conceptos de liquidación se agregan por `liquidacion_id` antes de cargar `FACT_REMUNERACIONES`.

La carga ETL futura deberá resolver `empleado_key` usando RUT normalizado y la versión SCD2 válida para la fecha o período del hecho.

Las claves organizacionales `area_key`, `cargo_key` y `centro_costo_key` deberán ser coherentes con la versión histórica del empleado utilizada para el hecho.

### Compras

Para el Sistema Operacional de Compras:

- `proveedor_id`, `insumo_id` y `oc_id` son identificadores locales de la fuente y no se utilizan como claves transversales del Data Warehouse;
- `rut_proveedor_normalizado` es la business key utilizada por `DIM_PROVEEDOR`; el RUT se normaliza y valida (dígito verificador) durante la carga ETL;
- `codigo_insumo` es la business key utilizada por `DIM_INSUMO`;
- la categoría de insumo se conserva desnormalizada dentro de `DIM_INSUMO`; no se crea `DIM_CATEGORIA_INSUMO`;
- `numero_oc` se conserva como dimensión degenerada en `FACT_COMPRAS`;
- `codigo_comprador` se conserva como atributo local descriptivo; no se homologa a empleado sin una business key común;
- `impuesto` y `total` provienen de la cabecera de la OC y deben prorratearse al grano de línea durante la carga ETL;
- `moneda_origen` preserva la moneda real de la OC; no se suman montos de monedas distintas sin conversión aprobada;
- el grano de `FACT_COMPRAS` se protege mediante `UNIQUE (numero_oc, insumo_key)`.

## Estado actual del Data Warehouse

### Implementado y validado

- Esquema `dw`
- `DIM_FECHA`
- `DIM_AREA`
- `DIM_CENTRO_COSTO`
- `DIM_CARGO`
- `DIM_EMPLEADO`
- `DIM_TURNO`
- `DIM_CONTRATO`
- `DIM_PROVEEDOR`
- `DIM_INSUMO`
- `FACT_ASISTENCIA`
- `FACT_REMUNERACIONES`
- `FACT_COMPRAS`
- integridad histórica SCD2 de RRHH
- resolución temporal `RUT + fecha`
- compatibilidad histórica entre `DIM_EMPLEADO` y `FACT_ASISTENCIA`
- business key contractual `numero_contrato`
- grano mensual `empleado + período` de remuneraciones
- business key de proveedor `rut_proveedor_normalizado` e insumo `codigo_insumo`
- grano de línea de compra `numero_oc + insumo_key`
- índices CORE, Asistencia, Contratos, Remuneraciones y Compras
- instaladores reproducibles
- tests estructurales y funcionales de RRHH y Compras
- validación reproducible de DW-RRHH 0.3 y DW-COMPRAS sobre PostgreSQL 16

### Estado del dominio analítico RRHH

El modelo físico del dominio analítico RRHH se considera completo en el alcance actual del Bloque 5:

```text
DW-RRHH
├── DIM_FECHA
├── DIM_AREA
├── DIM_CENTRO_COSTO
├── DIM_CARGO
├── DIM_EMPLEADO
├── DIM_TURNO
├── DIM_CONTRATO
├── FACT_ASISTENCIA
└── FACT_REMUNERACIONES
```

La disponibilidad física de estos objetos no implica que la carga ETL hacia el DW esté terminada. Esa integración corresponde al Bloque 6.

### Estado del dominio analítico Compras

El modelo físico del dominio analítico Compras se considera completo en el alcance actual del Bloque 5:

```text
DW-COMPRAS
├── DIM_FECHA          (consumida del CORE, role-playing)
├── DIM_AREA           (consumida del CORE)
├── DIM_CENTRO_COSTO   (consumida del CORE)
├── DIM_PROVEEDOR
├── DIM_INSUMO
└── FACT_COMPRAS
```

El dominio Compras reutiliza las dimensiones conformadas del CORE (`DIM_FECHA`, `DIM_AREA`, `DIM_CENTRO_COSTO`) sin recrearlas. La disponibilidad física de estos objetos no implica que la carga ETL hacia el DW esté terminada. Esa integración, incluyendo el cálculo del prorrateo de impuesto y la resolución de lookups dimensionales, corresponde al Bloque 6.

### Pendiente dentro del Bloque 5

- `DIM_PRODUCTO`
- `DIM_CUENTA_CONTABLE`
- `FACT_CONTABILIDAD`
- `FACT_PRODUCCION`
- `FACT_CONSUMO_INSUMO`

`DIM_CONTRATO` y `FACT_REMUNERACIONES` (RRHH) y `DIM_PROVEEDOR`, `DIM_INSUMO` y `FACT_COMPRAS` (Compras) ya no forman parte de los pendientes del Bloque 5.

## Próximas etapas

Después de completar las dimensiones y tablas de hechos pendientes del Bloque 5, se implementarán las cargas ETL hacia el Data Warehouse.

### Etapa posterior — Bloque 6

La carga ETL hacia las tablas `dw.*` permanece pendiente.

Para RRHH, esta etapa deberá incluir al menos:

- carga y mantenimiento de dimensiones conformadas;
- carga SCD Tipo 2 de `DIM_EMPLEADO`;
- resolución `RUT normalizado + fecha/período`;
- control explícito de solapamientos históricos;
- carga SCD Tipo 1 de `DIM_CONTRATO`;
- resolución de `contrato_key` mediante `numero_contrato`;
- resolución de `area_key`, `cargo_key` y `centro_costo_key`;
- carga de `FACT_ASISTENCIA`;
- carga de `FACT_REMUNERACIONES`;
- agregación de `DetalleLiquidacion + ConceptoPago` para obtener haberes, descuentos y aportes;
- tratamiento de miembros desconocidos;
- eventos REVIEW para casos no resolubles de forma determinística;
- carga incremental;
- idempotencia;
- reconciliaciones fuente → staging → DW;
- validación integral del dominio RRHH.

Para Compras, esta etapa deberá incluir al menos:

- carga SCD Tipo 1 de `DIM_PROVEEDOR` con normalización y validación de RUT;
- carga SCD Tipo 1 de `DIM_INSUMO`, derivando a REVIEW los cambios de `unidad_medida`;
- resolución de `proveedor_key` mediante RUT normalizado y de `insumo_key` mediante `codigo_insumo`;
- resolución de `centro_costo_key` y `area_key` mediante códigos empresariales;
- cálculo del prorrateo de impuesto y total al grano de línea, con residuo determinístico y cuadratura contra la cabecera de la OC;
- preservación de `moneda_origen` y, si corresponde, conversión a moneda de reporte;
- tratamiento de miembros desconocidos;
- eventos REVIEW para casos no resolubles de forma determinística;
- carga de `FACT_COMPRAS` respetando el grano `numero_oc + insumo_key`.

A nivel global del proyecto se implementarán además:

- lookups dimensionales para los demás dominios;
- mappings;
- controles de calidad;
- auditoría e integración de cargas;
- reconciliación entre fuentes y tablas de hechos;
- validación integral del Data Warehouse.

Una vez completada y validada la carga del DW, se preparará su consumo desde:

- Power BI;
- la aplicación analítica del proyecto.

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
9. agregar pruebas funcionales cuando existan reglas críticas que deban comprobarse por inserción;
10. validar la instalación en PostgreSQL antes de integrar cambios;
11. comprobar que las pruebas con fixtures no dejen residuos persistentes.
