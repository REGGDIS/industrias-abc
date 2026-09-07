# Notas de STAGING — Contratos y Remuneraciones

## Flujo definitivo

El dominio quedó implementado para sus cinco entidades:

```text
dbo.Empleado
dbo.Contrato
dbo.Liquidacion
dbo.ConceptoPago
dbo.DetalleLiquidacion
        |
        | extracción / carga
        v
raw.contratos_remuneraciones_*
        |
        | limpieza superficial y segura
        v
staging.contratos_remuneraciones_*
        |
        | validación de calidad
        v
etl.validate.contratos_remuneraciones
```

## Entidades

El flujo RAW -> STAGING cubre:

| Entidad            | RAW | STAGING |
| ------------------ | --- | ------- |
| Empleado           | Sí  | Sí      |
| Contrato           | Sí  | Sí      |
| Liquidacion        | Sí  | Sí      |
| ConceptoPago       | Sí  | Sí      |
| DetalleLiquidacion | Sí  | Sí      |

Ya no existen dependencias de fixtures temporales ficticios para `ConceptoPago` ni `DetalleLiquidacion`.

## RAW

RAW utiliza tablas físicas con `raw_loaded_at`.

Los scripts se encuentran en:

```text
etl/sql/load/contratos_remuneraciones/
```

Se utiliza una carga reproducible:

```text
TRUNCATE + INSERT
```

La capa RAW conserva el dato de origen sin homologar ni aplicar reglas de negocio.

## STAGING

Las cinco entidades se exponen mediante vistas persistentes:

```text
staging.contratos_remuneraciones_empleado
staging.contratos_remuneraciones_contrato
staging.contratos_remuneraciones_liquidacion
staging.contratos_remuneraciones_concepto_pago
staging.contratos_remuneraciones_detalle_liquidacion
```

Los scripts están en:

```text
etl/sql/staging/contratos_remuneraciones/
```

Las transformaciones realizadas son superficiales y seguras:

- eliminación de espacios extremos;
- normalización de mayúsculas en códigos y estados;
- conversión de cadenas vacías a `NULL` cuando corresponde;
- generación de `rut_referencia_normalizado` como candidato de homologación;
- preservación de identificadores y montos originales.

La homologación transversal definitiva continúa siendo responsabilidad de ETL Core.

## Conteos verificados

La ejecución real contra SQL Server produjo:

```text
Empleado             80
Contrato              21
Liquidacion           19
ConceptoPago           9
DetalleLiquidacion   106
-------------------------
TOTAL                235
```

Los conteos RAW y STAGING coincidieron.

## Validación

La lógica se encuentra ahora en:

```text
etl/validate/contratos_remuneraciones/
├── __init__.py
├── validator.py
└── runner.py
```

El antiguo módulo único:

```text
etl/validate/contratos_remuneraciones.py
```

fue refactorizado a paquete para mantener el mismo patrón utilizado por otros dominios del proyecto.

El validador cubre reglas por registro y controles cruzados entre entidades.

El runner agrega:

```text
run_id
timestamps
duración
status OK/ERROR
stage
conteos por entidad
procesados
válidos
warnings
errores
controles_error
hallazgos
```

## Configuración

La conexión reutiliza:

```python
get_contratos_rem_db_config()
```

desde:

```text
etl/config/settings.py
```

No se mantiene una segunda convención de variables SQL Server.

La dependencia utilizada es:

```text
pyodbc==5.3.0
```

con:

```text
ODBC Driver 17 for SQL Server
```

## Límites

Este cierre no:

- crea dimensiones;
- crea tablas de hechos;
- modifica ETL Core;
- homologa definitivamente empleados con RRHH o Asistencia;
- modifica automáticamente contratos vencidos;
- escribe cambios de calidad sobre las tablas operacionales.

La salida del dominio queda preparada para su integración posterior con el Data Warehouse.
