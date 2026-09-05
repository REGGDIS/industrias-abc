from decimal import Decimal
from datetime import date


ESTADOS_VALIDOS = {"PRESENTE", "ATRASO", "AUSENTE"}

FECHA_MIN = date(2025, 1, 1)
FECHA_MAX = date(2026, 7, 31)


def _numero(valor):
    if valor is None:
        return None

    try:
        return Decimal(str(valor))
    except (ValueError, TypeError):
        return None


def _fecha(valor):
    if valor is None:
        return None

    if isinstance(valor, date):
        return valor

    try:
        return date.fromisoformat(str(valor))
    except (ValueError, TypeError):
        return None


def validate_asistencia(
    row: dict,
    trabajadores_ids: set | None = None,
    turnos_ids: set | None = None,
    trabajadores: dict | None = None,
    turnos: dict | None = None,
) -> dict:

    errors = []
    warnings = []

    # Identificador de origen
    if row.get("asistencia_id") is None:
        errors.append("asistencia_id ausente")

    # Integridad trabajador
    trabajador_id = row.get("trabajador_id")

    if trabajador_id is None:
        errors.append("trabajador_id ausente")
    elif trabajadores_ids is not None and trabajador_id not in trabajadores_ids:
        errors.append("trabajador_id inexistente")

    # Integridad turno
    turno_id = row.get("turno_id")

    if turno_id is None:
        errors.append("turno_id ausente")
    elif turnos_ids is not None and turno_id not in turnos_ids:
        errors.append("turno_id inexistente")

    # Fecha
    fecha = _fecha(row.get("fecha"))

    if fecha is None:
        errors.append("fecha ausente o inválida")
    else:
        if fecha < FECHA_MIN or fecha > FECHA_MAX:
            warnings.append("fecha fuera del período de referencia")

    # Valores numéricos
    horas_trabajadas = _numero(row.get("horas_trabajadas"))
    horas_normales = _numero(row.get("horas_normales"))
    horas_extras = _numero(row.get("horas_extras"))
    atraso_minutos = _numero(row.get("atraso_minutos"))

    if horas_trabajadas is None:
        errors.append("horas_trabajadas ausentes o inválidas")
    elif horas_trabajadas < 0:
        errors.append("horas_trabajadas negativas")

    if horas_normales is None:
        errors.append("horas_normales ausentes o inválidas")
    elif horas_normales < 0:
        errors.append("horas_normales negativas")

    if horas_extras is None:
        errors.append("horas_extras ausentes o inválidas")
    elif horas_extras < 0:
        errors.append("horas_extras negativas")
    elif (
        horas_trabajadas is not None
        and horas_extras > horas_trabajadas
    ):
        errors.append("horas_extras mayores que horas_trabajadas")

    if atraso_minutos is None:
        errors.append("atraso_minutos ausente o inválido")
    elif atraso_minutos < 0:
        errors.append("atraso_minutos negativos")

    # Estado
    estado = row.get("estado")
    if isinstance(estado, str):
        estado = estado.strip().upper()

    if estado not in ESTADOS_VALIDOS:
        errors.append("estado inválido")

    # Ausentismo
    ausentismo = row.get("ausentismo")

    if ausentismo not in (0, 1):
        errors.append("ausentismo inválido")

    # Campos obligatorios de asistencia
    if (
        trabajador_id is None
        or turno_id is None
        or fecha is None
        or horas_trabajadas is None
        or horas_normales is None
        or horas_extras is None
        or atraso_minutos is None
        or ausentismo is None
        or estado is None
    ):
        pass

    # Coherencia de ausencia
    if estado == "AUSENTE":

        if row.get("hora_entrada") is not None:
            errors.append("AUSENTE con hora_entrada informada")

        if row.get("hora_salida") is not None:
            errors.append("AUSENTE con hora_salida informada")

        if horas_trabajadas is not None and horas_trabajadas != 0:
            errors.append("AUSENTE con horas_trabajadas distintas de 0")

        if horas_normales is not None and horas_normales != 0:
            errors.append("AUSENTE con horas_normales distintas de 0")

        if horas_extras is not None and horas_extras != 0:
            errors.append("AUSENTE con horas_extras distintas de 0")

        if atraso_minutos is not None and atraso_minutos != 0:
            errors.append("AUSENTE con atraso_minutos distinto de 0")

        if ausentismo != 1:
            errors.append("AUSENTE con ausentismo distinto de 1")

    # Ausentismo marcado sin estado AUSENTE
    if ausentismo == 1 and estado != "AUSENTE":
        errors.append("ausentismo=1 con estado distinto de AUSENTE")

    # Coherencia de presencia
    if estado in {"PRESENTE", "ATRASO"}:

        if row.get("hora_entrada") is None:
            errors.append("PRESENTE/ATRASO sin hora_entrada")

        if row.get("hora_salida") is None:
            errors.append("PRESENTE/ATRASO sin hora_salida")

    # Coherencia de atraso
    if estado == "ATRASO":

        if atraso_minutos is not None and atraso_minutos <= 0:
            errors.append("ATRASO con atraso_minutos no positivo")

    if estado == "PRESENTE":

        if atraso_minutos is not None and atraso_minutos > 0:
            errors.append("PRESENTE con atraso_minutos positivo")

    # Coherencia de horas
    if (
        horas_trabajadas is not None
        and horas_normales is not None
        and horas_extras is not None
        and abs(
            horas_trabajadas
            - (horas_normales + horas_extras)
        ) > Decimal("0.01")
    ):
        errors.append(
            "horas_trabajadas no coincide con normales + extras"
        )

    # Horas normales no pueden superar la jornada del turno
    if (
        horas_normales is not None
        and turno_id is not None
        and turnos is not None
        and turno_id in turnos
    ):
        turno = turnos[turno_id]
        horas_jornada = _numero(turno.get("horas_jornada"))

        if (
            horas_jornada is not None
            and horas_normales > horas_jornada
        ):
            errors.append(
                "horas_normales mayores que horas_jornada"
            )

    # Fecha anterior al ingreso
    if (
        fecha is not None
        and trabajador_id is not None
        and trabajadores is not None
        and trabajador_id in trabajadores
    ):
        trabajador = trabajadores[trabajador_id]
        fecha_ingreso = _fecha(
            trabajador.get("fecha_ingreso")
        )

        if (
            fecha_ingreso is not None
            and fecha < fecha_ingreso
        ):
            errors.append(
                "fecha de asistencia anterior a fecha_ingreso"
            )

    # Resultado
    if errors:
        status = "ERROR"
    else:
        status = "VALID"
    return{
        "status" : status,
        "errors" : errors,
        "warnings" : warnings,
        "record" : row,       
    }

