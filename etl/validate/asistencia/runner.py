import mysql.connector

from etl.validate.asistencia.validator import (
    validate_asistencias,
    resumen_validacion,
)


DB_CONFIG = {
    "host": "localhost",
    "user": "root",
    "password": "",
    "database": "sistemadeasistenciaindustriasabc",
}


def obtener_datos():

    conexion = mysql.connector.connect(**DB_CONFIG)
    cursor = conexion.cursor(dictionary=True)

    try:
        cursor.execute("""
            SELECT
                trabajador_id,
                rut,
                nombre,
                apellido,
                fecha_ingreso
            FROM trabajador
        """)
        trabajadores = cursor.fetchall()

        cursor.execute("""
            SELECT
                turno_id,
                nombre_turno,
                hora_inicio,
                hora_fin,
                horas_jornada
            FROM turnos
        """)
        turnos = cursor.fetchall()

        cursor.execute("""
            SELECT
                asistencia_id,
                trabajador_id,
                turno_id,
                fecha,
                hora_entrada,
                hora_salida,
                horas_trabajadas,
                horas_normales,
                horas_extras,
                atraso_minutos,
                ausentismo,
                estado
            FROM asistencia
        """)
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