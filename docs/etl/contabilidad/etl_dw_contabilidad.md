# DW + ETL → DW de Contabilidad

## 1. Alcance

Este bloque completa el dominio analítico de Contabilidad de Industrias ABC:

- `dw.dim_cuenta_contable`;
- `dw.fact_contabilidad`;
- índices e instalador físico reproducible;
- carga ETL desde el Sistema Operacional de Contabilidad ya validado;
- homologación hacia `DIM_AREA` y `DIM_CENTRO_COSTO` conformadas;
- conversión analítica de moneda;
- idempotencia y auditoría transversal.

El ETL fuente vigente ya valida 48 registros: 7 áreas, 7 centros de costo, 24 cuentas y 10 movimientos contables. La capa DW reutiliza ese cierre y no duplica sus reglas de calidad.

## 2. Contratos dimensionales

### DIM_CUENTA_CONTABLE

- business key: `codigo_cuenta`;
- fuente autoritativa: Sistema Operacional de Contabilidad;
- tratamiento: SCD Tipo 1;
- jerarquía: se conserva mediante `codigo_cuenta_padre`;
- los IDs locales `cuenta_id` / `cuenta_padre_id` no se almacenan como claves dimensionales;
- miembro `0 / DESCONOCIDO` obligatorio.

### Dimensiones conformadas reutilizadas

Contabilidad no crea dimensiones paralelas para Área ni Centro de costo. El contrato transversal vigente del proyecto usa:

- `codigo_area` → `dw.dim_area`;
- `codigo` de Contabilidad → `codigo_centro_costo` de `dw.dim_centro_costo`.

La igualdad se aplica porque estas business keys ya fueron formalizadas por el DW-CORE y el Universo Empresarial Master. Los IDs locales siguen siendo solo trazabilidad.

## 3. FACT_CONTABILIDAD

Grano: **un movimiento contable de la fuente operacional**.

Claves:

- `fecha_key`;
- `cuenta_key`;
- `area_key`;
- `centro_costo_key`.

Trazabilidad:

- `movimiento_id_origen` se conserva únicamente para rastreo e idempotencia dentro de la misma fuente; nunca se usa como FK transversal.

Dimensiones degeneradas / atributos:

- tipo y número de documento;
- descripción;
- moneda de origen;
- tipo de cambio.

Medidas:

- `debe_origen`;
- `haber_origen`;
- `debe` normalizado a CLP;
- `haber` normalizado a CLP;
- `saldo = debe - haber`;
- `cantidad_registros = 1`.

La conversión analítica usa `monto_origen * tipo_cambio` y cuantiza a 2 decimales. Para CLP el tipo de cambio operacional es 1. Los importes originales se preservan para trazabilidad.

## 4. Tratamiento de errores y REVIEW

- fecha no resoluble en `DIM_FECHA`: REJECTED;
- cuenta no resoluble: `cuenta_key = 0` + REVIEW;
- área no resoluble: `area_key = 0` + REVIEW;
- centro de costo no resoluble: `centro_costo_key = 0` + REVIEW;
- nunca se homologan entidades por nombre ni por IDs locales.

## 5. Idempotencia

`DIM_CUENTA_CONTABLE` usa UPSERT por `codigo_cuenta`.

`FACT_CONTABILIDAD` usa UPSERT por `movimiento_id_origen`. La segunda ejecución del mismo lote debe producir:

- 0 inserted;
- 0 updated;
- todas las 24 cuentas y 10 filas de hecho como unchanged, si la fuente no cambió.

## 6. Auditoría

Runner oficial:

```text
python -m etl.run_dw_contabilidad
```

Auditoría transversal:

- `source = CONTABILIDAD`;
- `process = ETL_DW_CONTABILIDAD`;
- métricas read / valid / inserted / updated / unchanged / rejected / review;
- `SUCCESS` sin incidencias;
- `PARTIAL` si quedan filas en REVIEW o REJECTED;
- `ERROR` ante fallo técnico o controles fuente bloqueantes.

No se crean tablas técnicas dentro del esquema `dw`.

## 7. Instalación física

Requiere DW-CORE instalado. Ejecutar con `psql`:

```text
data-warehouse/sql/99_install/994_instalar_dw_contabilidad.sql
```

Tests estructurales:

```text
data-warehouse/tests/structural/test_300_dim_cuenta_contable.sql
data-warehouse/tests/structural/test_310_fact_contabilidad.sql
data-warehouse/tests/structural/test_311_reglas_fact_contabilidad.sql
```

## 8. Validación esperada con el seed vigente

Si el DW-CORE está cargado con las business keys empresariales y la fuente conserva el seed actual, se espera:

- fuente: 48 registros validados;
- DIM_CUENTA_CONTABLE: 24 cuentas reales + miembro desconocido;
- FACT_CONTABILIDAD: 10 movimientos;
- REVIEW: 0;
- REJECTED: 0;
- primera ejecución: 34 inserted (24 dimensión + 10 hechos);
- segunda ejecución: 34 unchanged.

Estos valores deben comprobarse en ejecución real antes del merge; no se consideran evidencia hasta ejecutar el flujo en el entorno integrado.
