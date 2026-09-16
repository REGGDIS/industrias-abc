# Industrias ABC — Business Intelligence

Proyecto integrador de **Business Intelligence** para una empresa industrial ficticia, desarrollado en el módulo **BUSINESS INTELLIGENCE — ISI802_83-0-2026-081-PRE (AIEP, 2026)**.

## Objetivo

Construir una solución BI completa a partir de múltiples sistemas operacionales heterogéneos, integrando datos mediante procesos ETL/ELT hacia un Data Warehouse dimensional y una capa de explotación analítica mediante una aplicación web.

## Sistemas operacionales

El proyecto integra los siguientes dominios:

- Recursos Humanos — PostgreSQL
- Control de Asistencia — MySQL
- Contratos — SQL Server
- Remuneraciones — SQL Server
- Compras y Abastecimiento — PostgreSQL
- Contabilidad — PostgreSQL
- Producción — MySQL + CSV

Cada sistema mantiene su independencia operacional. La integración se realiza mediante procesos de extracción, validación, homologación, transformación y carga hacia el Data Warehouse.

## Arquitectura general

```text
Fuentes operacionales
        |
        v
     ETL / ELT
        |
        v
Data Warehouse PostgreSQL
        |
        v
   API FastAPI
        |
        v
Aplicación React / Vite
```

La aplicación web no accede directamente al Data Warehouse.

## Estructura principal del repositorio

- `apps/api/`: API BI desarrollada con FastAPI.
- `apps/web/`: aplicación web React + Vite + TypeScript.
- `etl/`: procesos de extracción, transformación, validación, homologación y carga.
- `sources/`: fuentes operacionales por dominio.
- `staging/`: estructuras y recursos temporales de integración.
- `data-warehouse/`: modelo dimensional y scripts del Data Warehouse.
- `docs/`: documentación técnica.
- `powerbi/`: recursos asociados a explotación analítica.

## Aplicación web

La aplicación incluye los módulos:

- Dashboard Ejecutivo
- Recursos Humanos
- Asistencia
- Contratos
- Remuneraciones
- Compras
- Contabilidad
- Producción
- Análisis Integrado
- Calidad de Datos
- Monitoreo ETL

La capa frontend soporta dos modos de ejecución:

```env
VITE_DATA_MODE=mock
```

o:

```env
VITE_DATA_MODE=api
VITE_API_URL=http://localhost:8000/api
```

Para la validación integrada final se utiliza el modo `api`.

## API

La API se encuentra en:

```text
apps/api
```

Ejemplo de ejecución:

```powershell
cd apps/api
python -m uvicorn src.main:app --reload --host 127.0.0.1 --port 8000
```

Endpoint de salud:

```text
GET http://localhost:8000/api/health
```

## Frontend

La aplicación web se encuentra en:

```text
apps/web
```

Ejemplo de ejecución:

```powershell
cd apps/web
npm install
npm run dev
```

Por defecto Vite utiliza:

```text
http://localhost:5173
```

## Data Warehouse

El entorno de desarrollo utiliza PostgreSQL para el Data Warehouse.

Configuración de referencia:

```env
DW_DB_HOST=localhost
DW_DB_PORT=5437
DW_DB_NAME=industrias_abc_dw
DW_DB_USER=dw_user
DW_DB_PASSWORD=
```

Las contraseñas reales deben mantenerse únicamente en archivos `.env` locales y nunca deben incorporarse al repositorio.

## Roles de demostración

La aplicación implementa control de navegación y rutas por rol para fines académicos.

Roles disponibles:

- `ADMIN`
- `GERENCIA`
- `RRHH`
- `COMPRAS`
- `CONTABILIDAD`
- `PRODUCCION`

Matriz resumida:

| Rol          | Acceso principal                                        |
| ------------ | ------------------------------------------------------- |
| ADMIN        | Todos los módulos                                       |
| GERENCIA     | Dashboard y Análisis Integrado                          |
| RRHH         | Dashboard, RRHH, Asistencia, Contratos y Remuneraciones |
| COMPRAS      | Dashboard y Compras                                     |
| CONTABILIDAD | Dashboard y Contabilidad                                |
| PRODUCCION   | Dashboard y Producción                                  |

Las credenciales incluidas en el frontend corresponden exclusivamente a usuarios de demostración académica.

> El control de acceso actual se implementa en el frontend para demostrar roles, sesión y navegación. No corresponde a un mecanismo de seguridad productivo ni reemplaza autorización en el backend.

## Calidad de Datos

La solución incluye controles reales sobre el Data Warehouse.

Se mantienen explícitamente como pendientes de homologación semántica algunos datos de Producción, especialmente Área y Centro de Costo, cuando no existe evidencia suficiente para establecer una equivalencia de negocio válida.

Estos casos se presentan como observaciones de calidad y no se corrigen mediante asignaciones artificiales.

## Monitoreo ETL

La aplicación consulta la auditoría real de los procesos ETL.

Los pipelines operacionales monitoreados corresponden a:

- RRHH
- Asistencia
- Contratos y Remuneraciones
- Compras
- Contabilidad
- Producción

## Validación E2E

Durante el cierre técnico se validaron:

- compilación del backend;
- build de producción del frontend;
- comunicación Frontend → API → Data Warehouse;
- endpoint de salud;
- endpoints BI por dominio;
- Dashboard;
- Análisis Integrado;
- Calidad de Datos;
- Monitoreo ETL;
- login y logout;
- restricciones de navegación por rol;
- redirección ante rutas no autorizadas.

El smoke test del backend obtuvo respuesta HTTP `200` en los 12 endpoints principales evaluados.

Períodos utilizados durante la validación:

- RRHH, Asistencia, Contratos, Remuneraciones, Compras y Producción: 2026.
- Contabilidad: 2025, correspondiente al período disponible actualmente en el DW.

## Flujo Git

Las ramas principales son:

- `main`: versión estable del proyecto.
- `develop`: rama de integración.

Las funcionalidades se desarrollan mediante ramas `feature/*` y se incorporan a `develop` mediante Pull Request.

## Estado

La solución BI integrada se encuentra en etapa de cierre técnico y validación final.
