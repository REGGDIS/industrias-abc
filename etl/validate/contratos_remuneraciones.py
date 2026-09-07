"""
etl/validate/contratos_remuneraciones.py

Dominio: Contratos y Remuneraciones
Encargo: Contratos/Remuneraciones 0.2

Valida las vistas de staging (staging.contratos_remuneraciones_empleado,
staging.contratos_remuneraciones_contrato,
staging.contratos_remuneraciones_liquidacion) contra las reglas mínimas
de calidad de la sección 3 del encargo:

    Regla                                       Tratamiento
    ------------------------------------------  -----------
    Contrato con fecha_inicio > fecha_termino    ERROR
    Contrato vencido (fecha_termino en pasado,   WARNING
    pero estado = VIGENTE)
    Liquidación sin empleado asociado            ERROR
    RUT nulo o claramente inválido                ERROR
    Montos negativos donde no corresponda        ERROR
    Texto con espacios extremos / estados         CLEAN (evidencia,
    inconsistentes                                ya resuelto en staging)

Diseño:
- Las funciones de regla (rule_*) son puras: reciben un dict con la fila y
  devuelven True/False. No tocan la base de datos, por lo que se pueden
  probar con datos de ejemplo (ver etl/tests/).
- La conexión a SQL Server y la orquestación viven en main() / fetch_rows(),
  separadas de la lógica de negocio.

Variables de entorno esperadas (ajustar a la convención real del equipo si
difiere de esta, por ejemplo si el repositorio ya define otras en
etl/config/.env.example):
    SQLSERVER_HOST
    SQLSERVER_DATABASE   (por defecto: ContratosRemuneraciones_ABC)
    SQLSERVER_USER
    SQLSERVER_PASSWORD
    SQLSERVER_DRIVER     (por defecto: "ODBC Driver 17 for SQL Server")

Uso:
    python etl/validate/contratos_remuneraciones.py
"""

from __future__ import annotations

import os
import re
import sys
from dataclasses import dataclass, field
from datetime import date
from typing import Any, Iterable

# ---------------------------------------------------------------------------
# Reglas puras (testeables sin base de datos)
# ---------------------------------------------------------------------------

# RUT chileno simplificado: 7-8 dígitos + guion + dígito verificador (0-9 o K).
# Es una validación de FORMATO superficial, no valida el dígito verificador
# matemáticamente — eso excede el alcance de "limpieza superficial y segura"
# de este encargo.
_RUT_PATTERN = re.compile(r"^\d{7,8}-[\dkK]$")


def rule_rut_invalido(rut: str | None) -> bool:
    """True si el RUT es nulo, vacío, o no calza con un formato básico válido."""
    if rut is None:
        return True
    rut = rut.strip()
    if rut == "":
        return True
    return _RUT_PATTERN.match(rut) is None


def rule_fecha_inicio_mayor_termino(fecha_inicio: date | None, fecha_termino: date | None) -> bool:
    """True (ERROR) si fecha_inicio es posterior a fecha_termino."""
    if fecha_inicio is None or fecha_termino is None:
        return False
    return fecha_inicio > fecha_termino


def rule_contrato_vencido(fecha_termino: date | None, estado: str | None, hoy: date | None = None) -> bool:
    """True (WARNING) si el contrato ya venció pero sigue marcado VIGENTE."""
    if fecha_termino is None or estado is None:
        return False
    hoy = hoy or date.today()
    return fecha_termino < hoy and estado.strip().upper() == "VIGENTE"


def rule_liquidacion_sin_empleado(empleado_id: str | None) -> bool:
    """True (ERROR) si la liquidación no tiene empleado_id asociado."""
    return empleado_id is None or str(empleado_id).strip() == ""


def rule_monto_negativo(*montos: float | None) -> bool:
    """True (ERROR) si alguno de los montos entregados es negativo."""
    return any(m is not None and m < 0 for m in montos)


# ---------------------------------------------------------------------------
# Clasificación de filas usando las reglas puras de arriba
# ---------------------------------------------------------------------------

@dataclass
class Finding:
    entidad: str
    identificador: Any
    regla: str
    severidad: str  # "ERROR" | "WARNING"
    detalle: str = ""


def evaluar_empleado(row: dict) -> list[Finding]:
    findings: list[Finding] = []
    if rule_rut_invalido(row.get("rut_referencia")):
        findings.append(Finding(
            entidad="Empleado",
            identificador=row.get("empleado_id"),
            regla="rut_invalido",
            severidad="ERROR",
            detalle=f"rut_referencia={row.get('rut_referencia')!r}",
        ))
    return findings


