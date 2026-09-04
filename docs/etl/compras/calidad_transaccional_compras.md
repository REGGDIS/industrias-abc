# Calidad de Datos Transaccional — Compras (ETL 0.3)

**Proyecto:** Business Intelligence — Industrias ABC (Equipo BInnova)
**Dominio:** Compras · **Responsable:** Raymond Civil
**Rama:** `feat/etl-compras-calidad-03` · **Base:** `develop` · **Versión:** 0.1

---

## 1. Objetivo y alcance

Implementar controles de **calidad de datos transaccional** sobre las tablas de
Compras (`ordenes_compra`, `detalle_orden_compra`, `recepciones`,
`detalle_recepcion`) para dejar el dominio confiable de cara a una futura
`FACT_COMPRAS`.

**Dentro de alcance:** validación de cantidades, precios, descuentos, subtotales,
coherencia de cabecera, referencias huérfanas y comparación solicitado vs
recibido; un resumen `procesados / válidos / errores` y el detalle por registro
(id + regla + severidad); pruebas reproducibles.

**Fuera de alcance (respetado):** no se crean hechos ni dimensiones, no se toca
el ETL Core (`etl/transform/homologation.py`, `etl/transform/business_keys.py`),
ni `data-warehouse/`, ni otros dominios, ni las tablas operacionales.

---

## 2. Reglas implementadas

Todas las fórmulas están **ancladas al modelo real** (`schema.sql` y
`validaciones.sql`); no se inventó ningún criterio.

| # | Regla (código) | Criterio real | Severidad | Origen |
|---|---|---|---|---|
| R01 | `CANTIDAD_POSITIVA` | `cantidad > 0` | ERROR | `ck_detalle_oc_cantidad` |
| R02 | `PRECIO_NO_NEGATIVO` | `precio_unitario >= 0` | ERROR | `ck_detalle_oc_precio` |
| R03 | `DESCUENTO_NO_NEGATIVO` | `descuento >= 0` | ERROR | `ck_detalle_oc_descuento` |
| R04 | `SUBTOTAL_LINEA_COHERENTE` | `subtotal = ROUND(cantidad*precio_unitario − descuento, 2)` | ERROR | B6 / `fn_detalle_oc_subtotal` |
| R05 | `DETALLE_PERTENECE_ORDEN` | `oc_id` existe en `ordenes_compra` | ERROR | `fk_detalle_oc_orden` |
| R06 | `INSUMO_EXISTE` | `insumo_id` existe en `insumos` | ERROR | `fk_detalle_oc_insumo` |
| R07 | `PROVEEDOR_VALIDO` | `proveedor_id` existe en `proveedores` | ERROR | `fk_ordenes_compra_proveedor` |
| R08 | `CABECERA_COHERENTE` | `total = subtotal + impuesto` y `impuesto = ROUND(subtotal*0.19, 2)` | REVISIÓN | B7 |
| R09a | `RECEPCION_SIN_ORDEN` | `recepciones.oc_id` existe en `ordenes_compra` | ERROR | `fk_recepciones_orden` |
| R09b | `DETREC_SIN_RECEPCION` | `detalle_recepcion.recepcion_id` existe | ERROR | `fk_detrec_recepcion` |
| R09c | `DETREC_SIN_DETALLE` | `detalle_recepcion.detalle_id` existe | ERROR | `fk_detrec_detalle` |
| R09d | `DETREC_LINEA_OTRA_ORDEN` | la recepción y la línea pertenecen a la misma OC | ERROR | B8 / `fn_detrec_valida` |
| R10 | `SOLICITADO_VS_RECIBIDO` | por `detalle_id`: `SUM(cantidad_recibida + cantidad_rechazada)` vs `cantidad` | REVISIÓN | B5 / C7 |

**Vocabulario de severidad:** `ERROR` = incumple una regla dura, bloquea el
registro para el DW; `REVISIÓN` = diferencia legítima que el equipo debe revisar
(por ejemplo, una recepción parcial pendiente), no bloquea.

---

## 3. Capa de datos y limitación (RAW / CLEAN)

**Hallazgo documentado:** el dominio Compras **no tiene capas RAW/CLEAN
materializadas como tablas**. La extracción (0.1) y el staging (`limpiar_*.sql`)
producen el CLEAN como **consultas** sobre *fixtures* temporales, no como tablas
persistidas. Por eso las validaciones de 0.3 se ejecutan sobre la **fuente
operacional real** (mismo criterio que `validaciones.sql`).

**Consecuencia esperada:** como el esquema operacional ya impone estas reglas por
`CHECK` / `FK` / `TRIGGER`, sobre los datos del *seed* las validaciones devuelven
**0 errores** — no porque no validen, sino porque el dato ya está saneado. La
detección se demuestra en la capa de staging (ver §5, pruebas), que es justo
donde el ETL recibirá datos crudos sin esas restricciones.

---

## 4. Regla anti-multiplicación

