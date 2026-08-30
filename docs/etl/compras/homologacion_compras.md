# Matriz de claves de negocio y homologación — Compras y Abastecimiento

**Proyecto:** Plataforma de Business Intelligence — Industrias ABC · Equipo BInnova
**Dominio:** Compras y Abastecimiento (PostgreSQL) · **Responsable:** Raymond Civil
**Etapa:** ETL Compras 0.1 — preparación para staging · **Versión:** 0.1

## Qué es la homologación

**Homologar** es reconocer que **un mismo objeto del mundo real** (un área, un
proveedor, un insumo) aparece en **varias bases operacionales** y **hacerlos
corresponder** para poder integrarlos en el Data Warehouse. Como cada fuente es
**independiente**, la correspondencia no puede basarse en los identificadores
internos: debe basarse en **claves de negocio** —atributos estables y
significativos que representan al objeto igual en todas las fuentes.

## Por qué NO se usan los IDs locales

Los IDs de cada base (`area_id`, `insumo_id`, `comprador_id`, …) se generan con
`INTEGER GENERATED ALWAYS AS IDENTITY`: **cada base numera por su cuenta, desde 1**.
Por eso:

- El `area_id = 4` de **Compras** representa "Compras y Abastecimiento", pero el
  `area_id = 4` de **RRHH** puede ser otra área completamente distinta. **Mismo
  número, objeto distinto** → cruzar por ID daría integraciones falsas.
- Además, el proyecto exige **independencia de fuentes**: no hay FK físicas entre
  bases, así que un ID de Compras **no tiene sentido** fuera de Compras.

En cambio, la **clave de negocio** es estable entre fuentes: el `codigo_area`
`A04` es "Compras y Abastecimiento" en Compras, en RRHH y en Contabilidad por
igual (viene del Universo Master). Por eso se homologa por `codigo_area`,
**no** por `area_id`.

> Regla: los IDs locales se **conservan** para trazabilidad (rastrear el registro
> hasta su fuente), pero **nunca** se usan como equivalencia entre bases.

## Matriz de claves de negocio (candidatas para homologación)

| Entidad | ID local (solo trazabilidad) | Clave de negocio candidata | Estabilidad | Uso futuro en la integración |
|---|---|---|---|---|
| Área | `area_id` | `codigo_area` | Alta (viene del Master) | Homologar áreas con RRHH y Contabilidad |
| Centro de costo | `centro_costo_id` | `codigo_centro` | Alta (viene del Master) | Homologar centros de costo empresariales (con Contabilidad) |
| Proveedor | `proveedor_id` | `rut_proveedor` | Alta (RUT es único e institucional) | Identificar al proveedor transversalmente |
| Insumo | `insumo_id` | `codigo_insumo` | Alta | Relacionar Compras con Producción (mismo insumo) |
| Categoría de insumo | `categoria_id` | `codigo_categoria` | Media/Alta | Homologar categorías de insumo si corresponde |
| Orden de compra | `oc_id` | `numero_oc` | Alta (documento formal) | Trazabilidad del documento de compra |
| Comprador | `comprador_id` | `codigo_comprador` (+ contexto) | Media | Posible homologación posterior con el trabajador de RRHH |

## Cómo funciona técnicamente (con lo visto en Clase 2)

La homologación se resuelve en el ETL con un **cruce de datos** (`JOIN`), tal como
enseña la Clase 2 ("Cruce de datos: combinación de información de distintas fuentes
mediante JOIN"). El cruce se hace **sobre la clave de negocio ya normalizada** en
staging (por eso limpiamos con `TRIM`/`UPPER`: para que `A04` y ` a04 ` crucen).

Ejemplo conceptual (etapa futura, no se implementa aún):

```sql
-- Homologar áreas de Compras con las de RRHH por clave de negocio, NO por ID
SELECT c.codigo_area,
       c.area_id      AS area_id_compras,   -- ID local (trazabilidad)
       r.area_id      AS area_id_rrhh        -- ID local del otro sistema
FROM   stg_compras_areas_limpio  c
JOIN   stg_rrhh_areas_limpio     r
       ON UPPER(TRIM(c.codigo_area)) = UPPER(TRIM(r.codigo_area));
```

## Notas de integración por concepto compartido (sin FK físicas)

- **Insumo ↔ Producción:** mismo insumo por `codigo_insumo`.
- **Centro de costo / Área ↔ Contabilidad:** por `codigo_centro` / `codigo_area`.
- **Comprador ↔ RRHH:** el comprador podrá homologarse posteriormente con el
  trabajador de RRHH mediante reglas de integración (no por ID).

## Límites de esta matriz

Estas son **claves candidatas para el trabajo ETL**, no claves del Data Warehouse.
La clave definitiva de una dimensión o tabla de hechos (clave subrogada del DW) se
decidirá cuando se diseñe el modelo dimensional. Si alguna decisión afectara el
significado de Área, Centro de costo, Insumo, Proveedor o Comprador en otras
fuentes, debe **consultarse con el equipo** antes de fijarla como regla transversal.
