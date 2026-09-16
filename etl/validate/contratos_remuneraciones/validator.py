"""
etl/validate/contratos_remuneraciones/validator.py

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

Configuración:
La conexión reutiliza la configuración central de ETL Core mediante
`get_contratos_rem_db_config()`, que utiliza:

    CONTRATOS_REM_DB_HOST
    CONTRATOS_REM_DB_PORT
    CONTRATOS_REM_DB_NAME
    CONTRATOS_REM_DB_USER
    CONTRATOS_REM_DB_PASSWORD

Uso:
    python etl/validate/contratos_remuneraciones/validator.py
"""

from __future__ import annotations

import re
import sys
from dataclasses import dataclass, field
from datetime import date
from typing import Any, Iterable

from etl.config.settings import get_contratos_rem_db_config

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


def rule_texto_obligatorio_vacio(valor: object | None) -> bool:
    """True si un campo textual obligatorio es nulo o queda vacío al limpiar."""
    return valor is None or str(valor).strip() == ""


def rule_tipo_concepto_invalido(tipo: str | None) -> bool:
    """True si ConceptoPago.tipo no pertenece al catálogo permitido."""
    if tipo is None:
        return True
    return tipo.strip().upper() not in {"HABER", "DESCUENTO", "APORTE"}


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




def evaluar_concepto_pago(row: dict) -> list[Finding]:
    findings: list[Finding] = []

    if rule_texto_obligatorio_vacio(row.get("codigo")):
        findings.append(Finding(
            entidad="ConceptoPago",
            identificador=row.get("concepto_id"),
            regla="codigo_obligatorio",
            severidad="ERROR",
            detalle=f"codigo={row.get('codigo')!r}",
        ))

    if rule_texto_obligatorio_vacio(row.get("descripcion")):
        findings.append(Finding(
            entidad="ConceptoPago",
            identificador=row.get("concepto_id"),
            regla="descripcion_obligatoria",
            severidad="ERROR",
            detalle=f"descripcion={row.get('descripcion')!r}",
        ))

    if rule_tipo_concepto_invalido(row.get("tipo")):
        findings.append(Finding(
            entidad="ConceptoPago",
            identificador=row.get("concepto_id"),
            regla="tipo_concepto_invalido",
            severidad="ERROR",
            detalle=f"tipo={row.get('tipo')!r}",
        ))

    return findings


def evaluar_detalle_liquidacion(row: dict) -> list[Finding]:
    findings: list[Finding] = []

    if row.get("liquidacion_id") is None:
        findings.append(Finding(
            entidad="DetalleLiquidacion",
            identificador=row.get("detalle_id"),
            regla="liquidacion_id_obligatorio",
            severidad="ERROR",
            detalle="liquidacion_id nulo",
        ))

    if row.get("concepto_id") is None:
        findings.append(Finding(
            entidad="DetalleLiquidacion",
            identificador=row.get("detalle_id"),
            regla="concepto_id_obligatorio",
            severidad="ERROR",
            detalle="concepto_id nulo",
        ))

    if row.get("monto") is None:
        findings.append(Finding(
            entidad="DetalleLiquidacion",
            identificador=row.get("detalle_id"),
            regla="monto_obligatorio",
            severidad="ERROR",
            detalle="monto nulo",
        ))
    elif rule_monto_negativo(row.get("monto")):
        findings.append(Finding(
            entidad="DetalleLiquidacion",
            identificador=row.get("detalle_id"),
            regla="monto_negativo",
            severidad="ERROR",
            detalle=f"monto={row.get('monto')}",
        ))

    return findings


# ---------------------------------------------------------------------------
# Acceso a datos (SQL Server) — separado de la lógica de negocio de arriba
# ---------------------------------------------------------------------------

