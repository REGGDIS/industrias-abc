# Cierre ETL de Contabilidad

## GAP ANALYSIS previo a la implementación

| Capacidad | Compras inspeccionado | Contabilidad inicial | Acción necesaria |
|---|---|---|---|
| Extracción y staging | SQL de extracción y limpieza; fixtures TEMP | Cuatro extractores y cuatro SELECT de limpieza completos | Reutilizar los ocho SQL sin modificarlos |
| Calidad ejecutable | 0.3: detalle, resumen y pruebas SQL | Informe Source-to-Staging con controles, sin clasificación por registro ni fallo del proceso por hallazgos | Compartir consultas del informe con runner, evaluar resultados y agregar pruebas adversas |
| Normalización | 0.4: limpieza, trazabilidad, idempotencia | TRIM/UPPER/NULLIF/DATE ya implementados; preservación monetaria prevista | Agregar evidencia original/normalizado y pruebas de preservación e idempotencia |
| Auditoría | No se encontró cierre 0.5 ni runner de auditoría de Compras en este checkout | Sin ejecución auditada de Contabilidad | Implementar requisitos explícitos del encargo dentro del dominio |
| Configuración y conexión | Configuración central disponible | `get_contabilidad_db_config`, conexión PostgreSQL y nombres de staging reutilizables | Reutilizar sin cambiar Core |

Se inspeccionaron `etl/audit`, `etl/config`, `etl/transform`, `etl/load`, los SQL,
tests y documentación de ambos dominios, además del esquema de Contabilidad.
`etl/audit/logger.py` depende de RRHH y de su tabla de auditoría: no es un helper
de auditoría desacoplado que pueda usarse para este dominio. No se modificó.
El constructor compartido de tablas CLEAN crea objetos permanentes y ejecuta
DROP; para este cierre se necesita exclusivamente CREATE TEMP, por lo que se
reutilizan los nombres compartidos y las consultas existentes, sin alterar ese
constructor. No se requieren cambios de arquitectura ni de Core.

## Implementación y reutilización

- `etl/validate/contabilidad/runner.py`: extracción, normalización, evaluación,
  clasificación y auditoría específica del dominio. Reutiliza configuración,
  conexión y nombres del Core; no incorpora dependencias.
- `etl/validate/contabilidad/controles.sql`: las 17 consultas del informe anterior
  se trasladaron aquí para compartirlas entre Python y psql. Se agregaron ocho
  controles de obligatorios/nivel y preservación exacta por entidad. Las sumas
  usan COALESCE para interpretar una fuente vacía como cero.
- `etl/tests/contabilidad/validacion_source_staging.sql`: conserva la evidencia
  Source-to-Staging mediante tablas RAW/CLEAN temporales y ROLLBACK. La preparación
  reproduce las transformaciones aprobadas del dominio y reutiliza centralmente
  `controles.sql`, evitando duplicar las reglas de calidad entre psql y Python.
- `etl/tests/contabilidad/test_runner.py`: pruebas automatizadas con fixtures TEMP.
- `etl/validate/contabilidad/__init__.py`: paquete del dominio.
- `evidencia_ejecucion.json` y `evidencia_fallo_controlado.json`: resultados obtenidos.

Los IDs, referencias, nivel, padre de cuenta, fecha, debe, haber y tipo_cambio se
comparan mediante diferencias de multiconjuntos (`EXCEPT ALL`) en ambos sentidos.
Esto detecta pérdidas, duplicaciones y cambios que una suma global podría ocultar.
Moneda y documento_tipo siguen usando las comparaciones normalizadas del informe
original. No se convierte moneda ni se redondean importes. No se inventa un catálogo
de monedas o documentos que el esquema fuente no define.

La jerarquía mantiene el criterio existente: padre referenciado existente y
preservación de la relación; se controla además nivel positivo. No se reconstruye.

## Contrato de salida

Cada ejecución genera UUID, inicio y término UTC, duración, estado OK/ERROR,
etapa del fallo, mensaje, cantidades extraídas por entidad, procesadas, válidas,
REVIEW, ERROR y `controles_error`; incluye controles, registros identificados y campos normalizados
que cambiaron, con valores original y final. Los Decimal se serializan como
cadenas exactas, nunca como float. Los fallos técnicos registran tipo y etapa sin
volcar mensajes de conexión que puedan contener secretos.

