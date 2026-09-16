# Normalización y Estandarización — Compras 0.4

**Proyecto:** Business Intelligence — Industrias ABC (Equipo BInnova)
**Dominio:** Compras · **Responsable:** Raymond Civil
**Rama:** `feat/etl-compras-normalizacion-04` · **Base:** `develop` · **Versión:** 0.1

---

## 1. Objetivo y alcance

Estandarizar los valores controlados de Compras (moneda, estados, códigos de
negocio y textos) sobre la capa staging/CLEAN, conservando **trazabilidad**
(valor original vs valor normalizado) y clasificando cada campo como
**NORMALIZADO / LIMPIO / REVISIÓN / ERROR**, para dejar el dominio preparado
para una futura integración dimensional.

**Dentro de alcance:** `ordenes_compra`, `proveedores`, `insumos`, `recepciones`.
**Fuera de alcance (respetado):** no se construye `FACT_COMPRAS`, dimensiones,
SCD ni DW; no se modifica ETL Core, `homologation.py`, `business_keys.py`,
`rut.py`, otros dominios ni las tablas operacionales.

## 2. Fuente y capa RAW/CLEAN

Se lee de los **fixtures RAW** `stg_compras_<tabla>_raw` (poblados por la
extracción de 0.1; no forman parte del ETL Core).

⚠️ **Limitación documentada:** Compras **no tiene RAW/CLEAN materializados como
tablas persistentes**; el RAW es un *fixture* y el CLEAN es el `SELECT` de los
`limpiar_*.sql`. La normalización de 0.4 se ejecuta sobre esa misma capa, en
**solo lectura**, sin alterar la fuente operacional.

## 3. Relación con Compras 0.1 (no se duplica)

Los `limpiar_*.sql` de 0.1 **ya aplican** `TRIM`/`UPPER`. Esta iteración **no los
reescribe**: agrega lo que 0.1 no produce — la **clasificación de dominio** y la
**trazabilidad antes/después**. (Nota: 0.1 solo hacía `TRIM` en `numero_oc`; 0.4
añade además `UPPER`.)

## 4. Reglas implementadas (ancladas a `schema.sql`)

| Campo | Regla | Dominio (schema) | Estado resultante |
|---|---|---|---|
| Moneda (OC) | `TRIM+UPPER` | `CLP, USD, EUR` | NORMALIZADO / REVISIÓN |
| Estado OC | `TRIM+UPPER` | `EMITIDA,PARCIAL,RECIBIDA,CERRADA,ANULADA` | NORMALIZADO / REVISIÓN |
| Estado proveedor/insumo | `TRIM+UPPER` | `ACTIVO,INACTIVO` | NORMALIZADO / REVISIÓN |
| Estado recepción | `TRIM+UPPER` | `REGISTRADA,CONFORME,CON_DIFERENCIAS,ANULADA` | NORMALIZADO / REVISIÓN |
| `numero_oc` | `TRIM+UPPER`, no vacío | `NOT NULL/UNIQUE` | NORMALIZADO / **ERROR** |
| `codigo_insumo` | `TRIM+UPPER`, no vacío | `NOT NULL/UNIQUE` | NORMALIZADO / **ERROR** |
| Textos (`razon_social`, `nombre_insumo`) | `TRIM` | — | LIMPIO / REVISIÓN |

**Regla anti-invención:** un valor fuera de dominio (p. ej. `"CLPS"`) **no** se
convierte a `CLP`; queda **REVISIÓN** conservando su valor original y su motivo.

## 5. Trazabilidad

Cada fila del reporte conserva: `entidad`, `id_registro` (PK real), `campo`,
`valor_original` (sin tocar), `valor_normalizado` y `estado`. El original nunca
se sobrescribe, por lo que siempre se puede responder “qué tenía antes y qué
quedó”.

Ejemplo (caso controlado):

```
valor_original  = ' oc-001 '
valor_normalizado = 'OC-001'
estado = NORMALIZADO
```

## 6. Idempotencia

`valor_normalizado = UPPER(TRIM(x))` (o `TRIM(x)` en textos). Ambas son
idempotentes: `TRIM(TRIM(x)) = TRIM(x)` y `UPPER(UPPER(x)) = UPPER(x)`. Se
**demuestra ejecutando** (no solo afirmando): la prueba aplica la normalización
sobre el valor ya normalizado y comprueba que no cambia.

## 7. Salida y resultados reales (ejecutado en PostgreSQL)

### 7.1 `normalizar_compras.sql` sobre el RAW real

Resumen (el seed ya viene estandarizado, por eso 0 en revisión / 0 error; el
detalle sale vacío porque no hay nada que corregir — el motor corre sin falsos
positivos):

