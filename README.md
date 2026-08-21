# Industrias ABC — Business Intelligence

Proyecto integrador de **Business Intelligence** para una empresa industrial ficticia, desarrollado en el módulo **BUSINESS INTELLIGENCE — ISI802_83-0-2026-081-PRE (AIEP, 2026)**.

## Objetivo

Construir una solución BI completa a partir de múltiples sistemas operacionales heterogéneos, integrando datos mediante procesos ETL/ELT hacia un Data Warehouse y una capa de explotación analítica con Power BI y una aplicación de visualización.

## Sistemas operacionales

- Recursos Humanos — PostgreSQL
- Control de Asistencia — MySQL
- Contratos y Remuneraciones — SQL Server
- Compras y Abastecimiento — PostgreSQL
- Producción — MySQL + CSV

## Estructura del repositorio

- `docs/`: documentación técnica mínima del proyecto.
- `sources/`: sistemas operacionales por dominio.
- `etl/`: procesos de extracción, transformación, validación, homologación y carga.
- `staging/`: estructuras y recursos de integración temporal.
- `data-warehouse/`: modelo dimensional, scripts y objetos del Data Warehouse.
- `powerbi/`: archivos y recursos de visualización Power BI.
- `app/`: aplicación de visualización o consulta.

## Flujo de trabajo

El desarrollo avanza desde los requisitos oficiales y modelos conceptuales hacia modelos lógicos/ERD, implementación de fuentes operacionales, integración ETL/ELT, Data Warehouse y explotación BI.

## Equipo

- Roberto González — Recursos Humanos / coordinación
- Raymond Civil — Compras y Abastecimiento
- Luis Figueroa — Contratos y Remuneraciones
- Esteban Osses — Control de Asistencia
- Joaquín Medina — Producción
