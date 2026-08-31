from etl.transform.rut import normalize_rut


def _clean_text(value: str | None) -> str | None:
    if value is None:
        return None

    value = value.strip()

    if value == "":
        return None

    return value.upper()


def transform_empleado(row: dict) -> dict:
    return {
        "empleado_id": row["empleado_id"],
        "rut": normalize_rut(row["rut"]),
        "nombres": _clean_text(row["nombres"]),
        "apellido_paterno": _clean_text(row["apellido_paterno"]),
        "apellido_materno": _clean_text(row["apellido_materno"]),
        "fecha_nacimiento": row["fecha_nacimiento"],
        "sexo": _clean_text(row["sexo"]),
        "nacionalidad": _clean_text(row["nacionalidad"]),
        "fecha_ingreso": row["fecha_ingreso"],
        "fecha_salida": row["fecha_salida"],
        "area_id": row["area_id"],
        "cargo_id": row["cargo_id"],
        "estado": _clean_text(row["estado"]),
    }


def transform_empleados(rows: list[dict]) -> list[dict]:
    return [transform_empleado(row) for row in rows]