def evaluar_contrato(row: dict, hoy: date | None = None) -> list[Finding]:
    findings: list[Finding] = []
    if rule_fecha_inicio_mayor_termino(row.get("fecha_inicio"), row.get("fecha_termino")):
        findings.append(Finding(
            entidad="Contrato",
            identificador=row.get("contrato_id"),
            regla="fecha_inicio_mayor_termino",
            severidad="ERROR",
            detalle=f"fecha_inicio={row.get('fecha_inicio')} fecha_termino={row.get('fecha_termino')}",
        ))
    if rule_monto_negativo(row.get("sueldo_base")):
        findings.append(Finding(
            entidad="Contrato",
            identificador=row.get("contrato_id"),
            regla="monto_negativo",
            severidad="ERROR",
            detalle=f"sueldo_base={row.get('sueldo_base')}",
        ))
    if rule_contrato_vencido(row.get("fecha_termino"), row.get("estado"), hoy):
        findings.append(Finding(
            entidad="Contrato",
            identificador=row.get("contrato_id"),
            regla="contrato_vencido",
            severidad="WARNING",
            detalle=f"fecha_termino={row.get('fecha_termino')} estado={row.get('estado')}",
        ))
    return findings


def evaluar_liquidacion(row: dict) -> list[Finding]:
    findings: list[Finding] = []
    if rule_liquidacion_sin_empleado(row.get("empleado_id")):
        findings.append(Finding(
            entidad="Liquidacion",
            identificador=row.get("liquidacion_id"),
            regla="liquidacion_sin_empleado",
            severidad="ERROR",
            detalle="empleado_id vacío o nulo",
        ))
    montos = (
        row.get("sueldo_base"),
        row.get("horas_extras"),
        row.get("sueldo_imponible"),
        row.get("sueldo_liquido"),
        row.get("costo_empresa"),
    )
    if rule_monto_negativo(*montos):
        findings.append(Finding(
            entidad="Liquidacion",
            identificador=row.get("liquidacion_id"),
            regla="monto_negativo",
            severidad="ERROR",
            detalle=f"montos={montos}",
        ))
    return findings


# ---------------------------------------------------------------------------
# Acceso a datos (SQL Server) — separado de la lógica de negocio de arriba
# ---------------------------------------------------------------------------

def _connection_string() -> str:
    driver = os.environ.get("SQLSERVER_DRIVER", "ODBC Driver 17 for SQL Server")
    host = os.environ["SQLSERVER_HOST"]
    database = os.environ.get("SQLSERVER_DATABASE", "ContratosRemuneraciones_ABC")
    user = os.environ["SQLSERVER_USER"]
    password = os.environ["SQLSERVER_PASSWORD"]
    return (
        f"DRIVER={{{driver}}};SERVER={host};DATABASE={database};"
        f"UID={user};PWD={password}"
    )


def fetch_rows(view_name: str) -> list[dict]:
    """Ejecuta SELECT * sobre una vista de staging y devuelve list[dict]."""
    import pyodbc  # import diferido: no se necesita para correr los tests

    conn = pyodbc.connect(_connection_string())
    try:
        cursor = conn.cursor()
        cursor.execute(f"SELECT * FROM {view_name}")
        columns = [c[0] for c in cursor.description]
        return [dict(zip(columns, row)) for row in cursor.fetchall()]
    finally:
        conn.close()


def run_validation() -> list[Finding]:
    findings: list[Finding] = []

    for row in fetch_rows("staging.contratos_remuneraciones_empleado"):
        findings.extend(evaluar_empleado(row))

    for row in fetch_rows("staging.contratos_remuneraciones_contrato"):
        findings.extend(evaluar_contrato(row))

    for row in fetch_rows("staging.contratos_remuneraciones_liquidacion"):
        findings.extend(evaluar_liquidacion(row))

    return findings


def print_report(findings: Iterable[Finding]) -> int:
    findings = list(findings)
    errores = [f for f in findings if f.severidad == "ERROR"]
    warnings = [f for f in findings if f.severidad == "WARNING"]

    print(f"Validación Contratos y Remuneraciones — {len(findings)} hallazgos "
          f"({len(errores)} ERROR, {len(warnings)} WARNING)\n")

    for f in findings:
        print(f"[{f.severidad}] {f.entidad} id={f.identificador} regla={f.regla} — {f.detalle}")

    if not findings:
        print("Sin hallazgos. Todas las reglas mínimas se cumplen.")

    # Código de salida distinto de 0 si hay ERRORES, para poder integrarlo
    # a un pipeline de CI/CD que corte la ejecución cuando corresponda.
    return 1 if errores else 0


def main() -> int:
    findings = run_validation()
    return print_report(findings)


if __name__ == "__main__":
    sys.exit(main())
