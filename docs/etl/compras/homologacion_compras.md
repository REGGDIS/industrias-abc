# Matriz de claves de negocio y homologación — Compras y Abastecimiento

**Proyecto:** Plataforma de Business Intelligence — Industrias ABC · Equipo BInnova
**Dominio:** Compras y Abastecimiento (PostgreSQL) · **Responsable:** Raymond Civil
**Etapa:** ETL Compras 0.1 — preparación para staging · **Versión:** 0.1

## Qué es la homologación

**Homologar** es reconocer que **un mismo objeto del mundo real** (un área, un
proveedor, un insumo) puede aparecer en **varias bases operacionales** y hacerlos
corresponder para integrarlos más adelante en el Data Warehouse. Como cada fuente
es **independiente**, la correspondencia no puede basarse en los identificadores
internos: debe apoyarse en **claves de negocio** —atributos estables y
significativos. Esta correspondencia se **definirá y cerrará en el ETL Core**;
aquí solo se **identifican las claves candidatas** del dominio Compras.

## Por qué NO se usan los IDs locales

Los IDs de cada base (`area_id`, `insumo_id`, `comprador_id`, …) se generan con
`INTEGER GENERATED ALWAYS AS IDENTITY`: **cada base numera por su cuenta, desde 1**.
Por eso:

- El `area_id = 4` de **Compras** representa "Compras y Abastecimiento", pero el
  `area_id = 4` de **RRHH** puede ser otra área distinta. **Mismo número, objeto
  distinto** → cruzar por ID daría integraciones falsas.
- El proyecto exige **independencia de fuentes**: no hay FK físicas entre bases, y
  un ID de Compras **no tiene sentido** fuera de Compras.

Por eso la homologación se apoyará en claves de negocio y **no** en los IDs
internos. Los IDs locales se **conservan** en extracción y staging solo para
**trazabilidad** (rastrear el registro hasta su fuente), nunca como equivalencia.

## Matriz de claves de negocio (candidatas)

> Importante: estas son **claves candidatas** para la homologación. **No** se
> afirma que los códigos sean necesariamente iguales, en formato o en valor,
> entre Compras, RRHH, Contabilidad o Producción. El Universo Master v0.2 es una
> **referencia conceptual** —su propia hoja de Áreas indica que "los sistemas
> operacionales pueden utilizar códigos o nombres distintos"—, por lo que cada
> correspondencia deberá **confirmarse y cerrarse en el ETL Core** mediante reglas
> de homologación.

| Entidad | ID local (solo trazabilidad) | Clave de negocio candidata | Uso futuro (a confirmar en ETL Core) |
|---|---|---|---|
| Área | `area_id` | `codigo_area` | Homologación con áreas de RRHH y Contabilidad, si los códigos resultan comparables |
| Centro de costo | `centro_costo_id` | `codigo_centro` | Homologación de centros de costo (con Contabilidad), sujeta a confirmación |
| Proveedor | `proveedor_id` | `rut_proveedor` | Identificación del proveedor; el RUT es una referencia institucional estable |
| Insumo | `insumo_id` | `codigo_insumo` | Relación futura con Producción **por confirmar** (ver nota) |
| Categoría de insumo | `categoria_id` | `codigo_categoria` | Homologación de categorías, si corresponde |
| Orden de compra | `oc_id` | `numero_oc` | Trazabilidad interna del documento de compra |
| Comprador | `comprador_id` | `codigo_comprador` (+ contexto) | Posible homologación posterior con el trabajador de RRHH |

**Nota sobre Insumo ↔ Producción:** actualmente **Producción no cuenta con un
catálogo físico que exponga `codigo_insumo`**. Por lo tanto, la correspondencia
Compras–Producción por insumo **no puede afirmarse todavía** y deberá **cerrarse
posteriormente**, cuando exista ese catálogo o se acuerde otra clave de negocio.

## Cómo funcionaría técnicamente (referencia, no se implementa aún)

La homologación se resolvería en el ETL con un **cruce de datos** (`JOIN`), tal
como enseña la Clase 2 ("Cruce de datos mediante JOIN"), uniendo por la **clave de
negocio candidata ya normalizada** en staging (por eso limpiamos con `TRIM`/`UPPER`).
El criterio de cruce (igualdad de código, normalización, o una tabla de
equivalencias) se **definirá en el ETL Core**; el ejemplo siguiente es ilustrativo:

```sql
-- Ejemplo ILUSTRATIVO (no se implementa en esta etapa).
-- El criterio real de correspondencia lo definirá el ETL Core.
SELECT c.codigo_area,
       c.area_id  AS area_id_compras,   -- ID local (trazabilidad)
       r.area_id  AS area_id_rrhh        -- ID local del otro sistema
FROM   stg_compras_areas_limpio  c
JOIN   stg_rrhh_areas_limpio     r
       ON UPPER(TRIM(c.codigo_area)) = UPPER(TRIM(r.codigo_area));  -- regla candidata, a confirmar
```

## Integración por concepto compartido (sin FK físicas)

- **Insumo ↔ Producción:** por `codigo_insumo` **cuando exista** el catálogo
  correspondiente en Producción (hoy no está disponible; a cerrar después).
- **Centro de costo / Área ↔ Contabilidad:** por `codigo_centro` / `codigo_area`,
  sujeto a confirmación de comparabilidad.
- **Comprador ↔ RRHH:** el comprador podrá homologarse posteriormente con el
  trabajador de RRHH mediante reglas de integración (no por ID).

## Límites de esta matriz

Estas son **claves candidatas para el trabajo ETL**, no claves del Data Warehouse.
La clave definitiva de una dimensión o tabla de hechos (clave subrogada del DW) se
decidirá al diseñar el modelo dimensional. Cualquier decisión que afecte el
significado de Área, Centro de costo, Insumo, Proveedor o Comprador entre fuentes
debe **consultarse con el equipo** antes de fijarse como regla transversal.
