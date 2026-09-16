# Matriz de Calidad de Datos — RRHH

## Alcance

Esta matriz documenta las reglas iniciales de calidad aplicadas durante
el hito ETL RRHH 0.1.

| Entidad         | Campo / Regla                       | Tratamiento ETL                             | Severidad |
| --------------- | ----------------------------------- | ------------------------------------------- | --------- |
| Empleado        | `empleado_id` obligatorio           | Validar presencia                           | ERROR     |
| Empleado        | RUT obligatorio                     | Validar presencia                           | ERROR     |
| Empleado        | Formato RUT                         | Normalizar a `XXXXXXXX-X` y validar formato | ERROR     |
| Empleado        | `nombres` obligatorio               | `TRIM` + mayúsculas + validación            | ERROR     |
| Empleado        | `apellido_paterno` obligatorio      | `TRIM` + mayúsculas + validación            | ERROR     |
| Empleado        | `apellido_materno` ausente          | Convertir vacío a `NULL`                    | WARNING   |
| Empleado        | `sexo` ausente                      | Convertir vacío a `NULL`                    | WARNING   |
| Empleado        | `nacionalidad` ausente              | Convertir vacío a `NULL`                    | WARNING   |
| Empleado        | `fecha_ingreso`                     | Validar fecha                               | ERROR     |
| Empleado        | `fecha_salida`                      | Debe ser igual o posterior al ingreso       | ERROR     |
| Empleado        | Fecha de salida con estado `ACTIVO` | Marcar inconsistencia                       | ERROR     |
| Empleado        | `area_id` obligatorio               | Validar presencia                           | ERROR     |
| Empleado        | `cargo_id` obligatorio              | Validar presencia                           | ERROR     |
| Empleado        | Estado                              | Debe corresponder al dominio esperado       | ERROR     |
| Área            | Código                              | `TRIM` + mayúsculas                         | Limpieza  |
| Área            | Nombre                              | `TRIM` + mayúsculas                         | Limpieza  |
| Área            | Gerencia vacía                      | Convertir a `NULL`                          | Limpieza  |
| Cargo           | Código                              | `TRIM` + mayúsculas                         | Limpieza  |
| Cargo           | Nombre                              | `TRIM` + mayúsculas                         | Limpieza  |
| Cargo           | Nivel vacío                         | Convertir a `NULL`                          | Limpieza  |
| Centro de costo | Código                              | `TRIM` + mayúsculas                         | Limpieza  |
| Centro de costo | Nombre                              | `TRIM` + mayúsculas                         | Limpieza  |

## Homologación

Los identificadores numéricos de RRHH (`area_id`, `cargo_id`,
`centro_costo_id`, etc.) se consideran identificadores locales de la
fuente operacional.

No deben asumirse como equivalentes a identificadores de Compras,
Contabilidad, Producción u otras fuentes.

Los códigos de negocio, como códigos de área, cargo o centro de costo,
pueden utilizarse como candidatos para procesos posteriores de
homologación, pero las equivalencias definitivas serán resueltas por el
ETL Core en una etapa posterior.
