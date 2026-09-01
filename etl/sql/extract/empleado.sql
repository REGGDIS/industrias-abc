/* ============================================================================
   extract / empleado.sql
   Dominio:  Contratos y Remuneraciones
   Fuente:   sources/contratos-remuneraciones-sqlserver/sql/schema.sql (dbo.Empleado)
   Motor:    SQL Server
   ----------------------------------------------------------------------------
   Extracción transparente: campos físicos exactos, sin limpieza, sin
   homologación y sin SELECT *. Se conserva empleado_id como identificador
   local de trazabilidad. Empleado NO es la entidad maestra del trabajador
   (esa responsabilidad es de RRHH); esta extracción solo copia la tabla de
   referencia local del dominio Contratos y Remuneraciones.
   ============================================================================ */
SELECT
    empleado_id,
    rut_referencia,
    nombre_completo,
    codigo_area_ref,
    codigo_cargo_ref,
    fecha_ingreso_ref
FROM dbo.Empleado;