def _connection_string() -> str:
    """Construye la cadena ODBC usando la configuración central del ETL."""
    cfg = get_contratos_rem_db_config()

    # Driver 18 es el estándar actual utilizado para SQL Server.
    # TrustServerCertificate evita problemas de certificado en el entorno
    # local de desarrollo del proyecto.
    return (
        "DRIVER={ODBC Driver 17 for SQL Server};"
        f"SERVER={cfg.host},{cfg.port};"
        f"DATABASE={cfg.database};"
        f"UID={cfg.user};"
        f"PWD={cfg.password};"
        "TrustServerCertificate=yes;"
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



def evaluar_relaciones(
    empleados: list[dict],
    contratos: list[dict],
    liquidaciones: list[dict],
    conceptos: list[dict],
    detalles: list[dict],
) -> list[Finding]:
    findings: list[Finding] = []

    empleados_ids = {r.get("empleado_id") for r in empleados}
    contratos_por_id = {r.get("contrato_id"): r for r in contratos}
    liquidaciones_ids = {r.get("liquidacion_id") for r in liquidaciones}
    conceptos_ids = {r.get("concepto_id") for r in conceptos}

    for row in contratos:
        empleado_id = row.get("empleado_id")
        if empleado_id not in empleados_ids:
            findings.append(Finding(
                entidad="Contrato",
                identificador=row.get("contrato_id"),
                regla="empleado_huerfano",
                severidad="ERROR",
                detalle=f"empleado_id={empleado_id!r}",
            ))

    for row in liquidaciones:
        empleado_id = row.get("empleado_id")
        contrato_id = row.get("contrato_id")

        if empleado_id not in empleados_ids:
            findings.append(Finding(
                entidad="Liquidacion",
                identificador=row.get("liquidacion_id"),
                regla="empleado_huerfano",
                severidad="ERROR",
                detalle=f"empleado_id={empleado_id!r}",
            ))

        contrato = contratos_por_id.get(contrato_id)

        if contrato is None:
            findings.append(Finding(
                entidad="Liquidacion",
                identificador=row.get("liquidacion_id"),
                regla="contrato_huerfano",
                severidad="ERROR",
                detalle=f"contrato_id={contrato_id!r}",
            ))
        elif contrato.get("empleado_id") != empleado_id:
            findings.append(Finding(
                entidad="Liquidacion",
                identificador=row.get("liquidacion_id"),
                regla="contrato_otro_empleado",
                severidad="ERROR",
                detalle=(
                    f"empleado_liquidacion={empleado_id!r} "
                    f"empleado_contrato={contrato.get('empleado_id')!r}"
                ),
            ))

    for row in detalles:
        if row.get("liquidacion_id") not in liquidaciones_ids:
            findings.append(Finding(
                entidad="DetalleLiquidacion",
                identificador=row.get("detalle_id"),
                regla="liquidacion_huerfana",
                severidad="ERROR",
                detalle=f"liquidacion_id={row.get('liquidacion_id')!r}",
            ))

        if row.get("concepto_id") not in conceptos_ids:
            findings.append(Finding(
                entidad="DetalleLiquidacion",
                identificador=row.get("detalle_id"),
                regla="concepto_huerfano",
                severidad="ERROR",
                detalle=f"concepto_id={row.get('concepto_id')!r}",
            ))

    return findings


def evaluar_duplicados(
    contratos: list[dict],
    liquidaciones: list[dict],
    conceptos: list[dict],
    detalles: list[dict],
) -> list[Finding]:
    findings: list[Finding] = []

    def duplicados(rows: list[dict], key_fn):
        vistos = set()
        repetidos = set()

        for row in rows:
            key = key_fn(row)
            if key in vistos:
                repetidos.add(key)
            else:
                vistos.add(key)

        return repetidos

    for numero in duplicados(
        contratos,
        lambda r: r.get("numero_contrato"),
    ):
        findings.append(Finding(
            entidad="Contrato",
            identificador=numero,
            regla="numero_contrato_duplicado",
            severidad="ERROR",
            detalle=f"numero_contrato={numero!r}",
        ))

    for key in duplicados(
        liquidaciones,
        lambda r: (r.get("empleado_id"), r.get("periodo")),
    ):
        findings.append(Finding(
            entidad="Liquidacion",
            identificador=key,
            regla="empleado_periodo_duplicado",
            severidad="ERROR",
            detalle=f"empleado_id={key[0]!r} periodo={key[1]!r}",
        ))

    for codigo in duplicados(
        conceptos,
        lambda r: r.get("codigo"),
    ):
        findings.append(Finding(
            entidad="ConceptoPago",
            identificador=codigo,
            regla="codigo_duplicado",
            severidad="ERROR",
            detalle=f"codigo={codigo!r}",
        ))

    for key in duplicados(
        detalles,
        lambda r: (r.get("liquidacion_id"), r.get("concepto_id")),
    ):
        findings.append(Finding(
            entidad="DetalleLiquidacion",
            identificador=key,
            regla="liquidacion_concepto_duplicado",
            severidad="ERROR",
            detalle=(
                f"liquidacion_id={key[0]!r} "
                f"concepto_id={key[1]!r}"
            ),
        ))

    return findings


def run_validation() -> list[Finding]:
    empleados = fetch_rows(
        "staging.contratos_remuneraciones_empleado"
    )
    contratos = fetch_rows(
        "staging.contratos_remuneraciones_contrato"
    )
    liquidaciones = fetch_rows(
        "staging.contratos_remuneraciones_liquidacion"
    )
    conceptos = fetch_rows(
        "staging.contratos_remuneraciones_concepto_pago"
    )
    detalles = fetch_rows(
        "staging.contratos_remuneraciones_detalle_liquidacion"
    )

    findings: list[Finding] = []

    for row in empleados:
        findings.extend(evaluar_empleado(row))

    for row in contratos:
        findings.extend(evaluar_contrato(row))

    for row in liquidaciones:
        findings.extend(evaluar_liquidacion(row))

    for row in conceptos:
        findings.extend(evaluar_concepto_pago(row))

    for row in detalles:
        findings.extend(evaluar_detalle_liquidacion(row))

    findings.extend(evaluar_relaciones(
        empleados,
        contratos,
        liquidaciones,
        conceptos,
        detalles,
    ))

    findings.extend(evaluar_duplicados(
        contratos,
        liquidaciones,
        conceptos,
        detalles,
    ))

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


