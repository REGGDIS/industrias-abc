# Cierre ETL de Compras

**Proyecto:** Business Intelligence — Industrias ABC (Equipo BInnova)
**Dominio:** Compras · **Responsable:** Raymond Civil
**Rama:** `feat/etl-compras-auditoria-05` · **Base:** `develop` · **Versión:** 0.1

## GAP ANALYSIS previo a la implementación

Compras ya contaba con extracción y staging (0.1), carga incremental (0.2),
calidad transaccional (0.3) y normalización/estandarización (0.4), todo probado
en PostgreSQL. **Faltaba** una funcionalidad ejecutable que dejara evidencia
técnica de **cada corrida** del ETL: identificador único, tiempos, estado final,
métricas reales y detalle de error. Ese es el objetivo de 0.5, el cierre.

Se adopta la **misma convención de cierre que Contabilidad y Asistencia**: un
runner en `etl/validate/<dominio>/runner.py`, invocable con `--output <json>`, y
evidencia committeada (`evidencia_ejecucion.json` / `evidencia_fallo_controlado.json`).

## Implementación y reutilización

`etl/validate/compras/runner.py` orquesta las etapas del cierre **reutilizando
los scripts existentes, sin duplicar reglas de negocio**:

| Etapa | Script reutilizado | Aporta |
|---|---|---|
| `preparacion_raw` | `sql/staging/compras/preparar_raw_compras.sql` (0.4) | fixtures RAW |
| `normalizacion` | `sql/staging/compras/ejecutar_normalizacion_compras.sql` (0.4) | normalización + **métricas** (fila TOTAL) |
| `validaciones_calidad` | `validate/compras/validaciones_calidad_compras.sql` (0.3) | controles de calidad |
| `pruebas_normalizacion` | `tests/compras/test_normalizacion_compras.sql` (0.4) | pruebas |

- Cada etapa se ejecuta con **`psql -v ON_ERROR_STOP=1`**: el **código de salida
  real** decide OK/ERROR; un fallo **no** se convierte en OK y se registra la
  `stage` donde ocurrió.
- Las **métricas** (`procesados / validos / review / errores`) se leen de la fila
  `TOTAL` del resumen de normalización de 0.4 — no se escriben a mano.
- **Seguridad:** la contraseña se pasa por `PGPASSWORD` (no en la línea de comandos)
  y los errores inesperados se registran como `"<Tipo>: fallo en <stage>"`, sin
  volcar mensajes que puedan contener credenciales.
- **Solo lectura:** los scripts usan `SELECT` / `TEMP` / `ROLLBACK`; el runner
  escribe únicamente el JSON de salida. No toca tablas operacionales ni el ETL Core.

> Nota de implementación: a diferencia de Contabilidad/Asistencia (que ejecutan
> vía `psycopg`), Compras invoca los scripts con `psql` porque sus SQL de 0.4 usan
> meta-comandos de psql (`\ir`, `\echo`); así se **reutiliza 0.3/0.4 tal cual**, sin
> reimplementar sus reglas.

## Contrato de salida

Un objeto JSON por corrida (escrito en `--output`):

```
run_id, proceso="compras_etl", status="OK|ERROR", stage (null si OK / etapa si ERROR),
error (null o detalle técnico saneado),
procesados, validos, review, errores, controles_error,
etapas=[{nombre, resultado, duracion_ms}],
started_at, finished_at, duration_seconds, duracion_ms
```

`duracion_ms` se incluye explícitamente por requerimiento del encargo de Compras.

## Reproducción

```bash
# Corrida real (escribe la evidencia en la ruta indicada)
python -m etl.validate.compras.runner --output docs/etl/compras/evidencia_ejecucion.json

# Pruebas
pytest etl/tests/compras/test_runner.py -v
```

Requiere `COMPRAS_DB_HOST/PORT/NAME/USER/PASSWORD` (ya soportadas por
`etl/config/settings.py`, sin credenciales en código) y el cliente `psql`.

## Verificación realizada (evidencia real, ejecutada en PostgreSQL)

**Corrida OK** (`evidencia_ejecucion.json`): `status=OK`, exit 0, `run_id` único,
métricas **120 / 120 / 0 / 0** (procesados/validos/review/errores), 4 etapas OK,
`error=null`.

```json
{
  "run_id": "da1b001c-6561-463d-82f8-70571a306f91",
  "proceso": "compras_etl", "status": "OK", "stage": null, "error": null,
  "procesados": 120, "validos": 120, "review": 0, "errores": 0, "controles_error": 0,
  "etapas": [
    {"nombre": "preparacion_raw", "resultado": "OK", "duracion_ms": 683},
    {"nombre": "normalizacion", "resultado": "OK", "duracion_ms": 92},
    {"nombre": "validaciones_calidad", "resultado": "OK", "duracion_ms": 49},
    {"nombre": "pruebas_normalizacion", "resultado": "OK", "duracion_ms": 48}
  ],
  "duration_seconds": 0.874, "duracion_ms": 874
}
```

**Falla controlada** (`evidencia_fallo_controlado.json`): se fuerza el fallo de una
etapa (SQL inválido) → `status=ERROR`, `stage="validaciones_calidad"`,
`controles_error=1`, `error` con el detalle técnico real y **exit 1**. El fallo
**no** se reporta como OK.

```json
{
  "status": "ERROR", "stage": "validaciones_calidad", "controles_error": 1,
  "error": "Etapa 'validaciones_calidad' (exit 3): ... relation \"control_inexistente_cierre\" does not exist ...",
  "etapas": [
    {"nombre": "preparacion_raw", "resultado": "OK", "duracion_ms": 49},
    {"nombre": "normalizacion", "resultado": "OK", "duracion_ms": 57},
    {"nombre": "validaciones_calidad", "resultado": "ERROR", "duracion_ms": 34}
  ]
}
```

**Pruebas** (`test_runner.py`): **4/4 PASA** — incluye fallo sin BD con
**saneo de credenciales** (el secreto inyectado no queda en la evidencia),
`run_id` único, corrida OK y falla controlada.

## Trazabilidad (requisito → evidencia)

| Requisito | Evidencia | Estado |
|---|---|---|
| run_id único | ids distintos entre corridas | ✅ |
| inicio/término/duración | started_at/finished_at/duration_seconds/duracion_ms | ✅ |
| estado OK/ERROR + exit code | 0 / 1 reales | ✅ |
| métricas reales (0.3/0.4) | 120/120/0/0 de la fila TOTAL | ✅ |
| etapas + resultado | lista `etapas[]` | ✅ |
| error saneado | detalle técnico sin credenciales | ✅ |
| salida JSON | `evidencia_*.json` válidos | ✅ |
| no toca operacionales/Core/DW | solo lectura + JSON | 🚫 respetado |

## Límites del cierre

- Las métricas se obtienen de la fila `TOTAL` del resumen de normalización de 0.4
  (acoplamiento intencional al contrato de 0.4; si cambia ese resumen, se ajusta
  el parseo).
- Las pruebas de corrida OK / falla real son de **integración** (requieren BD y
  `psql`); si no hay BD, se omiten. Las pruebas de saneo y `run_id` corren sin BD.
- Con la integración de este PR, **el ETL de Compras queda cerrado**. Todo
  desarrollo posterior corresponde a la etapa de Data Warehouse, no a nuevas
  iteraciones ETL (salvo corrección necesaria).
