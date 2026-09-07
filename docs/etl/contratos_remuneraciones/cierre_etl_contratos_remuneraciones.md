# Cierre ETL — Contratos y Remuneraciones

**Proyecto:** Business Intelligence — Industrias ABC  
**Equipo:** BInnova  
**Dominio:** Contratos y Remuneraciones  
**Responsable:** Luis Figueroa  
**Base de integración:** `develop`

## Objetivo del cierre

Completar el ETL de Contratos y Remuneraciones dejando un flujo ejecutable, validado contra SQL Server real y con evidencia reproducible de una corrida correcta y de un fallo controlado.

## GAP inicial

Antes del cierre, el PR disponía de extracción, RAW parcial, STAGING parcial y 26 pruebas unitarias, pero presentaba brechas relevantes:

```text
ejecución SQL Server real pendiente
RAW incompleto para 2 de 5 entidades
STAGING dependiente de fixtures inexistentes
validador limitado a 3 entidades
configuración SQL Server paralela a ETL Core
dependencia pyodbc no declarada
ausencia de auditoría de ejecución
ausencia de evidencia real de fallo de calidad
```

## Implementación final

Se completó el flujo de cinco entidades:

```text
Empleado
Contrato
Liquidacion
ConceptoPago
DetalleLiquidacion
```

Arquitectura:

```text
SQL Server operacional
        |
        v
RAW física
        |
        v
STAGING
        |
        v
validator.py
        |
        v
runner.py
        |
        v
evidencia JSON
```

## Refactorización

El validador se convirtió desde un módulo aislado a un paquete:

```text
etl/validate/contratos_remuneraciones/
├── __init__.py
├── validator.py
└── runner.py
```

Esto evita mantener un módulo y un paquete con el mismo nombre y alinea el dominio con el patrón de cierre usado en otros ETL del proyecto.

## Configuración central

La conexión a SQL Server reutiliza:

```python
get_contratos_rem_db_config()
```

de ETL Core.

Variables:

```text
CONTRATOS_REM_DB_HOST
CONTRATOS_REM_DB_PORT
CONTRATOS_REM_DB_NAME
CONTRATOS_REM_DB_USER
CONTRATOS_REM_DB_PASSWORD
```

Dependencias verificadas:

```text
pyodbc==5.3.0
ODBC Driver 17 for SQL Server
```

No se versionan contraseñas.

## Ejecución real

Entorno:

```text
Microsoft SQL Server 2022
Developer Edition
contenedor = industrias-abc-contratos-rem-db
base = ContratosRemuneraciones_ABC
puerto host = 1434
```

Carga y STAGING:

| Entidad            |   Filas |
| ------------------ | ------: |
| Empleado           |      80 |
| Contrato           |      21 |
| Liquidacion        |      19 |
| ConceptoPago       |       9 |
| DetalleLiquidacion |     106 |
| **TOTAL**          | **235** |

Los conteos de RAW y STAGING coincidieron.

## Corrida OK

Archivo:

```text
docs/etl/contratos_remuneraciones/evidencia_ejecucion.json
```

Resultado:

```text
run_id = 900176ef-c209-45ae-84c5-ebba34a8c10c
status = OK
stage = null

procesados = 235
validos = 235
review = 0
errores = 0
warnings = 0
controles_error = 0
```

Etapas:

```text
lectura_staging -> OK
validacion      -> OK
```

## Fallo controlado

Archivo:

```text
docs/etl/contratos_remuneraciones/evidencia_fallo_controlado.json
```

Se alteró temporalmente en memoria una copia de un registro de `DetalleLiquidacion`:

```text
monto = -100
```

No se modificó SQL Server.

Resultado:

```text
run_id = ab12cecf-c7d5-47ce-a79c-08d16edb46a0
status = ERROR
stage = validacion

procesados = 235
validos = 234
errores = 1
warnings = 0
controles_error = 1
```

Hallazgo:

```text
DetalleLiquidacion
id = 1
regla = monto_negativo
severidad = ERROR
detalle = monto=-100
```

El runner bloqueó correctamente el cierre.

## Pruebas

Validación del dominio:

```text
34 passed
```

Runner:

```text
4 passed
```

Suite global final:

```text
132 passed, 38 skipped
```

## Evidencias

El cierre conserva:

```text
evidencia_validaciones_v0_2.md
evidencia_ejecucion.json
evidencia_fallo_controlado.json
matriz_calidad_v0_2.md
notas_staging_v0_2.md
cierre_etl_contratos_remuneraciones.md
```

## Alcance respetado

No se construyen dimensiones ni hechos desde este dominio.

No se modifica ETL Core salvo reutilizar su configuración existente.

No se realizan homologaciones transversales definitivas de empleados, áreas o cargos.

No se modifican automáticamente datos de negocio por una regla de calidad.

El dominio queda cerrado en ETL y preparado para integración posterior con el Data Warehouse.
