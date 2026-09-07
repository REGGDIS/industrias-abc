"""
ETL Compras 0.5 · Pruebas del cierre/auditoría de ejecución
Proyecto: Business Intelligence - Industrias ABC (Equipo BInnova)
Dominio: Compras · Responsable: Raymond Civil

Cubre: fallo sin BD (con saneo de credenciales), run_id único, corrida OK
(métricas reales) y falla controlada. Las pruebas que requieren BD se omiten
si no hay COMPRAS_DB_* configurado (integración, como el resto del ETL).
"""
import json
import os
import shutil
import uuid

import pytest

from etl.validate.compras import runner


def _db_configurada() -> bool:
    variables_ok = all(
        os.getenv(f"COMPRAS_DB_{k}") not in (None, "")
        for k in ("HOST", "PORT", "NAME", "USER")
    )

    return variables_ok and shutil.which("psql") is not None


requiere_bd = pytest.mark.skipif(
    not _db_configurada(), reason="Requiere COMPRAS_DB_* y el cliente psql"
)


def test_fallo_no_registra_credenciales(tmp_path):
    """Un fallo inesperado deja status ERROR y NO persiste posibles secretos."""
    def psql_con_secreto(conninfo, password, sql_path):
        raise RuntimeError("password=NO-DEBE-QUEDAR-REGISTRADO")

    path = tmp_path / "fallo.json"
    report = runner.run(path, psql_fn=psql_con_secreto)
    guardado = json.loads(path.read_text(encoding="utf-8"))

    assert guardado == report
    assert report["status"] == "ERROR"
    assert report["stage"] is not None
    assert report["duration_seconds"] >= 0
    assert report["finished_at"] >= report["started_at"]
    uuid.UUID(report["run_id"])
    assert "NO-DEBE-QUEDAR-REGISTRADO" not in path.read_text(encoding="utf-8")


def test_run_id_unico(tmp_path):
    def psql_falla(conninfo, password, sql_path):
        raise RuntimeError("no disponible")

    r1 = runner.run(tmp_path / "a.json", psql_fn=psql_falla)
    r2 = runner.run(tmp_path / "b.json", psql_fn=psql_falla)
    assert r1["run_id"] != r2["run_id"]


@requiere_bd
def test_corrida_ok(tmp_path):
    report = runner.run(tmp_path / "ok.json")

    assert report["status"] == "OK"
    assert report["error"] is None
    assert report["stage"] is None
    assert report["proceso"] == "compras_etl"
    # métricas reales y coherentes
    assert report["procesados"] == report["validos"] + report["review"] + report["errores"]
    # etapas: todas OK
    assert report["etapas"] and all(e["resultado"] == "OK" for e in report["etapas"])
    # tiempos
    assert report["duracion_ms"] >= 0 and report["finished_at"] >= report["started_at"]


@requiere_bd
def test_falla_controlada(tmp_path):
    rota = tmp_path / "rota.sql"
    rota.write_text("SELECT * FROM tabla_que_no_existe_cierre;\n", encoding="utf-8")
    stages = [("etapa_rota", rota)]

    report = runner.run(tmp_path / "err.json", stages=stages)

    assert report["status"] == "ERROR"
    assert report["stage"] == "etapa_rota"
    assert report["error"] is not None and "exit" in report["error"]
    assert report["etapas"][-1]["resultado"] == "ERROR"

def test_calidad_con_revision_no_bloquea(tmp_path):
    normalizacion = tmp_path / "normalizacion.sql"
    calidad = tmp_path / "calidad.sql"
    pruebas = tmp_path / "pruebas.sql"

    for path in (normalizacion, calidad, pruebas):
        path.write_text("SELECT 1;\n", encoding="utf-8")

    stages = [
        ("normalizacion", normalizacion),
        ("validaciones_calidad", calidad),
        ("pruebas_normalizacion", pruebas),
    ]

    def psql_simulado(conninfo, password, sql_path):
        if sql_path == normalizacion:
            return 0, "TOTAL|120|120|0|0\n", ""

        if sql_path == calidad:
            return 0, "TOTAL|55|53|2|0\n", ""

        return 0, "", ""

    report = runner.run(
        tmp_path / "calidad_review.json",
        stages=stages,
        psql_fn=psql_simulado,
    )

    assert report["status"] == "OK"
    assert report["stage"] is None

    assert report["normalizacion"] == {
        "procesados": 120,
        "normalizados": 120,
        "review": 0,
        "errores": 0,
    }

    assert report["calidad"] == {
        "procesados": 55,
        "validos": 53,
        "review": 2,
        "errores": 0,
    }

    assert report["procesados"] == 55
    assert report["validos"] == 53
    assert report["review"] == 2
    assert report["errores"] == 0
    assert report["controles_error"] == 0


def test_calidad_con_error_bloquea_cierre(tmp_path):
    normalizacion = tmp_path / "normalizacion.sql"
    calidad = tmp_path / "calidad.sql"

    for path in (normalizacion, calidad):
        path.write_text("SELECT 1;\n", encoding="utf-8")

    stages = [
        ("normalizacion", normalizacion),
        ("validaciones_calidad", calidad),
    ]

    def psql_simulado(conninfo, password, sql_path):
        if sql_path == normalizacion:
            return 0, "TOTAL|120|120|0|0\n", ""

        return 0, "TOTAL|55|52|2|1\n", ""

    report = runner.run(
        tmp_path / "calidad_error.json",
        stages=stages,
        psql_fn=psql_simulado,
    )

    assert report["status"] == "ERROR"
    assert report["stage"] == "validaciones_calidad"

    assert report["procesados"] == 55
    assert report["validos"] == 52
    assert report["review"] == 2
    assert report["errores"] == 1
    assert report["controles_error"] == 1

    assert report["etapas"][-1]["nombre"] == "validaciones_calidad"
    assert report["etapas"][-1]["resultado"] == "ERROR"

    assert report["error"] == (
        "Se detectaron registros con errores "
        "en los controles de calidad de Compras."
    )