def validate_trabajadores(rows: list[dict]) -> list[dict]:

    results = []
    rut_seen = set()
    nombre_seen = set()

    for row in rows:

        errors = []
        warnings = []

        rut = row.get("rut")
        nombre = row.get("nombre")
        apellido = row.get("apellido")
        fecha_ingreso = row.get("fecha_ingreso")

        # Campos obligatorios
        if rut is None or not str(rut).strip():
            errors.append("rut ausente")
        else:
            rut_text = str(rut).strip()

            # Formato XX.XXX.XXX-X
            import re

            if not re.match(
                r"^[0-9]{2}\.[0-9]{3}\.[0-9]{3}-[0-9Kk]$",
                rut_text,
            ):
                errors.append("rut con formato inválido")

            if rut_text in rut_seen:
                errors.append("rut duplicado")
            else:
                rut_seen.add(rut_text)

        if nombre is None or not str(nombre).strip():
            errors.append("nombre ausente")

        if apellido is None or not str(apellido).strip():
            errors.append("apellido ausente")

        if fecha_ingreso is None:
            errors.append("fecha_ingreso ausente")

        # Posible duplicado por nombre + apellido
        if nombre and apellido:
            key = (
                str(nombre).strip().upper(),
                str(apellido).strip().upper(),
            )

            if key in nombre_seen:
                warnings.append(
                    "nombre + apellido duplicado"
                )
            else:
                nombre_seen.add(key)

        if errors:
            status = "ERROR"
        elif warnings:
            status = "WARNING"
        else:
            status = "VALID"

        results.append(
            {
                "status": status,
                "errors": errors,
                "warnings": warnings,
                "record": row,
            }
        )

    return results


def validate_asistencias(
    rows: list[dict],
    trabajadores_ids: set | None = None,
    turnos_ids: set | None = None,
    trabajadores: dict | None = None,
    turnos: dict | None = None,
) -> list[dict]:

    results = []
    seen = set()

    for row in rows:

        result = validate_asistencia(
            row,
            trabajadores_ids=trabajadores_ids,
            turnos_ids=turnos_ids,
            trabajadores=trabajadores,
            turnos=turnos,
        )

        trabajador_id = row.get("trabajador_id")
        fecha = row.get("fecha")

        key = (trabajador_id, fecha)

        if trabajador_id is not None and fecha is not None:

            if key in seen:
                result["errors"].append(
                    "duplicado trabajador + fecha"
                )
                result["status"] = "ERROR"
            else:
                seen.add(key)

        results.append(result)

    return results


def resumen_validacion(results: list[dict]) -> dict:

    procesados = len(results)

    validos = sum(
        1
        for result in results
        if result["status"] == "VALID"
    )

    errores = sum(
        1
        for result in results
        if result["status"] == "ERROR"
    )

    warnings = sum(
        1
        for result in results
        if result["warnings"] and not result["errors"]
    )

    detalle = []

    for result in results:

        if result["errors"]:
            detalle.append(
                {
                    "asistencia_id": result["record"].get(
                        "asistencia_id"
                    ),
                    "reglas": result["errors"],
                    "severidad": "ERROR",
                }
            )

        elif result["warnings"]:
            detalle.append(
                {
                    "asistencia_id": result["record"].get(
                        "asistencia_id"
                    ),
                    "reglas": result["warnings"],
                    "severidad": "WARNING",
                }
            )

    return {
        "procesados": procesados,
        "validos": validos,
        "errores": errores,
        "warnings": warnings,
        "detalle": detalle,
    }