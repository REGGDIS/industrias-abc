from __future__ import annotations

from datetime import date

from etl.audit.logger import finish_execution, start_execution
from etl.config.settings import get_dw_db_config
from etl.extract.postgres import get_postgres_connection
from etl.load.dw_rrhh import (
    build_initial_empleado_versions,
    extract_areas_clean,
    extract_cargos_clean,
    extract_centros_costo_clean,
    extract_empleados_clean,
    resolve_empleados_dimension_keys,
    run_dim_area,
    run_dim_cargo,
    run_dim_centro_costo,
    run_dim_empleado,
)


SOURCE = "RRHH"
PROCESS = "ETL_DW_RRHH"
FECHA_OBSERVACION = date(2026, 9, 9)


def classify_changes() -> dict:
    areas = extract_areas_clean()
    centros = extract_centros_costo_clean()
    cargos = extract_cargos_clean()

    empleados = extract_empleados_clean()
    empleados_resueltos = resolve_empleados_dimension_keys(empleados)
    versiones = build_initial_empleado_versions(
        empleados_resueltos,
        FECHA_OBSERVACION,
    )

    config = get_dw_db_config()

    with get_postgres_connection(config) as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                """
                SELECT
                    codigo_area,
                    nombre_area,
                    gerencia
                FROM dw.dim_area
                WHERE area_key <> 0;
                """
            )
            dw_areas = {
                row[0]: (row[1], row[2])
                for row in cursor.fetchall()
            }

            cursor.execute(
                """
                SELECT
                    codigo_centro_costo,
                    nombre_centro_costo
                FROM dw.dim_centro_costo
                WHERE centro_costo_key <> 0;
                """
            )
            dw_centros = {
                row[0]: row[1]
                for row in cursor.fetchall()
            }

            cursor.execute(
                """
                SELECT
                    codigo_cargo,
                    nombre_cargo,
                    nivel,
                    sueldo_base_referencial
                FROM dw.dim_cargo
                WHERE cargo_key <> 0;
                """
            )
            dw_cargos = {
                row[0]: (row[1], row[2], row[3])
                for row in cursor.fetchall()
            }

            cursor.execute(
                """
                SELECT
                    rut_normalizado,
                    nombres,
                    apellido_paterno,
                    apellido_materno,
                    fecha_nacimiento,
                    fecha_ingreso,
                    fecha_salida,
                    area_key,
                    cargo_key,
                    centro_costo_key,
                    estado_laboral,
                    sexo,
                    nacionalidad,
                    fecha_desde,
                    fecha_hasta,
                    es_actual,
                    contexto_historico_estimado
                FROM dw.dim_empleado
                WHERE empleado_key <> 0;
                """
            )
            dw_empleados = {
                (row[0], row[13]): row[1:]
                for row in cursor.fetchall()
            }

    inserted = 0
    updated = 0
    unchanged = 0

    for row in centros:
        key = row["codigo_centro_costo"]
        expected = row["nombre_centro_costo"]

        if key not in dw_centros:
            inserted += 1
        elif dw_centros[key] != expected:
            updated += 1
        else:
            unchanged += 1

    for row in areas:
        key = row["codigo_area"]
        expected = (
            row["nombre_area"],
            row["gerencia"],
        )

        if key not in dw_areas:
            inserted += 1
        elif dw_areas[key] != expected:
            updated += 1
        else:
            unchanged += 1

    for row in cargos:
        key = row["codigo_cargo"]
        expected = (
            row["nombre_cargo"],
            row["nivel"],
            row["sueldo_base_referencial"],
        )

        if key not in dw_cargos:
            inserted += 1
        elif dw_cargos[key] != expected:
            updated += 1
        else:
            unchanged += 1

    for row in versiones:
        key = (
            row["rut_normalizado"],
            row["fecha_desde"],
        )

        expected = (
            row["nombres"],
            row["apellido_paterno"],
            row["apellido_materno"],
            row["fecha_nacimiento"],
            row["fecha_ingreso"],
            row["fecha_salida"],
            row["area_key"],
            row["cargo_key"],
            row["centro_costo_key"],
            row["estado_laboral"],
            row["sexo"],
            row["nacionalidad"],
            row["fecha_desde"],
            row["fecha_hasta"],
            row["es_actual"],
            row["contexto_historico_estimado"],
        )

        if key not in dw_empleados:
            inserted += 1
        elif dw_empleados[key] != expected:
            updated += 1
        else:
            unchanged += 1

    return {
        "records_read": (
            len(centros)
            + len(areas)
            + len(cargos)
            + len(empleados)
        ),
        "records_valid": (
            len(centros)
            + len(areas)
            + len(cargos)
            + len(empleados)
        ),
        "records_inserted": inserted,
        "records_updated": updated,
        "records_unchanged": unchanged,
        "records_rejected": 0,
        "records_review": 0,
    }


def main() -> dict:
    execution_id = start_execution(SOURCE, PROCESS)

    summary = {
        "records_read": 0,
        "records_valid": 0,
        "records_inserted": 0,
        "records_updated": 0,
        "records_unchanged": 0,
        "records_rejected": 0,
        "records_review": 0,
    }

    try:
        summary = classify_changes()

        centros = run_dim_centro_costo()
        areas = run_dim_area()
        cargos = run_dim_cargo()
        empleados = run_dim_empleado(FECHA_OBSERVACION)

        finish_execution(
            execution_id=execution_id,
            records_read=summary["records_read"],
            records_valid=summary["records_valid"],
            records_rejected=summary["records_rejected"],
            records_inserted=summary["records_inserted"],
            records_updated=summary["records_updated"],
            records_unchanged=summary["records_unchanged"],
            records_review=summary["records_review"],
            status="SUCCESS",
            message=(
                "ETL RRHH -> DW ejecutado. "
                f"FECHA_OBSERVACION={FECHA_OBSERVACION.isoformat()} "
                "REVIEW=0 REJECTED=0."
            ),
        )

        return {
            "execution_id": execution_id,
            "status": "SUCCESS",
            **summary,
            "fecha_observacion": FECHA_OBSERVACION.isoformat(),
            "dim_centro_costo": centros,
            "dim_area": areas,
            "dim_cargo": cargos,
            "dim_empleado": empleados,
        }

    except Exception as exc:
        finish_execution(
            execution_id=execution_id,
            records_read=summary["records_read"],
            records_valid=summary["records_valid"],
            records_rejected=summary["records_rejected"],
            records_inserted=summary["records_inserted"],
            records_updated=summary["records_updated"],
            records_unchanged=summary["records_unchanged"],
            records_review=summary["records_review"],
            status="ERROR",
            message=f"ETL RRHH -> DW falló: {type(exc).__name__}: {exc}",
        )
        raise


if __name__ == "__main__":
    print(main())
