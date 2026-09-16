from datetime import date, time

from etl.validate.asistencia.validator import (
    validate_asistencia,
    validate_asistencias,
    resumen_validacion,
)


def asistencia_valida():
    return {
        "asistencia_id": 1,
        "trabajador_id": 1,
        "turno_id": 1,
        "fecha": date(2026, 7, 1),
        "hora_entrada": time(8, 0),
        "hora_salida": time(17, 0),
        "horas_trabajadas": 8.0,
        "horas_normales": 8.0,
        "horas_extras": 0.0,
        "atraso_minutos": 0,
        "ausentismo": 0,
        "estado": "PRESENTE",
    }


def test_asistencia_valida():
    result = validate_asistencia(
        asistencia_valida(),
        trabajadores_ids={1},
        turnos_ids={1},
    )

    assert result["status"] == "VALID"
    assert result["errors"] == []


def test_horas_trabajadas_negativas():
    row = asistencia_valida()
    row["horas_trabajadas"] = -1

    result = validate_asistencia(row)

    assert result["status"] == "ERROR"
    assert "horas_trabajadas negativas" in result["errors"]


def test_horas_extras_mayores_que_trabajadas():
    row = asistencia_valida()
    row["horas_extras"] = 9

    result = validate_asistencia(row)

    assert result["status"] == "ERROR"
    assert "horas_extras mayores que horas_trabajadas" in result["errors"]


def test_estado_invalido():
    row = asistencia_valida()
    row["estado"] = "OTRO"

    result = validate_asistencia(row)

    assert result["status"] == "ERROR"
    assert "estado inválido" in result["errors"]


def test_ausente_con_horario():
    row = asistencia_valida()
    row["estado"] = "AUSENTE"
    row["ausentismo"] = 1
    row["hora_entrada"] = None
    row["hora_salida"] = None
    row["horas_trabajadas"] = 0
    row["horas_normales"] = 0
    row["horas_extras"] = 0

    result = validate_asistencia(row)

    assert result["status"] == "VALID"


def test_atraso_debe_tener_minutos():
    row = asistencia_valida()
    row["estado"] = "ATRASO"
    row["atraso_minutos"] = 0

    result = validate_asistencia(row)

    assert result["status"] == "ERROR"
    assert "ATRASO con atraso_minutos no positivo" in result["errors"]


def test_presente_con_atraso_es_incoherente():
    row = asistencia_valida()
    row["estado"] = "PRESENTE"
    row["atraso_minutos"] = 10

    result = validate_asistencia(row)

    assert result["status"] == "ERROR"
    assert "PRESENTE con atraso_minutos positivo" in result["errors"]


def test_trabajador_inexistente():
    result = validate_asistencia(
        asistencia_valida(),
        trabajadores_ids={2},
        turnos_ids={1},
    )

    assert result["status"] == "ERROR"
    assert "trabajador_id inexistente" in result["errors"]


def test_turno_inexistente():
    result = validate_asistencia(
        asistencia_valida(),
        trabajadores_ids={1},
        turnos_ids={2},
    )

    assert result["status"] == "ERROR"
    assert "turno_id inexistente" in result["errors"]


def test_duplicado_trabajador_fecha():
    row1 = asistencia_valida()
    row2 = asistencia_valida()
    row2["asistencia_id"] = 2

    results = validate_asistencias(
        [row1, row2],
        trabajadores_ids={1},
        turnos_ids={1},
    )

    assert results[0]["status"] == "VALID"
    assert results[1]["status"] == "ERROR"
    assert "duplicado trabajador + fecha" in results[1]["errors"]


def test_resumen_validacion():
    valido = asistencia_valida()

    invalido = asistencia_valida()
    invalido["asistencia_id"] = 2
    invalido["horas_trabajadas"] = -1

    results = validate_asistencias(
        [valido, invalido],
        trabajadores_ids={1},
        turnos_ids={1},
    )

    resumen = resumen_validacion(results)

    assert resumen["procesados"] == 2
    assert resumen["validos"] == 1
    assert resumen["errores"] == 1
    assert len(resumen["detalle"]) == 1