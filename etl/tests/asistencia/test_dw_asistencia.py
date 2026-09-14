from datetime import date, time
from decimal import Decimal
from pathlib import Path

from etl.load.dw_asistencia import (
    build_fact_rows,
    normalizar_rut,
    resolve_asistencia_dimension_keys,
)
from etl.load.dw_rrhh import rut_dv_valido


def _trabajadores():
    return [
        {
            "trabajador_id": 1,
            "rut": "15.000.984-7",
            "nombre": "Paula",
            "apellido": "Civil",
            "fecha_ingreso": date(2019, 6, 7),
        }
    ]


def _dimensiones():
    return {
        "fechas": {
            date(2026, 7, 27): 20260727,
            date(2026, 7, 28): 20260728,
        },
        "empleados": {
            "15000984-7": [
                {
                    "empleado_key": 10,
                    "area_key": 5,
                    "cargo_key": 7,
                    "centro_costo_key": 5,
                    "fecha_desde": date(2019, 6, 7),
                    "fecha_hasta": date(2026, 7, 28),
                },
                {
                    "empleado_key": 11,
                    "area_key": 6,
                    "cargo_key": 8,
                    "centro_costo_key": 6,
                    "fecha_desde": date(2026, 7, 28),
                    "fecha_hasta": None,
                },
            ]
        },
        "turnos_origen": {1: "TURNO MAÑANA|08:00:00|17:00:00"},
        "turnos_dw": {"TURNO MAÑANA|08:00:00|17:00:00": 2},
    }


def _fila(**overrides):
    row = {
        "asistencia_id": 1,
        "trabajador_id": 1,
        "turno_id": 1,
        "fecha": date(2026, 7, 27),
        "hora_entrada": time(8, 0),
        "hora_salida": time(17, 0),
        "horas_trabajadas": Decimal("8.00"),
        "horas_normales": Decimal("8.00"),
        "horas_extras": Decimal("0.00"),
        "atraso_minutos": 0,
        "ausentismo": 0,
        "estado": "PRESENTE",
    }
    row.update(overrides)
    return row


def test_normalizar_rut_reutiliza_formato_core():
    assert normalizar_rut("15.000.984-7") == "15000984-7"


def test_rut_dv_valido_compartido():
    assert rut_dv_valido("15000984-7") is True
    assert rut_dv_valido("15000984-8") is False


def test_resuelve_empleado_scd2_y_contexto_historico():
    resueltas, rechazadas, review = resolve_asistencia_dimension_keys(
        [_fila()], _trabajadores(), _dimensiones()
    )

    assert rechazadas == []
    assert review == []
    assert len(resueltas) == 1
    assert resueltas[0]["empleado_key"] == 10
    assert resueltas[0]["area_key"] == 5
    assert resueltas[0]["cargo_key"] == 7
    assert resueltas[0]["centro_costo_key"] == 5
    assert resueltas[0]["turno_key"] == 2


def test_frontera_scd2_fecha_hasta_es_exclusiva():
    resueltas, rechazadas, review = resolve_asistencia_dimension_keys(
        [_fila(fecha=date(2026, 7, 28))], _trabajadores(), _dimensiones()
    )

    assert rechazadas == []
    assert review == []
    assert resueltas[0]["empleado_key"] == 11
    assert resueltas[0]["area_key"] == 6


def test_rut_invalido_va_a_review_y_no_se_homologa():
    trabajadores = [{**_trabajadores()[0], "rut": "15.000.984-8"}]
    resueltas, rechazadas, review = resolve_asistencia_dimension_keys(
        [_fila()], trabajadores, _dimensiones()
    )

    assert resueltas == []
    assert rechazadas == []
    assert review[0]["regla"] == "RUT_INVALIDO"


def test_empleado_no_resuelto_va_a_review():
    dimensiones = _dimensiones()
    dimensiones["empleados"] = {}
    resueltas, rechazadas, review = resolve_asistencia_dimension_keys(
        [_fila()], _trabajadores(), dimensiones
    )

    assert resueltas == []
    assert rechazadas == []
    assert review[0]["regla"] == "EMPLEADO_NO_RESUELTO"


def test_turno_no_resuelto_va_a_review():
    dimensiones = _dimensiones()
    dimensiones["turnos_dw"] = {}
    resueltas, rechazadas, review = resolve_asistencia_dimension_keys(
        [_fila()], _trabajadores(), dimensiones
    )

    assert resueltas == []
    assert rechazadas == []
    assert review[0]["regla"] == "TURNO_NO_RESUELTO"


def test_fecha_no_resuelta_es_error():
    resueltas, rechazadas, review = resolve_asistencia_dimension_keys(
        [_fila(fecha=date(2035, 1, 1))], _trabajadores(), _dimensiones()
    )

    assert resueltas == []
    assert review == []
    assert rechazadas[0]["regla"] == "FECHA_NO_RESUELTA"


def test_scd2_ambiguo_es_error():
    dimensiones = _dimensiones()
    dimensiones["empleados"]["15000984-7"].append(
        {
            "empleado_key": 99,
            "area_key": 5,
            "cargo_key": 7,
            "centro_costo_key": 5,
            "fecha_desde": date(2020, 1, 1),
            "fecha_hasta": None,
        }
    )
    resueltas, rechazadas, review = resolve_asistencia_dimension_keys(
        [_fila()], _trabajadores(), dimensiones
    )

    assert resueltas == []
    assert review == []
    assert rechazadas[0]["regla"] == "SCD2_AMBIGUO"


def test_duplicado_rut_fecha_es_rechazado():
    fila_1 = _fila(asistencia_id=1)
    fila_2 = _fila(asistencia_id=2)
    resueltas, rechazadas, review = resolve_asistencia_dimension_keys(
        [fila_1, fila_2], _trabajadores(), _dimensiones()
    )

    assert len(resueltas) == 1
    assert review == []
    assert any(item["regla"] == "DUPLICADO_RUT_FECHA" for item in rechazadas)


def test_build_fact_rows_respeta_semantica_estado():
    resueltas, _, _ = resolve_asistencia_dimension_keys(
        [_fila()], _trabajadores(), _dimensiones()
    )
    fact = build_fact_rows(resueltas)[0]

    assert fact["estado_asistencia"] == "PRESENTE"
    assert fact["dias_trabajados"] == 1
    assert fact["dias_ausentes"] == 0
    assert fact["cantidad_registros"] == 1
    assert fact["horas_trabajadas"] == Decimal("8.00")


def test_sql_fact_protege_idempotencia_por_grano():
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
