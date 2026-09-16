import psycopg
import pymysql

from etl.config.settings import (
    get_asistencia_db_config,
    get_rrhh_db_config,
)
from etl.transform.homologation import (
    BusinessEntityRef,
    homologate_entity_collections,
    summarize_homologation_results,
)
from etl.transform.rut import normalize_rut


ENTITY_TYPE = "persona"


def fetch_rrhh_empleados() -> list[BusinessEntityRef]:
    config = get_rrhh_db_config()

    with psycopg.connect(
        host=config.host,
        port=config.port,
        dbname=config.database,
        user=config.user,
        password=config.password,
    ) as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT
                    empleado_id,
                    rut,
                    nombres,
                    apellido_paterno,
                    apellido_materno
                FROM empleados
                ORDER BY empleado_id
                """
            )

            rows = cur.fetchall()

    empleados = []

    for (
        empleado_id,
        rut,
        nombres,
        apellido_paterno,
        apellido_materno,
    ) in rows:
        nombre_completo = " ".join(
            part.strip()
            for part in (
                nombres,
                apellido_paterno,
                apellido_materno,
            )
            if part and part.strip()
        )

        empleados.append(
            BusinessEntityRef(
                source="rrhh",
                entity=ENTITY_TYPE,
                local_id=empleado_id,
                business_code=normalize_rut(rut),
                display_name=nombre_completo,
            )
        )

    return empleados


def fetch_asistencia_trabajadores() -> list[BusinessEntityRef]:
    config = get_asistencia_db_config()

    conn = pymysql.connect(
        host=config.host,
        port=config.port,
        database=config.database,
        user=config.user,
        password=config.password,
        charset="utf8mb4",
        use_unicode=True,
        cursorclass=pymysql.cursors.Cursor,
    )

    try:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT
                    trabajador_id,
                    rut,
                    nombre,
                    apellido
                FROM trabajador
                ORDER BY trabajador_id
                """
            )

            rows = cur.fetchall()
    finally:
        conn.close()

    trabajadores = []

    for trabajador_id, rut, nombre, apellido in rows:
        nombre_completo = " ".join(
            part.strip()
            for part in (
                nombre,
                apellido,
            )
            if part and part.strip()
        )

        trabajadores.append(
            BusinessEntityRef(
                source="asistencia",
                entity=ENTITY_TYPE,
                local_id=trabajador_id,
                business_code=normalize_rut(rut),
                display_name=nombre_completo,
            )
        )

    return trabajadores


def names_match(
    source_name: str | None,
    target_name: str | None,
) -> bool:
    if source_name is None or target_name is None:
        return False

    return source_name.strip().casefold() == target_name.strip().casefold()


def print_results(results) -> None:
    print()
    print("Asistencia vs RRHH por RUT")
    print("---------------------------")

    for result in results:
        source = result.source
        target = result.target

        if result.status == "MATCH":
            name_status = (
                "OK"
                if names_match(
                    source.display_name,
                    target.display_name,
                )
                else "DIFERENTE"
            )

            print(
                f"{source.source}:{source.local_id} "
                f"{source.business_code} "
                f"-> "
                f"{target.source}:{target.local_id} "
                f"{target.business_code} "
                f"[MATCH | nombre={name_status}]"
            )

            print(
                f"  nombre asistencia: "
                f"{source.display_name}"
            )
            print(
                f"  nombre rrhh:       "
                f"{target.display_name}"
            )

        elif result.status == "NO_MATCH":
            print(
                f"{source.source}:{source.local_id} "
                f"{source.business_code} "
                f"-> sin coincidencia en RRHH "
                f"[NO_MATCH]"
            )

        else:
            print(
                f"{source.source}:{source.local_id} "
                f"{source.business_code} "
                f"-> requiere revisión "
                f"[REVIEW]"
            )

    summary = summarize_homologation_results(results)

    print()
    print(
        f"Resumen: total={summary.total}, "
        f"match={summary.match}, "
        f"no_match={summary.no_match}, "
        f"review={summary.review}"
    )


def main() -> None:
    trabajadores = fetch_asistencia_trabajadores()
    empleados = fetch_rrhh_empleados()

    results = homologate_entity_collections(
        trabajadores,
        empleados,
    )

    print_results(results)


if __name__ == "__main__":
    main()
