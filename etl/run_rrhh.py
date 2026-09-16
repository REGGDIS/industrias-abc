from etl.audit.logger import finish_execution, start_execution
from etl.extract.rrhh import (
    extract_areas,
    extract_cargos,
    extract_centros_costo,
    extract_empleados,
)
from etl.load.staging_rrhh import (
    create_areas_clean_table,
    create_areas_raw_table,
    create_cargos_clean_table,
    create_cargos_raw_table,
    create_centros_costo_clean_table,
    create_centros_costo_raw_table,
    create_empleados_clean_table,
    create_empleados_raw_table,
    load_areas_raw,
    load_cargos_raw,
    load_centros_costo_raw,
    load_empleados_raw,
)
from etl.transform.rrhh import transform_empleados
from etl.validate.rrhh import validate_empleados


def run_rrhh_etl():
    execution_id = start_execution(
        source="RRHH",
        process="ETL_RRHH_EMPLEADOS",
    )

    records_read = 0
    records_valid = 0
    records_rejected = 0

    try:
        # 1. Extracción
        extracted_rows = extract_empleados()
        areas_rows = extract_areas()
        cargos_rows = extract_cargos()
        centros_costo_rows = extract_centros_costo()

        records_read = len(extracted_rows)

        # 2. Transformación
        transformed_rows = transform_empleados(extracted_rows)

        # 3. Validación
        validation_results = validate_empleados(transformed_rows)

        records_valid = sum(
            1
            for result in validation_results
            if result["status"] in {"VALID", "WARNING"}
        )

        records_rejected = sum(
            1
            for result in validation_results
            if result["status"] == "ERROR"
        )

        # 4. Staging RAW - Empleados
        create_empleados_raw_table()
        loaded_raw = load_empleados_raw(extracted_rows)

        if loaded_raw != records_read:
            raise RuntimeError(
                "La cantidad cargada en RAW no coincide con la cantidad extraída."
            )

        # 4.1 Staging RAW - Tablas maestras RRHH
        create_areas_raw_table()
        create_cargos_raw_table()
        create_centros_costo_raw_table()

        load_areas_raw(areas_rows)
        load_cargos_raw(cargos_rows)
        load_centros_costo_raw(centros_costo_rows)

        # 5. Staging CLEAN
        create_empleados_clean_table()
        create_areas_clean_table()
        create_cargos_clean_table()
        create_centros_costo_clean_table()

        # 6. Auditoría final
        finish_execution(
            execution_id=execution_id,
            records_read=records_read,
            records_valid=records_valid,
            records_rejected=records_rejected,
            status="SUCCESS",
            message="ETL RRHH ejecutado correctamente.",
        )

        return {
            "execution_id": execution_id,
            "records_read": records_read,
            "records_valid": records_valid,
            "records_rejected": records_rejected,
            "areas": len(areas_rows),
            "cargos": len(cargos_rows),
            "centros_costo": len(centros_costo_rows),
            "status": "SUCCESS",
        }

    except Exception as error:
        finish_execution(
            execution_id=execution_id,
            records_read=records_read,
            records_valid=records_valid,
            records_rejected=records_rejected,
            status="ERROR",
            message=str(error),
        )

        raise


if __name__ == "__main__":
    result = run_rrhh_etl()
    print(result)