`procesados` suma filas de las cuatro entidades, no solamente movimientos.
`VALID` significa que no hay incidencias atribuibles a esa fila; `ERROR` reúne todas
sus reglas sin contar la fila varias veces. No se definieron reglas REVIEW porque
los controles contables existentes son obligatorios; el contador permanece en cero.
Un fallo global de cuadratura o reconciliación también hace fallar la ejecución,
aunque no pueda atribuirse a una fila concreta. `errores` cuenta registros
individuales clasificados como ERROR y `controles_error` cuenta controles de
calidad fallidos, por lo que ambas métricas deben interpretarse conjuntamente. Durante un fallo anterior a la
validación, válidos y errores aún no están calculados; la etapa lo deja explícito.

Todo PostgreSQL se ejecuta en una sesión con snapshot REPEATABLE READ, tablas
temporales y rollback/cierre. El JSON es la salida persistida. Si no puede escribirse,
la excepción se propaga y el comando falla; no se declara una auditoría exitosa.

## Reproducción

Usar las variables CONTABILIDAD_DB_* de la configuración central existente.
No crear credenciales ni archivos .env para este cierre.

```powershell
.\.venv\Scripts\python.exe -m etl.validate.contabilidad.runner
$env:CONTABILIDAD_INTEGRATION='1'
.\.venv\Scripts\python.exe -m pytest etl/tests/contabilidad -q
.\.venv\Scripts\python.exe -m pytest -q
```

El runner guarda por defecto un archivo único en `logs/contabilidad/`; `--output`
permite elegir la ruta (una ruta repetida reemplaza ese archivo). Devuelve código
0 para OK y 1 para controles fallidos o errores de ejecución auditados.

El informe SQL sigue disponible mediante `psql`. En el entorno Windows validado,
donde `psql` no está instalado localmente, se ejecutó desde el contenedor PostgreSQL
copiando temporalmente la carpeta `etl` al contenedor y usando:

```text
psql -v ON_ERROR_STOP=1 -U postgres -d contabilidad -f /tmp/industrias-abc/etl/tests/contabilidad/validacion_source_staging.sql
```

Este informe SQL muestra resultados; el runner es la entrada que interpreta
hallazgos como errores y produce auditoría. Las pruebas de integración requieren
PostgreSQL configurado y el conjunto de datos de Contabilidad; sin la variable
de activación quedan explícitamente omitidas. En esta verificación se activaron.

## Verificación realizada

- Pruebas específicas de Contabilidad con integración PostgreSQL activada:
  **38 aprobadas de 38**.
- Suite completa del proyecto: **86 aprobadas y 35 omitidas**, sin fallos.
  Las omisiones corresponden a pruebas de integración que requieren activación
  explícita de sus respectivos entornos.
- `git diff --check`: sin errores de whitespace.
- psql Source-to-Staging: ejecución correcta, 25 controles evaluados y ROLLBACK.
- Ejecución real del runner: **48 procesados, 48 válidos, 0 REVIEW,
  0 errores y 0 controles_error**, estado OK.
- Los 48 registros corresponden a 7 áreas, 7 centros de costo,
  24 cuentas contables y 10 movimientos.
- Conteos Source/Staging: áreas 7/7, centros 7/7, cuentas 24/24,
  movimientos 10/10.
- SUM(debe) y SUM(haber): **26950000.00** en origen y staging;
  cuadratura **0.00**.
- El fallo controlado utiliza exclusivamente una copia TEMP de movimientos con
  `tipo_cambio=0`; no altera la fuente operacional.
- Las pruebas cubren fallos de conexión y SQL, nulos, reglas contables,
  referencias huérfanas, estados, duplicados, trazabilidad, precisión decimal,
  idempotencia, reconciliación y fallos globales de controles.

Los resultados se calculan desde PostgreSQL y no están codificados como constantes
en el runner.

## Límites del cierre

El nivel Compras 0.5 no puede contrastarse con archivos ausentes en este checkout;
la auditoría cubre los requisitos explícitos del encargo. RAW/CLEAN siguen siendo
temporales, coherentes con el flujo validado, sin publicación de staging permanente.
La evidencia de fallo corresponde a un fixture deliberadamente inválido, no a un
problema de la fuente operacional. No se modificaron otros dominios, Core, fuentes,
Data Warehouse, dependencias ni credenciales.
