import json
from datetime import date
from decimal import Decimal
from pathlib import Path

from etl.load.dw_asistencia import (
    build_fact_rows,
    normalizar_rut,
    rut_dv_valido,
)


FIXTURE = (
    Path(__file__).resolve().parents[1]
    / "fixtures"
    / "asistencia"
    / "asistencia_valida.json"
)


def cargar_fixture():
    with FIXTURE.open(encoding="utf-8-sig") as archivo:
        return json.load(archivo)


def test_normalizar_rut():
    assert normalizar_rut("15.000.984-7") == "15000984-7"


def test_rut_valido():
    assert rut_dv_valido("15.000.984-7") is True


def test_rut_invalido():
    assert rut_dv_valido("15.678.234-9") is False


def test_fixture_contiene_datos_validos():
    fila = cargar_fixture()

    assert fila["rut"] == "15.000.984-7"
    assert fila["fecha"] == "2026-08-24"
    assert fila["estado"] == "PRESENTE"
    assert fila["horas_trabajadas"] == 8.00
    assert fila["horas_normales"] == 8.00
    assert fila["horas_extras"] == 0.00
    assert fila["atraso_minutos"] == 0


def test_build_fact_present():
    fila = cargar_fixture()

    fila["fecha"] = date.fromisoformat(fila["fecha"])
    fila.update(
        {
            "fecha_key": 20260824,
            "empleado_key": 1,
            "area_key": 1,
            "cargo_key": 1,
            "centro_costo_key": 1,
            "turno_key": 3,
        }
    )

    resultado = build_fact_rows([fila])

    assert len(resultado) == 1

    fact = resultado[0]

    assert fact["fecha_key"] == 20260824
    assert fact["empleado_key"] == 1
    assert fact["area_key"] == 1
    assert fact["cargo_key"] == 1
    assert fact["centro_costo_key"] == 1
    assert fact["turno_key"] == 3
    assert fact["estado_asistencia"] == "PRESENTE"
    assert fact["horas_trabajadas"] == Decimal("8.0")
    assert fact["horas_normales"] == Decimal("8.0")
    assert fact["horas_extras"] == Decimal("0")
    assert fact["minutos_atraso"] == 0
    assert fact["dias_trabajados"] == 1
    assert fact["dias_ausentes"] == 0
    assert fact["cantidad_registros"] == 1


def test_grano_empleado_dia():
    fila = cargar_fixture()

    fila["fecha"] = date.fromisoformat(fila["fecha"])
    fila.update(
        {
            "fecha_key": 20260824,
            "empleado_key": 1,
            "area_key": 1,
            "cargo_key": 1,
            "centro_costo_key": 1,
            "turno_key": 3,
        }
    )

    resultado = build_fact_rows([fila])

    claves = {(r["empleado_key"], r["fecha_key"]) for r in resultado}

    assert claves == {(1, 20260824)}
from datetime import date

from etl.load.dw_asistencia import (
    resolve_asistencia_dimension_keys,
)

def test_resolucion_scd2_y_turno_real():
    fila = {
        "asistencia_id": 9001,
        "rut": "15.000.984-7",
        "fecha": date(2026, 8, 24),
        "hora_entrada": None,
        "hora_salida": None,
        "horas_trabajadas": 0,
        "horas_normales": 0,
        "horas_extras": 0,
        "atraso_minutos": 0,
        "ausentismo": 0,
        "estado": "AUSENTE",
        "turno_id": 3,
    }

    resueltas, errores = resolve_asistencia_dimension_keys([fila])

    assert errores == []
    assert len(resueltas) == 1

    resultado = resueltas[0]

    assert resultado["empleado_key"] == 1
    assert resultado["area_key"] == 1
    assert resultado["cargo_key"] == 1
    assert resultado["centro_costo_key"] == 1
    assert resultado["turno_key"] == 3

def test_rut_invalido_es_rechazado():
    fila = {
        "asistencia_id": 9002,
        "rut": "15.678.234-9",
        "fecha": date(2026, 8, 24),
        "hora_entrada": None,
        "hora_salida": None,
        "horas_trabajadas": 0,
        "horas_normales": 0,
        "horas_extras": 0,
        "atraso_minutos": 0,
        "ausentismo": 0,
        "estado": "AUSENTE",
        "turno_id": 3,
    }

    resueltas, errores = resolve_asistencia_dimension_keys([fila])

    assert resueltas == []
    assert any(
        error["regla"] == "RUT_INVALIDO"
        for error in errores
    )


def test_empleado_no_resuelto():
    fila = {
        "asistencia_id": 9003,
        "rut": "12.345.678-5",
        "fecha": date(2026, 8, 24),
        "hora_entrada": None,
        "hora_salida": None,
        "horas_trabajadas": 0,
        "horas_normales": 0,
        "horas_extras": 0,
        "atraso_minutos": 0,
        "ausentismo": 0,
        "estado": "AUSENTE",
        "turno_id": 3,
    }

    resueltas, errores = resolve_asistencia_dimension_keys([fila])

    assert resueltas == []
    assert any(
        error["regla"] == "EMPLEADO_NO_RESUELTO"
        for error in errores
    )

