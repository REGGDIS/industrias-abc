# Estrategia y prototipo de carga incremental — Compras 0.2

**Proyecto:** Plataforma de Business Intelligence — Industrias ABC · Equipo BInnova
**Dominio:** Compras (PostgreSQL) · **Responsable:** Raymond Civil
**Etapa:** ETL Compras 0.2 — prototipo incremental · **Versión:** 0.1

## 1. Objetivo

Construir un prototipo específico y reproducible de carga incremental para Compras que
permita **identificar registros nuevos** (INSERT) y **detectar registros modificados**
(UPDATE), documentando las limitaciones de la fuente para DELETE. No se resuelve todavía
el incremental global ni se modifica el ETL Core; se deja una estrategia que el ETL Core
pueda reutilizar más adelante.

## 2. Contexto

ETL Compras 0.1 dejó preparadas la extracción, el staging, la calidad y las claves
candidatas de homologación. 0.2 avanza hacia uno de los requisitos del proyecto: disponer
de al menos un mecanismo de carga incremental, sin adelantar decisiones del Data Warehouse.

## 3. Tablas cubiertas

Prioritarias en este hito (con script): **`ordenes_compra`** y **`recepciones`**.
Analizadas para una etapa posterior (sin script en 0.2): `detalle_orden_compra` y
`detalle_recepcion` (ver §11).

## 4. Fuente física

`sources/compras-postgresql/sql/schema.sql`. Las PK de las tablas transaccionales son
`INTEGER GENERATED ALWAYS AS IDENTITY` (crecientes). **La fuente NO tiene `created_at`,
`updated_at` ni marca de borrado lógico** — esto es lo que obliga a usar snapshot para
UPDATE y deja el DELETE físico como no detectable de forma robusta.

## 5. Watermark para INSERT

Se usa la PK creciente como **watermark técnico**: se procesan solo las filas con
`oc_id > :ultimo_oc_id` (órdenes) y `recepcion_id > :ultima_recepcion_id` (recepciones),
donde el watermark es **el último ID confirmado como procesado en una ejecución anterior**.

- Archivos: `etl/sql/incremental/compras/ordenes_compra_nuevas.sql` y `recepciones_nuevas.sql`.
- **No** se usa `MAX(oc_id)` calculado dentro de la misma consulta como sustituto del
  watermark histórico: mediría la tabla contra sí misma y no distinguiría lo ya procesado.
- Como la PK es `GENERATED ALWAYS`, un INSERT de prueba genera un ID mayor y aparece en el delta.

## 6. Detección de UPDATE mediante comparación de snapshot

El watermark por PK **no** detecta cambios en filas existentes (el `oc_id` no cambia cuando
cambian estado o montos). Se compara la **fuente actual** contra un **snapshot anterior**
usando `IS DISTINCT FROM` (comparación segura ante NULL), devolviendo solo las filas que
cambiaron.

- Archivos: `detectar_cambios_ordenes.sql` y `detectar_cambios_recepciones.sql`.
- Snapshots de prueba: `tmp_compras_ordenes_snapshot_anterior` y
  `tmp_compras_recepciones_snapshot_anterior`. **Son fixtures LOCALES del prototipo; NO
  constituyen un estándar del ETL Core.**

## 7. Campos utilizados para detectar cambios

- **Órdenes:** `estado`, `fecha_requerida`, `centro_costo_id`, `comprador_id`, `moneda`,
  `subtotal`, `impuesto`, `total` (todos los campos que una orden puede cambiar, Informe §9).
- **Recepciones:** `fecha_recepcion`, `estado`.

## 8. Tratamiento de DELETE

El esquema **no** tiene marca de borrado lógico ni fecha de eliminación. Por lo tanto:
**el watermark por PK NO permite detectar de manera robusta un DELETE físico.** Como
alternativa **conceptual/provisional** se podría comparar el conjunto de PK del snapshot
anterior contra la fuente actual (las PK ausentes serían candidatas a borrado), pero:

- requiere conservar el snapshot completo;
- es más costoso;
- **no equivale** a disponer de una marca de borrado confiable en la fuente.

No se afirma que el DELETE físico sea detectable de forma robusta con el modelo actual.

## 9. Limitaciones

- El watermark por PK cubre **solo INSERT**.
- El UPDATE depende de **conservar un snapshot anterior**.
- El DELETE físico **no** es detectable de forma confiable (ver §8).
- Los IDs son **locales** (`GENERATED ALWAYS`); no son clave de negocio global.

## 10. Persistencia futura del watermark

En 0.2 el watermark es un **parámetro/valor documentado** (ej. `ultimo_oc_id = 12`,
`ultima_recepcion_id = 9`). **No** se crea una tabla común de control. Posteriormente, el
**ETL Core** deberá persistir estos valores por **fuente, entidad y ejecución**.

## 11. Integración futura con ETL Core y tablas de detalle

- **ETL Core** estandarizará: persistencia de watermarks, gestión de snapshots, auditoría
  y control de deltas entre fuentes.
