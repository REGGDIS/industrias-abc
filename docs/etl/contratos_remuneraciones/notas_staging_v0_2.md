Notas de staging — Contratos y Remuneraciones (v0.2)
Flujo implementado
dbo.Empleado / dbo.Contrato / dbo.Liquidacion   (operacional, SQL Server)
        │  etl/sql/extract/contratos_remuneraciones/*.sql   (SELECT transparente)
        ▼
raw.contratos_remuneraciones_*                  (tabla física RAW)
        │  etl/sql/load/contratos_remuneraciones/*.sql      (TRUNCATE + INSERT)
        ▼
staging.contratos_remuneraciones_*              (VISTA persistente, limpieza superficial)
        │  etl/sql/staging/contratos_remuneraciones/*.sql   (CREATE OR ALTER VIEW)
        ▼
etl/validate/contratos_remuneraciones.py        (validación de reglas mínimas)
Orden de ejecución
sources/contratos-remuneraciones-sqlserver/sql/schema.sql y seed.sql (si no se ha creado la base operacional).
etl/sql/load/contratos_remuneraciones/empleado.sql, contrato.sql, liquidacion.sql — crean el esquema raw y materializan los datos crudos.
etl/sql/staging/contratos_remuneraciones/empleado.sql, contrato.sql, liquidacion.sql — crean el esquema staging y las vistas limpias, leyendo desde raw.*.
python etl/validate/contratos_remuneraciones.py — valida las vistas de staging.
Por qué RAW es una tabla física y STAGING es una vista
RAW necesita ser una tabla física porque representa una foto del dato en un momento dado (con raw_loaded_at), independiente de que la fuente operacional siga cambiando.
STAGING se implementó como vista (no tabla) porque la limpieza aplicada es determinística y barata de recalcular (TRIM, UPPER, NULLIF); así siempre refleja el estado más reciente de RAW sin necesidad de un paso de carga adicional. Si más adelante el volumen de datos lo justifica, puede materializarse como tabla sin cambiar la lógica de limpieza.
Qué NO se hizo aquí (fuera de alcance del Encargo 0.2)
No se homologó rut_referencia con RRHH/Asistencia (rut_referencia_normalizado es solo un candidato de comparación).
No se creó ninguna dimensión ni tabla de hechos.
No se tocaron concepto_pago ni detalle_liquidacion (fuera del alcance de esta iteración; sus scripts de v0.1 siguen vigentes en etl/sql/extract/ y etl/sql/staging/, sin flujo RAW propio todavía).
No se decidió si un contrato vencido debe cambiar automáticamente su estado a TERMINADO: se dejó como columna derivada (contrato_vencido) para que el equipo lo revise, en vez de modificar el dato silenciosamente.
