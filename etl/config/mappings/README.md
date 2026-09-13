# Mappings ETL de Producción

Este directorio conserva mappings explícitos y auditables utilizados por la carga ETL de Producción hacia el Data Warehouse.

## Regla de integración

No se homologan referencias por semejanza visual ni por secuencia numérica. Una fila sólo se utiliza como mapping cuando `estado=APROBADO` y contiene las business keys empresariales requeridas.

Mientras una equivalencia permanezca en `REVIEW`, la carga utiliza el miembro desconocido (`key = 0`) y conserva la referencia de origen para trazabilidad.

### `produccion_centros_costo.csv`

Relaciona el `centro_costo_id` local de Producción con `codigo_centro_costo` y `codigo_area` del DW. Los IDs 101-105 se mantienen inicialmente en REVIEW porque la fuente operacional no expone por sí sola la business key empresarial.

### `produccion_insumos.csv`

Relaciona `insumo_codigo_origen` de Producción con `codigo_insumo_dw` de `DIM_INSUMO`. Códigos como `INS-1001` no se transforman automáticamente a códigos de Compras por reglas de texto. Los valores `ID_LOCAL:*` son fallbacks de trazabilidad cuando el CSV complementario no identifica un consumo de forma unívoca.