```
    entidad     | procesados | normalizados | en_revision | errores
----------------+------------+--------------+-------------+---------
 insumos        |         45 |           45 |           0 |       0
 ordenes_compra |         36 |           36 |           0 |       0
 proveedores    |         30 |           30 |           0 |       0
 recepciones    |          9 |            9 |           0 |       0
 TOTAL          |        120 |          120 |           0 |       0
```

Coherencia: `procesados = normalizados + en_revisión + errores` (120 = 120+0+0).

### 7.2 `test_normalizacion_compras.sql` (detección con fixtures)

**12 / 12 PASA** en `BEGIN … ROLLBACK` (no persiste nada):

```
 nro | caso                               | obt_normalizado | obt_estado  | resultado
-----+------------------------------------+-----------------+-------------+-----------
   1 | Moneda ' clp '                     | CLP             | NORMALIZADO | PASA
   5 | Número OC ' oc-001 '               | OC-001          | NORMALIZADO | PASA
   7 | Número OC vacío                    |                 | ERROR       | PASA
   9 | Moneda 'CLPS' (fuera de dominio)   | CLPS            | REVISION    | PASA
  10 | Texto '  Proveedor Sur  '          | Proveedor Sur   | LIMPIO      | PASA
```
(Idempotencia: 10/10. Trazabilidad caso 5: PASA.)

**Endurecimiento:** si algún caso no cumple, el script lanza `RAISE EXCEPTION` y
termina con código de salida **no-cero** (verificado: una expectativa rota
produce `ERROR` y exit code 3). Una prueba fallida **falla de verdad**.

## 8. Auditoría de granularidad

Cada tabla se recorre por separado a su granularidad de PK, **sin JOIN**: no se
duplican, pierden ni multiplican filas. El reporte es de formato largo (una fila
por registro-campo), derivado de recorridos de una sola tabla.

## 9. Matriz de trazabilidad

| Requisito | Regla | Tabla/Campo | Archivo | Prueba | Estado |
|---|---|---|---|---|---|
| Moneda dominio | TRIM+UPPER, {CLP,USD,EUR} | ordenes_compra.moneda | normalizar_compras.sql | P1, P9 | ✅ |
| Estados (4 dominios) | TRIM+UPPER + CHECK | OC/prov/insumo/recep.estado | idem | P2,P3,P4 | ✅ |
| numero_oc | TRIM+UPPER, no vacío | ordenes_compra.numero_oc | idem | P5,P7 | ✅ |
| codigo_insumo | TRIM+UPPER, no vacío | insumos.codigo_insumo | idem | P6,P8 | ✅ |
| Textos | TRIM, vacío→REVISIÓN | razon_social, nombre_insumo | idem | P10 | ✅ |
| Trazabilidad | original+normalizado | todas | idem | P11 | ✅ |
| Idempotencia | doble ejecución = igual | todas | test | P12 | ✅ |
| Salida CLEAN | procesados/normalizados/revisión/error | resumen | idem | 7.1 | ✅ |
| No tocar operacionales/Core/DW | solo SELECT | — | auditoría git | 🚫 respetado |

## 10. Limitaciones y notas

- **RAW/CLEAN no persistente** (§2): los fixtures RAW se generan temporalmente
  mediante `preparar_raw_compras.sql` y se consumen en la misma sesión por
  `ejecutar_normalizacion_compras.sql`.
- **NO DEFINIDO EN LA FUENTE OFICIAL:** el encargo no fija nombre/ruta exactos de
  los archivos (solo las carpetas permitidas); se adoptó el patrón SQL de Compras.
- Los textos descriptivos cubiertos son `razon_social` y `nombre_insumo` como
  representativos; se pueden ampliar si el equipo lo requiere.

## 11. Cómo ejecutar

### Ejecución completa y reproducible

El flujo recomendado prepara automáticamente los fixtures RAW temporales y
ejecuta la normalización en una misma sesión PostgreSQL:

```bash
psql "<conn>" -f etl/sql/staging/compras/ejecutar_normalizacion_compras.sql
```

`ejecutar_normalizacion_compras.sql` ejecuta en orden:

1. `preparar_raw_compras.sql`
2. `normalizar_compras.sql`

Los fixtures `stg_compras_*_raw` se crean como tablas temporales y no modifican
las tablas operacionales.

### Pruebas

```bash
psql "<conn>" -f etl/tests/compras/test_normalizacion_compras.sql
```

Las pruebas se ejecutan dentro de `BEGIN … ROLLBACK` y lanzan `RAISE EXCEPTION`
si algún caso no cumple.
