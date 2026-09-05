from etl.transform.homologation import (
    BusinessEntityRef,
    homologate_entity_collections,
    summarize_homologation_results,
)


def test_homologacion_centros_costo_rrhh_compras():
    rrhh = [
        BusinessEntityRef(
            source="rrhh",
            entity="centro_costo",
            local_id=1,
            business_code="CC001",
            display_name="Administración General",
        )
    ]

    compras = [
        BusinessEntityRef(
            source="compras",
            entity="centro_costo",
            local_id=99,
            business_code=" cc001 ",
            display_name="Administración General",
        )
    ]

    results = homologate_entity_collections(
        rrhh,
        compras,
    )

    summary = summarize_homologation_results(results)

    assert summary.total == 1
    assert summary.match == 1
    assert summary.no_match == 0
    assert summary.review == 0

    assert results[0].source.local_id == 1
    assert results[0].target.local_id == 99


def test_homologacion_centros_costo_rrhh_contabilidad():
    rrhh = [
        BusinessEntityRef(
            source="rrhh",
            entity="centro_costo",
            local_id=1,
            business_code="CC005",
            display_name="Planta de Producción",
        )
    ]

    contabilidad = [
        BusinessEntityRef(
            source="contabilidad",
            entity="centro_costo",
            local_id=500,
            business_code="CC005",
            display_name="Planta de Producción",
        )
    ]

    results = homologate_entity_collections(
        rrhh,
        contabilidad,
    )

    summary = summarize_homologation_results(results)

    assert summary.total == 1
    assert summary.match == 1
    assert summary.no_match == 0
    assert summary.review == 0


def test_homologacion_centro_costo_no_existente():
    rrhh = [
        BusinessEntityRef(
            source="rrhh",
            entity="centro_costo",
            local_id=1,
            business_code="CC999",
        )
    ]

    compras = [
        BusinessEntityRef(
            source="compras",
            entity="centro_costo",
            local_id=2,
            business_code="CC001",
        )
    ]

    results = homologate_entity_collections(
        rrhh,
        compras,
    )

    summary = summarize_homologation_results(results)

    assert summary.total == 1
    assert summary.match == 0
    assert summary.no_match == 1
    assert summary.review == 0
