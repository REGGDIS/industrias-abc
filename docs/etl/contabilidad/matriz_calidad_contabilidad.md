# Matriz de calidad de datos — Contabilidad

**Proyecto:** Plataforma de Business Intelligence — Industrias ABC · Equipo BInnova
**Dominio:** Contabilidad (PostgreSQL) · **Responsable:** Raymond Civil
**Etapa:** ETL Contabilidad 0.1 — preparación para staging · **Versión:** 0.1

## Propósito

Esta matriz documenta las reglas que permiten distinguir, durante el ETL, entre
registros **válidos**, **advertencias** y **errores** en el dominio de Contabilidad.
Las reglas se **derivan de la fuente física real** (`sources/contabilidad-postgresql/sql/schema.sql`)
y de los controles de `sources/contabilidad-postgresql/sql/validaciones.sql`; no se
inventan reglas de negocio nuevas. Sirve para que el ETL Core sepa qué controlar al
extraer, limpiar y cargar Contabilidad.

## Convención de severidad

| Severidad | Significado | Acción en el ETL |
|---|---|---|
| **ERROR** | Viola la integridad del modelo. El dato no puede cargarse tal cual. | Rechazar el registro y dejarlo identificable para revisión (no descartar en silencio). |
| **ADVERTENCIA** | No rompe la integridad, pero requiere limpieza o revisión. | Limpiar en staging y/o marcar; el registro sigue. |

> Casi todas las reglas ERROR ya están garantizadas en la base por `CHECK`, `UNIQUE`,
> `FK` o `NOT NULL`; se listan igual porque el ETL debe preverlas al recibir datos de
> cualquier origen. La **cuadratura global** es una regla de negocio contable que se
> verifica por consulta.

## Matriz por entidad

| Entidad | Campo / regla | Validación | Severidad | Dónde se controla (origen) |
|---|---|---|---|---|
| areas | `codigo_area` | Obligatorio y único | ERROR | `uq_areas_codigo_area` (schema) |
| areas | `area_id`, `codigo_area`, `nombre_area` | No nulos | ERROR | `NOT NULL` (schema) |
| centros_costo | `codigo` | Obligatorio y único | ERROR | `uq_centros_costo_codigo` |
| centros_costo | `area_id` | Relación 1:1 área–centro (un centro por área) | ERROR | `uq_centros_costo_area_id` |
| centros_costo | `area_id` | Debe referenciar un área existente | ERROR | `fk_centros_costo_areas` |
| centros_costo | `estado` | Dominio {ACTIVO, INACTIVO} | ERROR | `chk_centros_costo_estado` |
| centros_costo | obligatorios (`codigo,nombre,area_id,estado`) | No nulos | ERROR | `NOT NULL` |
| centros_costo | Área sin centro de costo | 0 filas en el universo actual | ERROR | `validaciones.sql` §4.4 |
| cuentas_contables | `codigo_cuenta` | Obligatorio y único | ERROR | `uq_cuentas_contables_codigo` |
| cuentas_contables | `cuenta_padre_id` | Si existe, debe apuntar a una cuenta válida | ERROR | `fk_cuentas_contables_padre` + `validaciones.sql` §5.1 |
| cuentas_contables | `nivel` | Mayor que 0 | ERROR | `chk_cuentas_contables_nivel` |
| cuentas_contables | `estado` | Dominio {ACTIVA, INACTIVA} | ERROR | `chk_cuentas_contables_estado` |
| cuentas_contables | obligatorios (`codigo_cuenta,nombre_cuenta,tipo_cuenta,grupo,nivel,estado`) | No nulos | ERROR | `NOT NULL` |
| movimientos_contables | `cuenta_id` | Debe referenciar una cuenta existente | ERROR | `fk_movimientos_cuentas` + `validaciones.sql` §4.1 |
| movimientos_contables | `centro_costo_id` | Debe referenciar un centro existente | ERROR | `fk_movimientos_centros_costo` + `validaciones.sql` §4.2 |
| movimientos_contables | `debe`, `haber` | No negativos | ERROR | `chk_movimientos_debe_no_negativo`, `chk_movimientos_haber_no_negativo` |
| movimientos_contables | `debe`/`haber` | Exactamente uno positivo (no ambos 0, no ambos > 0) | ERROR | `chk_movimientos_debe_haber_exclusivo` |
| movimientos_contables | `tipo_cambio` | Mayor que 0 | ERROR | `chk_movimientos_tipo_cambio` |
| movimientos_contables | obligatorios (`fecha,cuenta_id,centro_costo_id,documento_tipo,documento_numero,descripcion,debe,haber,moneda,tipo_cambio`) | No nulos | ERROR | `NOT NULL` |
| movimientos_contables | Cuadratura global | Σ(debe) − Σ(haber) = 0 | ERROR (según dato) | `validaciones.sql` §6.2 |

