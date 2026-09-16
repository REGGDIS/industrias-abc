# Evidencia de validación — Contratos y Remuneraciones

**Proyecto:** Business Intelligence — Industrias ABC
**Dominio:** Contratos y Remuneraciones
**Responsable del dominio:** Luis Figueroa
**Motor:** Microsoft SQL Server 2022
**Base:** `ContratosRemuneraciones_ABC`
**Puerto local:** `1434`

## Estado

La validación dejó de estar pendiente. El flujo completo fue ejecutado contra la base SQL Server real utilizando las cinco entidades del dominio:

- Empleado
- Contrato
- Liquidacion
- ConceptoPago
- DetalleLiquidacion

El flujo validado es:

```text
dbo.*
  -> RAW física
  -> STAGING
  -> validación Python
  -> auditoría JSON
```

## Carga RAW real

| Entidad            | Filas RAW |
| ------------------ | --------: |
| Empleado           |        80 |
| Contrato           |        21 |
| Liquidacion        |        19 |
| ConceptoPago       |         9 |
| DetalleLiquidacion |       106 |
| **TOTAL**          |   **235** |

## STAGING real

Los conteos de STAGING coincidieron con RAW:

```text
empleado: 80
contrato: 21
liquidacion: 19
concepto_pago: 9
detalle_liquidacion: 106
TOTAL: 235
```

## Validación real

Comando oficial:

```bash
python -m etl.validate.contratos_remuneraciones.validator
```

Resultado:

```text
Validación Contratos y Remuneraciones — 0 hallazgos
0 ERROR
0 WARNING

Sin hallazgos. Todas las reglas mínimas se cumplen.
```

## Runner de cierre

```bash
python -m etl.validate.contratos_remuneraciones.runner --output docs/etl/contratos_remuneraciones/evidencia_ejecucion.json
```

Resultado real:

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

## Fallo controlado

Se alteró temporalmente en memoria un registro de `DetalleLiquidacion`:

```text
monto = -100
```

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
entidad = DetalleLiquidacion
identificador = 1
regla = monto_negativo
severidad = ERROR
detalle = monto=-100
```

## Pruebas

```text
Validación del dominio: 34 passed
Runner: 4 passed
Suite global: 132 passed, 38 skipped
```

## Entorno validado

```text
Microsoft SQL Server 2022
Base: ContratosRemuneraciones_ABC
Contenedor: industrias-abc-contratos-rem-db
Puerto host: 1434
ODBC Driver 17 for SQL Server
pyodbc 5.3.0
```

La configuración reutiliza `get_contratos_rem_db_config()` y no se versionan credenciales.