- **`detalle_orden_compra`** (`detalle_id`, `oc_id`, `insumo_id`, `cantidad`,
  `precio_unitario`, `descuento`, `subtotal`) y **`detalle_recepcion`**
  (`detalle_recepcion_id`, `recepcion_id`, `detalle_id`, `cantidad_recibida`,
  `cantidad_rechazada`, `estado`): sus PK identity permitirían detectar **INSERT** igual
  que órdenes/recepciones; sus **UPDATE** requerirían snapshot (cantidades, precio,
  descuento, subtotal, estado pueden cambiar sin PK nueva). Dependen de orden/recepción
  por FK, por lo que su incremental debe procesarse **después** del de sus cabeceras.

## 12. Riesgos

- Confundir la PK local con una clave de negocio global (no hacerlo).
- Asumir que el watermark detecta UPDATE (no lo hace).
- Forzar estados imposibles en las pruebas (respetar dominios y triggers).
- Presentar el nombre del snapshot como estándar del Core (es local al prototipo).

## 13. Decisiones pendientes (para el equipo / ETL Core)

- Dónde y cómo persistir los watermarks (tabla común de control).
- Cómo estandarizar y conservar los snapshots.
- Si se adoptará una estrategia de detección de DELETE (y con qué costo).
- Qué campos adicionales se comparan en el UPDATE definitivo.

## 14. Pruebas realizadas

Archivo `etl/tests/compras/validacion_incremental_compras.sql`, ejecutado en PostgreSQL,
todo dentro de `BEGIN … ROLLBACK` con tablas `TEMP` (sin alterar el seed):

1. INSERT de órdenes (watermark por `oc_id`).
2. INSERT de recepciones (watermark por `recepcion_id`).
3. UPDATE de órdenes (snapshot).
4. UPDATE de recepciones (snapshot).

## 15. Evidencias (PRUEBA EJECUTADA)

```
Línea base: MAX(oc_id)=12 (12 órdenes) · MAX(recepcion_id)=9 (9 recepciones)

Prueba 1 · INSERT órdenes    → wm=12; INSERT → aparece SOLO oc_id 13; wm al día → 0 filas.
Prueba 2 · INSERT recepciones→ wm=9;  INSERT → aparece SOLO recepcion_id 10.
Prueba 3 · UPDATE órdenes    → oc 6 EMITIDA→PARCIAL → aparece SOLO oc 6 (sin cambios excluidos).
Prueba 4 · UPDATE recepciones→ rec 1 CONFORME→CON_DIFERENCIAS → aparece SOLO recepcion 1.

Seguridad de datos: conteo ANTES = DESPUÉS (12 órdenes, 9 recepciones) → el seed NO se modificó.
```

## 16. Conclusiones

El prototipo demuestra, con evidencia reproducible, la detección de **INSERT por watermark**
y de **UPDATE por comparación de snapshot** para órdenes y recepciones, y documenta que el
**DELETE físico no es detectable de forma robusta** con la fuente actual. Queda preparado
el camino para que el **ETL Core** defina la persistencia común de watermarks, snapshots,
auditoría y control de deltas.

---

## Matriz de trazabilidad

| Requisito | Fuente | Archivo que lo implementa | Prueba | Evidencia | Estado |
|---|---|---|---|---|---|
| Detectar nuevas órdenes | Informe 0.2 §3, §7 | `ordenes_compra_nuevas.sql` | validación · Prueba 1 | oc 13 con wm=12; 0 con wm al día | OK |
| Detectar nuevas recepciones | Informe 0.2 §3, §8 | `recepciones_nuevas.sql` | validación · Prueba 2 | recepcion 10 con wm=9 | OK |
| Detectar cambios en órdenes | Informe 0.2 §9, §10 | `detectar_cambios_ordenes.sql` | validación · Prueba 3 | oc 6 EMITIDA→PARCIAL | OK |
| Detectar cambios en recepciones | Informe 0.2 §11 | `detectar_cambios_recepciones.sql` | validación · Prueba 4 | rec 1 CONFORME→CON_DIFERENCIAS | OK |
| No alterar el seed | Informe 0.2 §16–§19 | `validacion_incremental_compras.sql` | conteo antes/después | 12/9 = 12/9 | OK |
| Limitación de DELETE | Informe 0.2 §13 | este documento (§8) | — | limitación documentada | OK (documentado) |
| Persistencia del watermark | Informe 0.2 §15, §16 | este documento (§10) | — | pendiente | PENDIENTE (ETL Core) |

## Lo que funciona hoy vs lo que queda para ETL Core

| Funciona hoy (0.2) | Queda para ETL Core |
|---|---|
| INSERT por watermark (parámetro) | Persistir el watermark por fuente/entidad/ejecución |
| UPDATE por snapshot local + `IS DISTINCT FROM` | Estandarizar y conservar snapshots |
| Pruebas reproducibles sin tocar el seed | Estrategia común de detección de DELETE |
| Estrategia documentada para las 2 tablas cabecera | Incremental de detalles y de otras fuentes |
