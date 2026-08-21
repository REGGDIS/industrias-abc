# Industrias ABC — Business Intelligence

Proyecto integrador de **Business Intelligence** para una empresa industrial ficticia, desarrollado en el módulo **BUSINESS INTELLIGENCE — ISI802_83-0-2026-081-PRE (AIEP, 2026)**.

## Objetivo

Construir una solución BI completa a partir de múltiples sistemas operacionales heterogéneos, integrando datos mediante procesos ETL/ELT hacia un Data Warehouse y una capa de explotación analítica con Power BI y una aplicación de visualización.

## Sistemas operacionales

El proyecto considera los **7 sistemas operacionales** definidos para Industrias ABC:

- Recursos Humanos — PostgreSQL
- Control de Asistencia — MySQL
- Contratos — SQL Server
- Remuneraciones — SQL Server
- Compras y Abastecimiento — PostgreSQL
- Contabilidad — PostgreSQL
- Producción — MySQL + CSV

Cada sistema de origen mantiene su independencia y podrá utilizar identificadores, formatos y estructuras propias. La integración entre fuentes se realizará posteriormente mediante procesos de homologación, calidad de datos y ETL/ELT.

## Estructura del repositorio

- `docs/`: documentación técnica mínima del proyecto.
- `sources/rrhh-postgresql/`: fuente operacional de Recursos Humanos.
- `sources/asistencia-mysql/`: fuente operacional de Control de Asistencia.
- `sources/contratos-remuneraciones-sqlserver/`: fuentes operacionales de Contratos y Remuneraciones.
- `sources/compras-postgresql/`: fuente operacional de Compras y Abastecimiento.
- `sources/contabilidad-postgresql/`: fuente operacional de Contabilidad.
- `sources/produccion-mysql-csv/`: fuente operacional de Producción.
- `etl/`: procesos de extracción, transformación, validación, homologación y carga.
- `staging/`: estructuras y recursos de integración temporal.
- `data-warehouse/`: modelo dimensional, scripts y objetos del Data Warehouse.
- `powerbi/`: archivos y recursos de visualización Power BI.
- `app/`: aplicación de visualización o consulta.

## Flujo de trabajo

El desarrollo avanza desde los requisitos oficiales y modelos conceptuales hacia modelos lógicos/ERD, implementación de fuentes operacionales, integración ETL/ELT, Data Warehouse y explotación BI.

Las ramas principales son:

- `main`: versión estable e integrada del proyecto.
- `develop`: rama de integración del trabajo del equipo.

Ramas de dominio:

- `feature/rrhh`
- `feature/contabilidad`
- `feature/asistencia`
- `feature/contratos-remuneraciones`
- `feature/compras`
- `feature/produccion`

Cada integrante desarrolla en su rama de dominio y, cuando una etapa está terminada y revisada, abre un **Pull Request hacia `develop`**. Las integraciones estables se incorporarán posteriormente desde `develop` hacia `main`.

## Equipo

- Roberto González — Recursos Humanos, Contabilidad y coordinación
- Raymond Civil — Compras y Abastecimiento
- Luis Figueroa — Contratos y Remuneraciones
- Esteban Osses — Control de Asistencia
- Joaquín Medina — Producción
