# Matriz de calidad de datos — Compras y Abastecimiento

**Proyecto:** Plataforma de Business Intelligence — Industrias ABC · Equipo BInnova
**Dominio:** Compras y Abastecimiento (PostgreSQL) · **Responsable:** Raymond Civil
**Etapa:** ETL Compras 0.1 — preparación para staging · **Versión:** 0.1

## Propósito

Esta matriz documenta las reglas que permiten distinguir, durante el ETL, entre
registros **válidos**, **advertencias** y **errores** en el dominio de Compras.
Las reglas se **derivan del Modelo Lógico / ERD y de la implementación real**
(`schema.sql`, `validaciones.sql`); no se inventan reglas de negocio nuevas.
Sirve para que el ETL Core sepa qué controlar al extraer, limpiar y cargar Compras.

## Convención de severidad

| Severidad | Significado | Acción en el ETL |
|---|---|---|
| **ERROR** | Viola la integridad del modelo. El dato no puede cargarse tal cual. | Rechazar el registro y dejarlo identificable para revisión (no descartar en silencio). |
| **ADVERTENCIA** | No rompe la integridad, pero requiere limpieza o revisión (sobre todo para homologación). | Limpiar en staging y/o marcar para revisión; el registro sigue. |

> Nota: casi todas las reglas ERROR ya están **garantizadas en la base** por
> `CHECK`, `UNIQUE`, `FK` o `TRIGGER`; se listan igual porque el ETL debe
> preverlas al recibir datos de cualquier origen (ej. cargas futuras vía CSV).

## Matriz por entidad

| Entidad | Campo / regla | Validación | Severidad | Dónde se controla (origen) |
|---|---|---|---|---|
| Áreas | `codigo_area` | Obligatorio y único | ERROR | `uq_areas_codigo` (schema) |
| Áreas | `nombre_area` | No vacío; limpiar espacios/formato | ADVERTENCIA | Modelo lógico + limpieza staging |
| Centros de costo | `codigo_centro` | Obligatorio y único | ERROR | `uq_centros_costo_codigo` |
| Centros de costo | `area_id` | Relación Área–Centro 1:1 (un centro por área) | ERROR | `uq_centros_costo_area` + `fk_centros_costo_area` |
| Centros de costo | `estado` | Dominio {ACTIVO, INACTIVO} | ERROR | `ck_centros_costo_estado` |
| Compradores | `codigo_comprador` | Obligatorio y único | ERROR | `uq_compradores_codigo` |
| Compradores | `estado` | Dominio {ACTIVO, INACTIVO} | ERROR | `ck_compradores_estado` |
| Proveedores | `rut_proveedor` | Obligatorio y único | ERROR | `uq_proveedores_rut` |
| Proveedores | `rut_proveedor` | Formato heterogéneo (puntos/guion) a revisar para homologación | ADVERTENCIA | `validaciones.sql` B2 |
| Proveedores | `razon_social` | No vacía; limpiar espacios y normalizar mayúsculas | ADVERTENCIA | Modelo lógico + limpieza staging |
| Proveedores | `estado` | Dominio {ACTIVO, INACTIVO} | ERROR | `ck_proveedores_estado` |
| Categorías de insumo | `codigo_categoria` | Obligatorio y único | ERROR | `uq_categorias_insumo_codigo` |
| Insumos | `codigo_insumo` | Obligatorio y único | ERROR | `uq_insumos_codigo` |
| Insumos | `categoria_id` | Debe existir como categoría válida | ERROR | `fk_insumos_categoria` |
| Insumos | `stock_minimo` | Mayor o igual que 0 | ERROR | `ck_insumos_stock` |
| Insumos | `estado` | Dominio {ACTIVO, INACTIVO} | ERROR | `ck_insumos_estado` |
| Órdenes de compra | `numero_oc` | Obligatorio y único | ERROR | `uq_ordenes_compra_numero` |
| Órdenes de compra | `proveedor_id` / `centro_costo_id` / `comprador_id` | Deben existir (referencias internas válidas) | ERROR | `fk_ordenes_compra_*` |
| Órdenes de compra | `fecha_requerida` | Si existe, debe ser >= `fecha_emision` | ERROR | `ck_ordenes_compra_fecha` + `validaciones.sql` B3 |
| Órdenes de compra | `moneda` | Dominio {CLP, USD, EUR} | ERROR | `ck_ordenes_compra_moneda` |
| Órdenes de compra | `subtotal`, `impuesto`, `total` | No negativos | ERROR | `ck_ordenes_compra_montos` |
| Órdenes de compra | `total` | Coherencia total = subtotal + impuesto (IVA 19%) | ERROR | `validaciones.sql` B7 |
| Órdenes de compra | `estado` | Dominio {EMITIDA, PARCIAL, RECIBIDA, CERRADA, ANULADA} | ERROR | `ck_ordenes_compra_estado` |
| Detalle OC | `oc_id` + `insumo_id` | Un insumo no se repite en la misma orden | ERROR | `uq_detalle_oc_insumo` |
| Detalle OC | `cantidad` | Mayor que 0 | ERROR | `ck_detalle_oc_cantidad` |
| Detalle OC | `precio_unitario`, `descuento`, `subtotal` | Mayores o iguales que 0 | ERROR | `ck_detalle_oc_precio/descuento/subtotal` |
| Detalle OC | `subtotal` | Coherencia = cantidad × precio − descuento | ERROR | `validaciones.sql` B6 |
| Recepciones | `oc_id` | Debe existir la orden | ERROR | `fk_recepciones_orden` |
| Recepciones | `fecha_recepcion` | No anterior a `fecha_emision` de la orden | ERROR | trigger `fn_recepcion_fecha` + `validaciones.sql` B4 |
| Recepciones | `estado` | Dominio {REGISTRADA, CONFORME, CON_DIFERENCIAS, ANULADA} | ERROR | `ck_recepciones_estado` |
| Detalle recepción | `recepcion_id` + `detalle_id` | No duplicar la línea dentro de una recepción | ERROR | `uq_detrec_recepcion_detalle` |
| Detalle recepción | `cantidad_recibida`, `cantidad_rechazada` | No negativas | ERROR | `ck_detrec_recibida` / `ck_detrec_rechazada` |
| Detalle recepción | recibido + rechazado por línea | No superar la cantidad solicitada (recepción acumulada) | ERROR | trigger de recepción acumulada + `validaciones.sql` B5 |
| Detalle recepción | `detalle_id` | La línea debe pertenecer a la misma OC de la recepción | ERROR | trigger + `validaciones.sql` B8 |
| Detalle recepción | `estado` | Dominio {OK, PARCIAL, RECHAZADO} | ERROR | `ck_detrec_estado` |

