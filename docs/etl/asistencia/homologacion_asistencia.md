\# Homologación — Sistema Operacional de Control de Asistencia



\## Objetivo



Documentar los campos candidatos que podrían utilizarse posteriormente para

integrar los datos del Sistema Operacional de Control de Asistencia con otras

fuentes, especialmente RRHH.



Este documento no establece mappings definitivos. La homologación final se

realizará posteriormente durante el hito ETL Core + homologación inicial.



\## Campos candidatos



| Campo origen | Uso candidato | Observación |

|---|---|---|

| `rut` de trabajador | Relacionar trabajador de Asistencia con RRHH | Es la principal clave candidata de integración. |

| `trabajador\_id` | Identificación local del trabajador | Es un identificador propio de Asistencia y no debe compararse directamente con `empleado\_id` de RRHH. |

| `turno\_id` | Identificación local del turno | Corresponde al identificador propio de la fuente de Asistencia. |

| `estado` | Clasificación del estado de asistencia | `PRESENTE`, `ATRASO` y `AUSENTE` pertenecen al dominio de Asistencia. |



\## Consideraciones sobre el RUT



El RUT de Asistencia utiliza el formato local `XX.XXX.XXX-X`.



RRHH podría utilizar otro formato para almacenar el RUT, por lo que una

comparación entre ambas fuentes requerirá una normalización durante la etapa

de homologación.



El RUT no debe modificarse en la fuente operacional solamente para facilitar

la integración.



\## Identificadores locales



`trabajador\_id` corresponde exclusivamente al identificador local de la base

de Asistencia. No se debe asumir que coincide con `empleado\_id` de RRHH.



De igual forma, `turno\_id` corresponde al identificador local de los turnos

de Asistencia.



\## Homologación definitiva



La resolución definitiva de la relación trabajador ↔ empleado y la

homologación de catálogos comunes se realizará posteriormente en ETL Core +

homologación inicial.



En esta etapa solamente se documentan candidatos de integración y no se

establecen equivalencias definitivas.

