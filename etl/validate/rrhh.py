import re
from datetime import date


RUT_PATTERN = re.compile(r"^[0-9]{7,8}-[0-9K]$")

ESTADOS_VALIDOS = {"ACTIVO", "INACTIVO"}


def validate_empleado(row: dict) -> dict:
    errors = []
    warnings = []

    # Identificador de origen
    if row.get("empleado_id") is None:
        errors.append("empleado_id ausente")

    # RUT
    rut = row.get("rut")

    if not rut:
        errors.append("rut ausente")
    elif not RUT_PATTERN.fullmatch(rut):
        errors.append("rut con formato inválido")

    # Nombre
    if not row.get("nombres"):
        errors.append("nombres ausentes")

    if not row.get("apellido_paterno"):
        errors.append("apellido_paterno ausente")

    if not row.get("apellido_materno"):
        warnings.append("apellido_materno ausente")

    # Fechas
    fecha_ingreso = row.get("fecha_ingreso")
    fecha_salida = row.get("fecha_salida")

    if not isinstance(fecha_ingreso, date):
        errors.append("fecha_ingreso inválida")

    if fecha_salida is not None and not isinstance(fecha_salida, date):
        errors.append("fecha_salida inválida")

    if (
        isinstance(fecha_ingreso, date)
        and isinstance(fecha_salida, date)
        and fecha_salida < fecha_ingreso
    ):
        errors.append("fecha_salida anterior a fecha_ingreso")

    # Relaciones locales
    if row.get("area_id") is None:
        errors.append("area_id ausente")

    if row.get("cargo_id") is None:
        errors.append("cargo_id ausente")

    # Estado
    estado = row.get("estado")

    if estado not in ESTADOS_VALIDOS:
        errors.append("estado inválido")

    if fecha_salida is not None and estado == "ACTIVO":
        errors.append("empleado con fecha_salida no puede estar ACTIVO")

    # Campos opcionales
    if not row.get("sexo"):
        warnings.append("sexo ausente")

    if not row.get("nacionalidad"):
        warnings.append("nacionalidad ausente")

    if errors:
        status = "ERROR"
    elif warnings:
        status = "WARNING"
    else:
        status = "VALID"

    return {
        "status": status,
        "errors": errors,
        "warnings": warnings,
        "record": row,
    }


def validate_empleados(rows: list[dict]) -> list[dict]:
    return [validate_empleado(row) for row in rows]
