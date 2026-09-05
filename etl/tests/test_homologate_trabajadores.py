from etl.transform.homologation import (
    BusinessEntityRef,
    homologate_entity_collections,
    summarize_homologation_results,
)
from etl.transform.rut import normalize_rut


def test_homologacion_trabajador_empleado_por_rut():
    asistencia = [
        BusinessEntityRef(
            source="asistencia",
            entity="persona",
            local_id=1,
            business_code=normalize_rut("15.000.984-7"),
            display_name="Paula Civil Martínez",
        )
    ]

    rrhh = [
        BusinessEntityRef(
            source="rrhh",
            entity="persona",
            local_id=99,
            business_code=normalize_rut("15000984-7"),
            display_name="Paula Civil Martínez",
        )
    ]

    results = homologate_entity_collections(
        asistencia,
        rrhh,
    )

    summary = summarize_homologation_results(results)

    assert summary.total == 1
    assert summary.match == 1
    assert summary.no_match == 0
    assert summary.review == 0

    assert results[0].source.local_id == 1
    assert results[0].target.local_id == 99


def test_homologacion_rut_no_existente():
    asistencia = [
        BusinessEntityRef(
            source="asistencia",
            entity="persona",
            local_id=1,
            business_code=normalize_rut("11.111.111-1"),
        )
    ]

    rrhh = [
        BusinessEntityRef(
            source="rrhh",
            entity="persona",
            local_id=2,
            business_code=normalize_rut("22.222.222-2"),
        )
    ]

    results = homologate_entity_collections(
        asistencia,
        rrhh,
    )

    summary = summarize_homologation_results(results)

    assert summary.total == 1
    assert summary.match == 0
    assert summary.no_match == 1
    assert summary.review == 0
