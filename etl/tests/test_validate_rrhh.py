from datetime import date

from etl.validate.rrhh import validate_empleado


def empleado_valido():
    return {
        "empleado_id": 1,
        "rut": "15000984-7",
        "nombres": "PAULA",
        "apellido_paterno": "CIVIL",
        "apellido_materno": "MARTÍNEZ",
        "fecha_nacimiento": date(2002, 2, 1),
        "sexo": "F",
        "nacionalidad": "CHILENA",
        "fecha_ingreso": date(2019, 6, 7),
        "fecha_salida": None,
        "area_id": 1,
        "cargo_id": 1,
        "estado": "ACTIVO",
    }


def test_empleado_valido():
    result = validate_empleado(empleado_valido())

    assert result["status"] == "VALID"
    assert result["errors"] == []
    assert result["warnings"] == []


def test_rut_invalido():
    row = empleado_valido()
    row["rut"] = "123"

    result = validate_empleado(row)

    assert result["status"] == "ERROR"
    assert "rut con formato inválido" in result["errors"]


def test_fecha_salida_anterior_ingreso():
    row = empleado_valido()
    row["fecha_salida"] = date(2018, 1, 1)
    row["estado"] = "INACTIVO"

    result = validate_empleado(row)

    assert result["status"] == "ERROR"
    assert "fecha_salida anterior a fecha_ingreso" in result["errors"]


def test_activo_con_fecha_salida():
    row = empleado_valido()
    row["fecha_salida"] = date(2026, 1, 1)

    result = validate_empleado(row)

    assert result["status"] == "ERROR"
    assert "empleado con fecha_salida no puede estar ACTIVO" in result["errors"]


def test_apellido_materno_ausente_es_warning():
    row = empleado_valido()
    row["apellido_materno"] = None

    result = validate_empleado(row)

    assert result["status"] == "WARNING"
    assert "apellido_materno ausente" in result["warnings"]
