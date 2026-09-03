from etl.transform.homologation import (
    BusinessEntityRef,
    homologate_entity_collections,
    summarize_homologation_results,
)


def test_homologacion_areas_rrhh_compras():
    rrhh = [
        BusinessEntityRef("rrhh", "area", 1, "A01", "Administración"),
        BusinessEntityRef("rrhh", "area", 2, "A02", "Recursos Humanos"),
    ]

    compras = [
        BusinessEntityRef("compras", "area", 10, "A01", "Administración"),
        BusinessEntityRef("compras", "area", 20, "A02", "Recursos Humanos"),
    ]

    results = homologate_entity_collections(rrhh, compras)
    summary = summarize_homologation_results(results)

    assert summary.total == 2
    assert summary.match == 2
    assert summary.no_match == 0
    assert summary.review == 0
