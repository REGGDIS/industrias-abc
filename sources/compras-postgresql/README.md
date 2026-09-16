# Sistema Operacional de Compras y Abastecimiento

Proyecto de Business Intelligence — Industrias ABC · Equipo BInnova
Módulo BUSINESS INTELLIGENCE · ISI802_83-0-2026-081-PRE

| | |
|---|---|
| **Responsable** | Raymond Civil |
| **Dominio** | Compras y Abastecimiento |
| **Motor** | PostgreSQL |
| **Rama** | `feature/compras` |
| **Estado** | Base operacional implementada y validada localmente (PostgreSQL 16) |

## Propósito

Fuente operacional (OLTP) que gestiona **proveedores, insumos, órdenes de compra con su detalle, y recepciones** de Industrias ABC. Registra el gasto de compras, la imputación a centros de costo, el comprador responsable y el cumplimiento de proveedores, para alimentar posteriormente el proceso BI (staging, ETL, Data Warehouse). Es una fuente **independiente**: no tiene claves foráneas físicas hacia otros dominios (RRHH, Producción, Contabilidad); esas integraciones se resuelven después por homologación.

## Estructura

```
sources/compras-postgresql/
├── README.md
└── sql/
    ├── schema.sql        # 10 tablas (3NF), PK IDENTITY, FK RESTRICT, CHECK/UNIQUE, índices y triggers
    ├── seed.sql          # datos de prueba coherentes con el Universo Master v0.2
    └── validaciones.sql  # controles de integridad + consultas analíticas del Trabajo v2
```

Tablas: `areas`, `centros_costo`, `compradores`, `proveedores`, `categorias_insumo`, `insumos`, `ordenes_compra`, `detalle_orden_compra`, `recepciones`, `detalle_recepcion`.

## Cómo ejecutar (local)

Requiere PostgreSQL. Crear la base y ejecutar los scripts en orden:

```bash
createdb compras_abc
psql -v ON_ERROR_STOP=1 -d compras_abc -f sql/schema.sql
psql -v ON_ERROR_STOP=1 -d compras_abc -f sql/seed.sql
psql -d compras_abc -f sql/validaciones.sql
```

En **pgAdmin**: crear la base `compras_abc`, abrir el Query Tool y ejecutar `schema.sql`, luego `seed.sql`, luego `validaciones.sql`.

## Reglas de integridad implementadas

- **PK** con `INTEGER GENERATED ALWAYS AS IDENTITY`; **FK** solo internas al dominio, todas `ON DELETE RESTRICT` (se preserva la trazabilidad histórica; las bajas se manejan por `estado`).
- **CHECK** de dominios (`estado`, `moneda`), montos ≥ 0, cantidad > 0 y fechas coherentes.
- **UNIQUE** compuestos: un insumo una sola vez por orden; una línea una sola vez por recepción.
- **Triggers**: subtotal de línea derivado; fecha de recepción ≥ emisión; y recepción acumulada (recibido + rechazado) ≤ cantidad solicitada por línea.

## Estado de validación (ejecutado en PostgreSQL 16)

- Carga sin errores: 7 áreas, 7 centros de costo, 4 compradores, 15 proveedores, 8 categorías, 15 insumos, 12 órdenes, 19 líneas, 9 recepciones, 15 detalles de recepción.
- Todos los controles de integridad (B1–B8 de `validaciones.sql`) devuelven **0 filas**.
- Pruebas negativas confirmadas: se rechaza la recepción que excede lo solicitado, la fecha de recepción anterior a la emisión y el insumo duplicado en una orden.

## Estado de aprobación

- Modelo Lógico / ERD v0.1 **aprobado** por el equipo (revisión de Roberto) para comenzar `schema.sql`.
- **Dominios de estado confirmados** (`ordenes_compra` y `recepciones`).
- Listo para subir a `feature/compras` y abrir PR hacia `develop` (ver `pasos-git-compras.md`).

## Nota de alcance — tabla `areas`

El Trabajo v2 (§7.2) define para `areas` los campos `gerencia` y `centro_costo_id`. En esta fuente operacional de Compras, `areas` es una tabla de **referencia local mínima** (`area_id`, `codigo_area`, `nombre_area`):

- **`gerencia` se omite intencionalmente.** El dato existe en el Universo Master v0.2 (hoja `Areas`, columna `gerencia_referencia`) y es atributo del maestro de áreas (dominio RRHH). Se reincorpora en la capa BI (DIM_AREA) por homologación. Ningún análisis de Compras lo requiere (el gasto se agrupa por área vía `centro_costo → area`).
- **`centro_costo_id` no se coloca en `areas`.** La relación Área–Centro de costo se modela como `centros_costo.area_id` con `UNIQUE` (1:1), coherente con el Modelo Conceptual y con Contabilidad.

Criterio avalado por el equipo: las fuentes operacionales pueden llevar un subconjunto del maestro; el propio Master lo indica ("los sistemas operacionales pueden utilizar códigos o nombres distintos"). Sin FK físicas hacia otros dominios.

## Referencias

Trabajo v2 (AIEP) · Universo Empresarial Master v0.2 · Brief e IDF v0.2 de Compras · Modelo Lógico / ERD v0.1 · Guías de trabajo del equipo (GitHub y Modelos Lógicos).
