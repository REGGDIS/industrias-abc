DROP TABLE IF EXISTS stg_rrhh_empleados_raw;

CREATE TABLE stg_rrhh_empleados_raw (
    empleado_id INTEGER,
    rut VARCHAR(20),
    nombres VARCHAR(100),
    apellido_paterno VARCHAR(60),
    apellido_materno VARCHAR(60),
    fecha_nacimiento DATE,
    sexo VARCHAR(20),
    nacionalidad VARCHAR(50),
    fecha_ingreso DATE,
    fecha_salida DATE,
    area_id INTEGER,
    cargo_id INTEGER,
    estado VARCHAR(20)
);