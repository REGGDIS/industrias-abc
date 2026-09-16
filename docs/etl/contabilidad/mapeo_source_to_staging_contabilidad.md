# Mapeo Source-to-Staging — Contabilidad

## Objetivo

Documentar la trazabilidad de los campos del dominio Contabilidad desde la fuente operacional hasta la capa staging/clean, indicando las transformaciones aplicadas y la validación esperada.

## areas

| Campo fuente | Campo staging | Transformación | Validación esperada |
|---|---|---|---|
| area_id | area_id | Ninguna | Mismo valor |
| codigo_area | codigo_area | UPPER(TRIM()) | Código normalizado, sin pérdida semántica |
| nombre_area | nombre_area | TRIM() | Texto preservado sin espacios exteriores |

## centros_costo

| Campo fuente | Campo staging | Transformación | Validación esperada |
|---|---|---|---|
| centro_costo_id | centro_costo_id | Ninguna | Mismo valor |
| codigo | codigo | UPPER(TRIM()) | Código preservado y normalizado |
| nombre | nombre | TRIM() | Texto preservado |
| area_id | area_id | Ninguna | Relación con área preservada |
| responsable | responsable | NULLIF(TRIM(), '') | Cadena vacía se transforma en NULL |
| estado | estado | UPPER(TRIM()) | ACTIVO / INACTIVO |

## cuentas_contables

| Campo fuente | Campo staging | Transformación | Validación esperada |
|---|---|---|---|
| cuenta_id | cuenta_id | Ninguna | Mismo valor |
| codigo_cuenta | codigo_cuenta | UPPER(TRIM()) | Código preservado |
| nombre_cuenta | nombre_cuenta | TRIM() | Texto preservado |
| tipo_cuenta | tipo_cuenta | UPPER(TRIM()) | Categórico normalizado |
| grupo | grupo | UPPER(TRIM()) | Categórico normalizado |
| nivel | nivel | Ninguna | Mismo valor |
| cuenta_padre_id | cuenta_padre_id | Ninguna | Jerarquía preservada |
| estado | estado | UPPER(TRIM()) | ACTIVA / INACTIVA |

## movimientos_contables

| Campo fuente | Campo staging | Transformación | Validación esperada |
|---|---|---|---|
| movimiento_id | movimiento_id | Ninguna | Mismo valor |
| fecha | fecha | CAST(... AS DATE) | Misma fecha |
| cuenta_id | cuenta_id | Ninguna | FK preservada |
| centro_costo_id | centro_costo_id | Ninguna | FK preservada |
| documento_tipo | documento_tipo | UPPER(TRIM()) | Valor normalizado sin pérdida semántica |
| documento_numero | documento_numero | TRIM() | Valor preservado |
| descripcion | descripcion | TRIM() | Texto preservado |
| debe | debe | Ninguna | Mismo monto |
| haber | haber | Ninguna | Mismo monto |
| moneda | moneda | UPPER(TRIM()) | Moneda normalizada sin pérdida de valor |
| tipo_cambio | tipo_cambio | Ninguna | Misma precisión |

## Conclusión

Las transformaciones de staging corresponden a normalizaciones de texto y estabilización de tipos. No modifican montos contables, identificadores, relaciones ni jerarquías.