def test_turno_no_resuelto():
    fila = {
        "asistencia_id": 9004,
        "rut": "15.000.984-7",
        "fecha": date(2026, 8, 24),
        "hora_entrada": None,
        "hora_salida": None,
        "horas_trabajadas": 0,
        "horas_normales": 0,
        "horas_extras": 0,
        "atraso_minutos": 0,
        "ausentismo": 0,
        "estado": "AUSENTE",
        "turno_id": 999,
    }

    resueltas, errores = resolve_asistencia_dimension_keys([fila])

    assert resueltas == []
    assert any(
        error["regla"] == "TURNO_NO_RESUELTO"
        for error in errores
    )

def test_ausente_con_horas_es_rechazado():
    fila = {
        "asistencia_id": 9005,
        "rut": "15.000.984-7",
        "fecha": date(2026, 8, 24),
        "hora_entrada": None,
        "hora_salida": None,
        "horas_trabajadas": 8,
        "horas_normales": 8,
        "horas_extras": 0,
        "atraso_minutos": 0,
        "ausentismo": 1,
        "estado": "AUSENTE",
        "turno_id": 3,
    }

    resueltas, errores = resolve_asistencia_dimension_keys([fila])

    assert resueltas == []
    assert any(
        error["regla"] == "AUSENTE_CON_HORAS_TRABAJADAS"
        for error in errores
    )


def test_atraso_sin_minutos_es_rechazado():
    fila = {
        "asistencia_id": 9006,
        "rut": "15.000.984-7",
        "fecha": date(2026, 8, 24),
        "hora_entrada": None,
        "hora_salida": None,
        "horas_trabajadas": 8,
        "horas_normales": 8,
        "horas_extras": 0,
        "atraso_minutos": 0,
        "ausentismo": 0,
        "estado": "ATRASO",
        "turno_id": 3,
    }

    resueltas, errores = resolve_asistencia_dimension_keys([fila])

    assert resueltas == []
    assert any(
        error["regla"] == "ATRASO_SIN_MINUTOS"
        for error in errores
    )


def test_horas_no_cuadran_es_rechazado():
    fila = {
        "asistencia_id": 9007,
        "rut": "15.000.984-7",
        "fecha": date(2026, 8, 24),
        "hora_entrada": None,
        "hora_salida": None,
        "horas_trabajadas": 8,
        "horas_normales": 7,
        "horas_extras": 0,
        "atraso_minutos": 0,
        "ausentismo": 0,
        "estado": "PRESENTE",
        "turno_id": 3,
    }

    resueltas, errores = resolve_asistencia_dimension_keys([fila])

    assert resueltas == []
    assert any(
        error["regla"] == "HORAS_NO_CUADRAN"
        for error in errores
    )


def test_duplicado_rut_fecha_es_rechazado():
    fila1 = {
        "asistencia_id": 9008,
        "rut": "15.000.984-7",
        "fecha": date(2026, 8, 24),
        "hora_entrada": None,
        "hora_salida": None,
        "horas_trabajadas": 0,
        "horas_normales": 0,
        "horas_extras": 0,
        "atraso_minutos": 0,
        "ausentismo": 1,
        "estado": "AUSENTE",
        "turno_id": 3,
    }

    fila2 = {
        **fila1,
        "asistencia_id": 9009,
    }

    resueltas, errores = resolve_asistencia_dimension_keys(
        [fila1, fila2]
    )

    assert len(resueltas) == 1
    assert any(
        error["regla"] == "DUPLICADO_RUT_FECHA"
        for error in errores
    )

def test_scd2_fecha_hasta_es_exclusiva():
    """
    Verifica que fecha_hasta sea exclusiva:
    en la fecha de cambio debe seleccionarse la siguiente versiï¿½n.
    """
    fila = {
        "asistencia_id": 9010,
        "rut": "15.008.765-1",
        "fecha": date(2025, 2, 15),
        "hora_entrada": None,
        "hora_salida": None,
        "horas_trabajadas": 0,
        "horas_normales": 0,
        "horas_extras": 0,
        "atraso_minutos": 0,
        "ausentismo": 1,
        "estado": "AUSENTE",
        "turno_id": 3,
    }

    resueltas, errores = resolve_asistencia_dimension_keys([fila])

    assert errores == []
    assert len(resueltas) == 1

    resultado = resueltas[0]

    assert resultado["empleado_key"] == 18

def test_sql_fact_es_idempotente():
    """
    Verifica que la sentencia de carga de FACT_ASISTENCIA use el grano
    empleado_key + fecha_key como clave de conflicto y actualice el
    registro existente en lugar de insertar un duplicado.
    """
    sql_path = (
        Path(__file__).resolve().parents[2]
        / "sql"
        / "load"
        / "dw"
        / "asistencia"
        / "cargar_fact_asistencia.sql"
    )

    sql = sql_path.read_text(encoding="utf-8").upper()

    assert "ON CONFLICT (EMPLEADO_KEY, FECHA_KEY)" in sql
    assert "DO UPDATE SET" in sql