La comparación solicitado vs recibido **agrega las recepciones por `detalle_id`
en una subconsulta ANTES** de unirlas al detalle de la orden. Así la cantidad
solicitada se lee una sola vez por línea y ningún `JOIN` la multiplica.

Evidencia con una línea que tiene 2 recepciones (5 + 4) sobre un solicitado de 12:

| método | solicitado reportado |
|---|---|
| `MAL_join_directo` (une y luego suma) | **24** ← inflado ×2 |
| `BIEN_agrega_antes` (agrega y luego une) | **12** ← correcto |

---

## 5. Resultados de ejecución (evidencia real)

### 5.1 Validación sobre el *seed* real (`validaciones_calidad_compras.sql`)

Detalle de incidencias:

```
       entidad        | id_registro |         regla          | severidad |                      motivo
----------------------+-------------+------------------------+-----------+--------------------------------------------------
 detalle_orden_compra |           6 | SOLICITADO_VS_RECIBIDO | REVISION  | solicitado=300.00 recepcionado=220.00 (FALTANTE)
 detalle_orden_compra |          13 | SOLICITADO_VS_RECIBIDO | REVISION  | solicitado=800.00 recepcionado=500.00 (FALTANTE)
```

Resumen:

```
       entidad        | procesados | validos | en_revision | con_error
----------------------+------------+---------+-------------+-----------
 detalle_orden_compra |         19 |      17 |           2 |         0
 detalle_recepcion    |         15 |      15 |           0 |         0
 ordenes_compra       |         12 |      12 |           0 |         0
 recepciones          |          9 |       9 |           0 |         0
 TOTAL                |         55 |      53 |           2 |         0
```

Lectura: **0 errores** (dato operacional limpio) y **2 en revisión** legítimos —
las líneas 6 y 13 tienen recepción parcial (pendiente), no un error.

### 5.2 Pruebas de detección (`test_calidad_compras.sql`)

**18 / 18 casos PASA** (12 casos núcleo + subcasos de recepción + control +
anti-multiplicación), todo dentro de `BEGIN … ROLLBACK` sobre tablas `TEMP`
(no persiste ningún cambio):

```
 total_casos | pasa | falla
-------------+------+-------
          18 |   18 |     0
```

---

## 6. Matriz de trazabilidad (requisito → archivo → prueba)

| Requisito del encargo | Archivo | Prueba | Estado |
|---|---|---|---|
| Cantidad > 0 | `validaciones_calidad_compras.sql` (R01) | test caso 2 | ✅ PASA |
| Precio ≥ 0 | idem (R02) | caso 3 | ✅ PASA |
| Descuento ≥ 0 | idem (R03) | caso 4 | ✅ PASA |
| Subtotal coherente | idem (R04) | caso 5 | ✅ PASA |
| Cabecera coherente | idem (R08) | caso 6 | ✅ PASA |
| Proveedor válido | idem (R07) | caso 7 | ✅ PASA |
| Detalle pertenece a orden | idem (R05) | caso 8 | ✅ PASA |
| Insumo existe | idem (R06) | caso 9 | ✅ PASA |
| Recepción sin huérfanas | idem (R09a–d) | caso 10 (4 sub) | ✅ PASA |
| Solicitado vs recibido | idem (R10) | casos 11, 12, control | ✅ PASA |
| JOIN no multiplica cantidades | idem (subconsulta) | caso 14 anti-mult | ✅ PASA |
| Resumen procesados/válidos/errores | idem (bloque 2) | ejecución 5.1 | ✅ |

---

## 7. Reutilización y no duplicación

Se reutiliza la lógica ya validada por el equipo en
`sources/compras-postgresql/sql/validaciones.sql`: **B6** (subtotal de línea),
**B7** (cabecera / IVA 19%), **B5** (recepción acumulada) y **B8** (línea de otra
orden). El aporte de 0.3 es **consolidarlas** en una salida de calidad con
severidad, resumen y detalle por registro, más las pruebas reproducibles — sin
duplicar ni reescribir el criterio.

---

## 8. Limitaciones y notas

- **NO DEFINIDO EN LA FUENTE OFICIAL:** el encargo no fija ruta/nombre exactos de
  los archivos de validación (solo las carpetas permitidas). Se adoptó el patrón
  SQL de Compras en `etl/validate/compras/`.
- Las reglas de existencia (R05, R06, R07, R09) sobre la fuente operacional no
  pueden encontrar huérfanos reales porque las `FK RESTRICT` los impiden; se
  incluyen porque el ETL Core recibirá datos de capas **sin** esas FK, donde sí
  son necesarias. Su detección queda probada en staging (§5.2).
- La regla R10 solo evalúa líneas que **ya tienen** recepciones; una línea sin
  recepciones está "pendiente" y es un estado legítimo, por lo que no se marca.

---

## 9. Cómo ejecutar

```bash
# Validación sobre la base de Compras
psql "<conn>" -f etl/validate/compras/validaciones_calidad_compras.sql

# Pruebas de detección (no persiste cambios)
psql "<conn>" -f etl/tests/compras/test_calidad_compras.sql
```
