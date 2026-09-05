from pathlib import Path

import pymysql

from etl.config.settings import get_asistencia_db_config
from etl.validate.asistencia.validator import (
    resumen_validacion,
    validate_asistencias,
)


PROJECT_ROOT = Path(__file__).resolve().parents[3]
STAGING_DIR = PROJECT_ROOT / "etl" / "sql" / "staging" / "asistencia"


def _leer_sql(nombre_archivo: str) -> str:
    ruta = STAGING_DIR / nombre_archivo
    return ruta.read_text(encoding="utf-8").strip().rstrip(";")


def obtener_datos():
    config = get_asistencia_db_config()

    conexion = pymysql.connect(
        host=config.host,
        port=config.port,
        user=config.user,
        password=config.password,
        database=config.database,
        cursorclass=pymysql.cursors.DictCursor,
        autocommit=True,
    )

    cursor = conexion.cursor()

    try:
        # -------------------------------------------------------------
        # RAW temporal
        # -------------------------------------------------------------
        cursor.execute(
            """
            CREATE TEMPORARY TABLE stg_asistencia_trabajador_raw
            AS
            SELECT *
            FROM trabajador
            """
        )

        cursor.execute(
            """
            CREATE TEMPORARY TABLE stg_asistencia_turnos_raw
            AS
            SELECT *
            FROM turnos
            """
        )

        cursor.execute(
            """
            CREATE TEMPORARY TABLE stg_asistencia_asistencia_raw
            AS
            SELECT *
            FROM asistencia
            """
        )

        # -------------------------------------------------------------
        # STAGING / CLEAN
        # Se reutilizan los SQL ya aprobados en Asistencia 0.1.
        # -------------------------------------------------------------
        cursor.execute(_leer_sql("trabajador.sql"))
        trabajadores = cursor.fetchall()

        cursor.execute(_leer_sql("turnos.sql"))
        turnos = cursor.fetchall()

        cursor.execute(_leer_sql("asistencia.sql"))
        asistencias = cursor.fetchall()

        return trabajadores, turnos, asistencias

    finally:
        cursor.close()
        conexion.close()


def ejecutar_validacion():
    trabajadores, turnos, asistencias = obtener_datos()

    trabajadores_ids = {
        trabajador["trabajador_id"]
        for trabajador in trabajadores
    }

    turnos_ids = {
        turno["turno_id"]
        for turno in turnos
    }

    trabajadores_dict = {
        trabajador["trabajador_id"]: trabajador
        for trabajador in trabajadores
    }

    turnos_dict = {
        turno["turno_id"]: turno
        for turno in turnos
    }

    resultados = validate_asistencias(
        asistencias,
        trabajadores_ids=trabajadores_ids,
        turnos_ids=turnos_ids,
        trabajadores=trabajadores_dict,
        turnos=turnos_dict,
    )

    resumen = resumen_validacion(resultados)

    print("========================================")
    print("VALIDACIÓN DE ASISTENCIA")
    print("========================================")
    print(f"procesados={resumen['procesados']}")
    print(f"validos={resumen['validos']}")
    print(f"errores={resumen['errores']}")
    print(f"warnings={resumen['warnings']}")
    print()

    print("DETALLE DE OBSERVACIONES")
    print("----------------------------------------")

    if not resumen["detalle"]:
        print("Sin errores ni advertencias.")
    else:
        for detalle in resumen["detalle"]:
            print(
                f"asistencia_id={detalle['asistencia_id']} | "
                f"severidad={detalle['severidad']} | "
                f"reglas={'; '.join(detalle['reglas'])}"
            )


if __name__ == "__main__":
    ejecutar_validacion()