## Controles ejecutables (de `validaciones.sql`)

Estos controles **deben devolver 0 filas**; si devuelven filas, hay un problema de calidad:

| Control | Qué detecta |
|---|---|
| B1 | Proveedores duplicados por RUT exacto |
| B2 | Mismo proveedor con RUT en formatos distintos (revisar para homologación) |
| B3 | Órdenes con `fecha_requerida` anterior a la emisión |
| B4 | Recepciones con fecha anterior a la emisión de la orden |
| B5 | Recepción acumulada de una línea que supera lo solicitado |
| B6 | Inconsistencia del subtotal de línea (cantidad × precio − descuento) |
| B7 | Inconsistencia de cabecera (total ≠ subtotal + impuesto, IVA 19%) |
| B8 | Detalle de recepción apuntando a una línea de otra orden |

## Reglas de limpieza aplicadas en staging (relación con la calidad)

| Regla | Transformación | Motivo de calidad |
|---|---|---|
| Espacios sobrantes en texto | `TRIM(...)` | Evitar que `" ACERO"` y `"ACERO"` se traten como distintos |
| Mayúsculas/minúsculas mixtas | `UPPER(...)` | Normalizar para comparación y homologación |
| Cadenas vacías en campos opcionales | `NULLIF(..., '')` | Distinguir "sin dato" (NULL) de texto en blanco |
| Tipos inconsistentes (fechas/montos) | `CAST(...)` | Asegurar tipo correcto antes de cargar |

## Alcance

Esta matriz cubre las reglas del **dominio operacional de Compras**. No define
reglas del Data Warehouse ni de dimensiones/hechos (etapa posterior). Los
`estado` y dominios corresponden exactamente a los confirmados por el equipo en
el Modelo Lógico v0.1 y `schema.sql`.
