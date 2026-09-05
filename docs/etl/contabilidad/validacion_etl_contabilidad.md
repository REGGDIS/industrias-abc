# Validación ETL Contabilidad 0.1 — Source-to-Staging

## 1. Objetivo

Validar de forma independiente y reproducible que la información de la fuente operacional de Contabilidad se conserve correctamente al pasar por RAW y staging/clean, verificando conteos, montos, cuadratura, integridad referencial, jerarquías, dominios y reglas contables.

## 2. Entorno utilizado

- Motor: PostgreSQL 16.
- Base de datos: contabilidad.
- Contenedor: industrias-abc-contabilidad-db.
- Staging de prueba: tablas TEMP creadas dentro de una única sesión PostgreSQL.
- Las tablas operacionales no fueron modificadas.
- No se crearon objetos permanentes de staging.

## 3. Scripts revisados

### Extracción

- etl/sql/extract/contabilidad/areas.sql
- etl/sql/extract/contabilidad/centros_costo.sql
- etl/sql/extract/contabilidad/cuentas_contables.sql
- etl/sql/extract/contabilidad/movimientos_contables.sql

### Staging

- etl/sql/staging/contabilidad/areas.sql
- etl/sql/staging/contabilidad/centros_costo.sql
- etl/sql/staging/contabilidad/cuentas_contables.sql
- etl/sql/staging/contabilidad/movimientos_contables.sql

### Validación

- etl/tests/contabilidad/validacion_source_staging.sql

## 4. Conteos Source vs Staging

| Entidad | Source | Staging | Diferencia | Resultado |
|---|---:|---:|---:|---|
| areas | 7 | 7 | 0 | OK |
| centros_costo | 7 | 7 | 0 | OK |
| cuentas_contables | 24 | 24 | 0 | OK |
| movimientos_contables | 10 | 10 | 0 | OK |

No se detectó pérdida ni duplicación de registros durante la preparación de staging.

## 5. Reconciliación financiera

| Control | Source | Staging | Diferencia | Resultado |
|---|---:|---:|---:|---|
| SUM(debe) | 26.950.000,00 | 26.950.000,00 | 0,00 | OK |
| SUM(haber) | 26.950.000,00 | 26.950.000,00 | 0,00 | OK |

Los montos se conservan íntegramente entre la fuente y staging.

## 6. Cuadratura contable

En staging se obtuvo:

- Total Debe: 26.950.000,00
- Total Haber: 26.950.000,00
- Diferencia: 0,00

Resultado: OK — BALANCE CUADRADO.

## 7. Duplicados

No se detectaron duplicados en:

- codigo_area;
- codigo de centros de costo;
- codigo_cuenta.

Resultado: OK.

## 8. Integridad referencial

No se detectaron:

- movimientos con cuenta_id inexistente;
- movimientos con centro_costo_id inexistente;
- centros de costo con area_id inexistente.

Resultado: OK.

## 9. Relación área-centro

No se detectaron áreas asociadas a más de un centro de costo bajo la regla 1:1 documentada para el modelo.

Resultado: OK.

## 10. Jerarquía de cuentas

No se detectaron cuentas con cuenta_padre_id apuntando a una cuenta inexistente.

Resultado: OK.

## 11. Reglas contables

No se detectaron registros con:

- debe negativo;
- haber negativo;
- debe y haber ambos en cero;
- debe y haber ambos mayores que cero;
- tipo_cambio menor o igual que cero.

Resultado: OK.

## 12. Dominios y normalización

No se detectaron:

- estados inválidos en centros de costo;
- estados inválidos en cuentas contables;
- moneda vacía, nula o con espacios residuales;
- diferencias entre moneda normalizada en Source y Staging;
- documento_tipo vacío, nulo o distinto de su valor normalizado esperado.

Resultado: OK.

## 13. Hallazgos

No se identificaron errores ni advertencias sobre los datos evaluados.

Durante la revisión del PR se detectó inicialmente que el script dependía de objetos staging no materializados. Para hacer la validación reproducible, se incorporó la creación de fixtures RAW y CLEAN mediante tablas TEMP dentro de la misma sesión PostgreSQL, sin alterar la fuente operacional ni el ETL Core.

## 14. Conclusión

**VALIDADO**

La validación Source-to-Staging confirma que el ETL Contabilidad 0.1 conserva los registros, montos, relaciones, jerarquías y dominios relevantes del modelo contable.

La reconciliación debe/haber es exacta y la cuadratura se mantiene con diferencia 0,00.

No se detectaron hallazgos críticos ni pérdidas de información durante el paso hacia staging.
