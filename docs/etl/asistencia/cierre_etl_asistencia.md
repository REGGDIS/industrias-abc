# Cierre ETL de Asistencia

## Estado previo

Asistencia ya contaba con extracción desde MySQL, tablas RAW temporales,
transformaciones de staging reutilizables, validación funcional y pruebas unitarias.
El cierre se concentró en agregar auditoría de ejecución, persistencia de evidencia
y pruebas específicas del runner, sin modificar la lógica de negocio existente.

## Implementación

- `etl/validate/asistencia/runner.py`
  - reutiliza la configuración central `get_asistencia_db_config`;
  - conecta con MySQL mediante PyMySQL;
  - crea tablas RAW temporales;
  - reutiliza los SQL aprobados de staging;
  - ejecuta el validador existente;
  - genera `run_id` UUID;
  - registra inicio, término y duración;
  - registra estado `OK/ERROR`, etapa y mensaje de fallo;
  - persiste conteos extraídos, procesados, válidos, errores y warnings;
  - serializa fechas, horas, Decimal y timedelta en JSON;
  - evita persistir mensajes técnicos que puedan exponer credenciales.

- `etl/tests/asistencia/test_asistencia_runner.py`
  - prueba UUID únicos;
  - prueba fallo técnico de conexión;
  - prueba protección de mensajes sensibles;
  - prueba serialización de `timedelta`;
  - prueba fallo de calidad;
  - prueba ejecución real contra MySQL mediante activación explícita.

- `docs/etl/asistencia/evidencia_ejecucion.json`
  - evidencia de ejecución real exitosa.

- `docs/etl/asistencia/evidencia_fallo_controlado.json`
  - evidencia de un fallo deliberado de calidad realizado sobre una copia en memoria,
    sin alterar la fuente operacional.

## Contrato de salida

Cada ejecución genera:

- `run_id`
- `started_at`
- `finished_at`
- `duration_seconds`
- `status`
- `stage`
- `error`
- `extraidos`
- `procesados`
- `validos`
- `errores`
- `warnings`
- `detalle`
- `resultados`

Los warnings son observaciones no bloqueantes.
Una ejecución termina con `ERROR` cuando existe al menos un registro con error de calidad
o cuando ocurre un fallo técnico.

## Validaciones existentes reutilizadas

El validador de Asistencia conserva controles sobre:

- identificadores obligatorios;
- trabajador existente;
- turno existente;
- fecha válida;
- período de referencia;
- horas negativas;
- horas extras mayores que horas trabajadas;
- atraso negativo o incoherente;
- estados válidos;
- ausentismo;
- coherencia de registros AUSENTE;
- coherencia de registros PRESENTE/ATRASO;
- relación entre horas trabajadas, normales y extras;
- horas normales versus jornada del turno;
- fecha de asistencia anterior al ingreso del trabajador;
- duplicado trabajador + fecha.

No se duplicó esta lógica dentro del runner.

## Verificación realizada

- Tests existentes del validador: **11 aprobados**.
- Tests del runner sin integración: **4 aprobados, 1 omitido**.
- Tests del runner con MySQL real: **5 aprobados de 5**.
- Suite completa de Asistencia: **15 aprobados, 1 omitido**.
- Suite completa del proyecto: **90 aprobados, 36 omitidos**, sin fallos.
- Ejecución real:
  - trabajadores extraídos: **10**
  - turnos extraídos: **3**
  - asistencias procesadas: **30**
  - válidas: **30**
  - errores: **0**
  - warnings: **0**
  - status: **OK**
- Fallo controlado:
  - asistencias procesadas: **30**
  - válidas: **29**
  - errores: **1**
  - warnings: **0**
  - status: **ERROR**
  - etapa: `validate`

## Alcance

Este cierre termina el ETL de Asistencia en la etapa de extracción, staging,
validación y auditoría.

No se incorporan Data Warehouse, dimensiones, hechos, SCD, Power BI ni cambios
en otros dominios. Tampoco se modifican fuentes operacionales, credenciales ni
dependencias del proyecto.
