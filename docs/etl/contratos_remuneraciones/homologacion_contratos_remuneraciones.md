# Homologación — Contratos y Remuneraciones (candidatos, no definitiva)

**Dominio:** Contratos y Remuneraciones
**Responsable:** Luis Figueroa
**Motor de origen:** SQL Server

Este documento identifica **candidatos** de homologación entre el dominio Contratos y Remuneraciones y otras fuentes del proyecto (RRHH, Asistencia, Compras, Contabilidad, Universo Empresarial Master). **No declara equivalencias definitivas ni mappings finales**: esa responsabilidad corresponde a ETL Core, que tiene visibilidad transversal de todos los dominios.

| Campo | Uso candidato | Posible relación | Limitación |
|---|---|---|---|
| `Empleado.rut_referencia` | Principal candidato de identidad de persona | RRHH / Asistencia | Debe normalizarse (formato con/sin puntos y guion) y validarse; no declarar match solo por coincidencia de formato. En staging se genera `rut_referencia_normalizado` únicamente como apoyo a esa comparación futura. |
| `Empleado.empleado_id` | Referencia local / posible código empresarial | Universo Empresarial Master | No asumir que equivale al `empleado_id` (o su equivalente) de otra base; es un identificador propio de este dominio, copiado del Master solo para poblar datos coherentes. |
| `Empleado.codigo_area_ref` | Candidato de área | RRHH / Contabilidad / Compras / Universo Empresarial Master | La igualdad textual del código debe validarse en ETL Core; nombres o catálogos de área pueden diferir entre fuentes. |
| `Empleado.codigo_cargo_ref` | Candidato de cargo | RRHH / Universo Empresarial Master | Puede haber catálogos de cargo distintos o nomenclaturas distintas entre RRHH y esta referencia local. |
| `Contrato.numero_contrato` | Clave de negocio interna del contrato | Dominio Contratos y Remuneraciones (uso interno) | No es un identificador transversal de empleado; solo identifica el contrato dentro de este dominio. |
| `ConceptoPago.codigo` | Candidato a catálogo común de conceptos de remuneración | Remuneraciones / futuros catálogos BI | Solo se homologa si ETL Core define equivalencias explícitas con catálogos contables u otros dominios. |
| `Liquidacion.periodo` | Dominio temporal YYYY-MM | Futura `DIM_FECHA` / período BI | No se crea ninguna dimensión de tiempo en esta etapa; el campo solo se conserva limpio y en su formato original. |

## Nota importante sobre `Empleado`

La tabla `dbo.Empleado` de este dominio **fue creada para apoyar Contratos y Remuneraciones**, copiando datos del Universo Empresarial Master v0.2 para poder construir contratos y liquidaciones de prueba coherentes con el resto del equipo. **No es, y no debe tratarse como, la ficha maestra del trabajador** — esa responsabilidad pertenece al dominio RRHH.

Por lo tanto, la homologación definitiva "trabajador ↔ empleado" (es decir, decidir qué identificador usar como clave transversal de persona en el Data Warehouse) **se cierra posteriormente en ETL Core**, con visibilidad sobre RRHH, Asistencia y esta fuente en conjunto. Este documento únicamente dejó registrados los campos candidatos y sus limitaciones conocidas.
