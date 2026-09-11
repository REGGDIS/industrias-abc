# Industrias ABC - Aplicación BI

## Estado

Frontend en desarrollo para la solución de Business Intelligence de Industrias ABC.

Versión actual:
- Hito App 0
- Contratos base y estructura frontend
- Modo inicial: mock
- Sin conexión todavía al Data Warehouse real

## Objetivo

Construir una aplicación web para visualizar indicadores, dashboards, filtros,
detalle de información, análisis integrado, calidad de datos y auditoría ETL.

La aplicación final consumirá información consolidada desde un Data Warehouse
a través de una API BI.

## Stack

- React
- Vite
- TypeScript
- React Router
- ESLint

Tecnologías visuales adicionales se incorporarán en hitos posteriores.

## Arquitectura funcional

Sistemas operacionales
-> ETL / Validación / Homologación
-> Data Warehouse
-> API BI
-> Frontend React

Durante la etapa actual:

Mocks
-> Servicios
-> Frontend React

## Modos de datos

El frontend debe soportar dos modos:

VITE_DATA_MODE=mock

VITE_DATA_MODE=api

Configuración:

VITE_DATA_MODE=mock
VITE_API_URL=http://localhost:8000/api

Las páginas no deben importar mocks directamente.

Flujo correcto:

Página
-> Service
-> MockService o ApiService

## Estructura principal

src/
- app/
- config/
- mocks/
- services/
  - contracts/
- types/
- utils/

## Pantallas previstas

1. Inicio de sesión
2. Dashboard Ejecutivo
3. Recursos Humanos
4. Asistencia
5. Contratos
6. Remuneraciones
7. Compras
8. Contabilidad
9. Producción
10. Calidad de Datos
11. Análisis Integrado
12. Procesos ETL / Administración

## Contratos base

El frontend ya define contratos para:

- Dashboard
- Recursos Humanos
- Asistencia
- Contratos
- Remuneraciones
- Compras
- Contabilidad
- Producción
- Calidad
- Auditoría ETL
- Análisis Integrado

## Filtros transversales

- Año
- Mes
- Fecha
- Área
- Centro de costo
- Trabajador
- Cargo
- Proveedor
- Insumo
- Producto
- Cuenta contable

## Auditoría ETL

El contrato de auditoría contempla actualmente:

- extraídos
- insertados
- actualizados
- sin cambios
- REVIEW
- rechazados
- errores
- estado de ejecución

## Regla de desarrollo

No se debe implementar ni modificar lógica ETL->DW correspondiente a dominios
asignados a otros integrantes mientras esas entregas estén pendientes.

El frontend puede:

- definir contratos de datos;
- definir mocks;
- definir filtros;
- definir visualizaciones;
- especificar necesidades futuras del Data Warehouse;
- preparar servicios para consumir la API futura.

El frontend no debe:

- sustituir ETL->DW pendientes;
- consultar directamente bases operacionales;
- replicar lógica de transformación del ETL;
- incorporar reglas de integración que correspondan al Data Warehouse.

## Convenciones

Componentes React:
PascalCase

Ejemplo:
KpiCard.tsx
DashboardPage.tsx

Tipos:
PascalCase

Ejemplo:
BiFilters
DashboardResumen

Variables:
camelCase

Endpoints:
kebab-case

Ejemplo:
/api/asistencia/horas-extras-por-area

## Validación

Antes de integrar cambios:

npm run build
npm run lint

Ambos comandos deben finalizar sin errores.

## Siguiente hito

Hito App 1:
- Layout general
- Router
- Sidebar
- Header
- Navegación por rol
- Selector mock/api
- Pantallas base
