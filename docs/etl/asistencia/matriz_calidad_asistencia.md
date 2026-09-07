# Matriz de Calidad — Sistema Operacional de Control de Asistencia

## Objetivo

Documentar los controles de calidad que deben aplicarse a los datos del Sistema Operacional de Control de Asistencia antes de su integración mediante ETL.

| Entidad | Control | Esperado | Clasificación |
|---|---|---|---|
| trabajador | RUT duplicado | 0 filas | ERROR |
| trabajador | Nombre + apellido duplicado | 0 filas en seed actual | WARNING / REVISIÓN |
| trabajador | RUT, nombre, apellido o fecha_ingreso vacíos/NULL | 0 filas | ERROR |
| asistencia | FK trabajador inválida | 0 filas | ERROR |
| asistencia | FK turno inválida | 0 filas | ERROR |
| asistencia | Duplicado trabajador + fecha | 0 filas | ERROR |
| asistencia | Campos obligatorios nulos | 0 filas | ERROR |
| asistencia | Valores negativos | 0 filas | ERROR |
| asistencia | ausentismo fuera de 0/1 | 0 filas | ERROR |
| asistencia | estado fuera de PRESENTE/ATRASO/AUSENTE | 0 filas | ERROR |
| asistencia | PRESENTE/ATRASO sin horario | 0 filas | ERROR |
| asistencia | Ausencia incoherente | 0 filas | ERROR |
| asistencia | Atraso incoherente | 0 filas | ERROR |
| asistencia | horas_extras > horas_trabajadas | 0 filas | ERROR |
| asistencia | horas_trabajadas != horas_normales + horas_extras | 0 filas con tolerancia 0,01 | ERROR |
| asistencia | horas_normales > jornada del turno | 0 filas | ERROR |
| asistencia | fecha anterior a fecha_ingreso | 0 filas | ERROR |
| asistencia | fecha fuera del período de datos del seed | revisar | WARNING / REVISIÓN |
| trabajador | RUT fuera del formato local XX.XXX.XXX-X | 0 filas | ERROR de fuente / REVISIÓN |

## Reglas de calidad

- El RUT del trabajador debe ser único.
- No debe existir más de un registro de asistencia para el mismo trabajador en una fecha.
- Toda asistencia debe apuntar a un trabajador y a un turno existentes.
- Los valores de horas y atraso no deben ser negativos.
- `ausentismo` solo debe contener los valores 0 o 1.
- `estado` solo debe contener `PRESENTE`, `ATRASO` o `AUSENTE`.
- Una ausencia debe ser coherente con la ausencia de horarios, horas trabajadas y atraso.
- Si existe atraso, el estado debe ser `ATRASO`; si el estado es `ATRASO`, debe existir atraso mayor a 0.
- Las horas trabajadas deben corresponder a horas normales más horas extras, con tolerancia de 0,01.
- Las horas normales no deben superar la jornada definida por el turno.
- La fecha de asistencia no puede ser anterior a la fecha de ingreso del trabajador.
- El período de referencia del seed actual corresponde a `2025-01-01`–`2026-07-31`; este rango es una característica del set de prueba, no una regla permanente del negocio.
- El RUT de la fuente utiliza el formato local `XX.XXX.XXX-X` y no debe modificarse en la base operacional.