## Controles ejecutables (de `validaciones.sql`) — deben devolver 0 filas

| Control | Qué detecta | Sección |
|---|---|---|
| Duplicados de código | `codigo_area`, `codigo` (centros), `codigo_cuenta` repetidos | §2 |
| Nulos obligatorios | Campos NOT NULL vacíos en las 4 tablas | §3 |
| Huérfanos de movimientos | Movimientos con cuenta o centro inexistente | §4.1, §4.2 |
| Relación área–centro | Áreas sin centro / con más de un centro | §4.4, §4.5 |
| Jerarquía de cuentas | Cuenta hija con `cuenta_padre_id` inexistente | §5.1 |
| Movimientos inválidos | `debe/haber` negativos, ambos 0, ambos > 0, o `tipo_cambio ≤ 0` | §6.1 |
| Cuadratura global | Σ(debe) vs Σ(haber) | §6.2 |

## Evidencia ejecutada (PostgreSQL) — PRUEBA EJECUTADA

Ejecutado contra la base de Contabilidad (`schema.sql` + `seed.sql`):

```
Conteos:  areas=7 · centros_costo=7 · cuentas_contables=24 · movimientos_contables=10
Duplicados (codigo_area / codigo / codigo_cuenta) ......... 0 / 0 / 0
Nulos obligatorios ........................................ 0
Huérfanos (mov→cuenta / mov→centro) ....................... 0 / 0
Áreas con >1 centro / áreas sin centro .................... 0 / 0
Cuenta padre inexistente / nivel ≤ 0 ...................... 0 / 0
Movimientos inválidos (Debe/Haber/tipo_cambio) ........... 0
Cuadratura global: Σdebe = 26.950.000,00  Σhaber = 26.950.000,00  diferencia = 0  → CUADRADO
```

Todos los controles obligatorios devuelven 0 y el libro cuadra. (Las pruebas sobre los
scripts de extracción y staging se registran en el PR como evidencia adicional.)

## Reglas de limpieza aplicadas en staging (relación con la calidad)

| Regla | Transformación | Motivo de calidad |
|---|---|---|
| Espacios sobrantes en texto/códigos | `TRIM(...)` | Evitar que `" 1101"` y `"1101"` se traten como distintos |
| Mayúsculas/minúsculas mixtas | `UPPER(...)` en códigos, estados y moneda | Normalizar para comparación y homologación |
| Cadenas vacías en campos opcionales | `NULLIF(..., '')` (ej. `responsable`) | Distinguir "sin dato" (NULL) de texto en blanco |
| Estabilizar tipos | `CAST(...)` solo cuando el RAW llega como texto | Asegurar fechas/numéricos correctos antes de cargar |

> La limpieza **no** altera la semántica contable: `debe`, `haber` y `tipo_cambio` se
> mantienen numéricos (sin redondear ni convertir moneda) y `cuenta_padre_id` se conserva
> (no se reconstruye la jerarquía).

## Alcance

Esta matriz cubre las reglas del **dominio operacional de Contabilidad**. No define
reglas del Data Warehouse ni de dimensiones/hechos (etapa posterior). Los dominios de
estado son exactamente los del `schema.sql`: `centros_costo` **ACTIVO/INACTIVO** y
`cuentas_contables` **ACTIVA/INACTIVA**.
