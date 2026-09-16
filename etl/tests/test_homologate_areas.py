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


def test_homologacion_areas_preserva_nombres():
    rrhh = [
        BusinessEntityRef(
            "rrhh",
            "area",
            1,
            "A01",
            "Administración",
        ),
    ]

    compras = [
        BusinessEntityRef(
            "compras",
            "area",
            10,
            "A01",
            "Administración",
        ),
    ]

    results = homologate_entity_collections(rrhh, compras)

    assert len(results) == 1
    assert results[0].status == "MATCH"
    assert results[0].source.display_name == "Administración"
    assert results[0].target.display_name == "Administración"
