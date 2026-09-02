import pytest

from etl.transform.homologation import (
    BusinessEntityRef,
    EntityHomologationResult,
    HomologationSummary,
    compare_business_codes,
    compare_entity_refs,
    homologate_entity_collections,
    summarize_homologation_results,
)


def test_compare_business_codes_match():
    result = compare_business_codes(
        "A01",
        " a01 ",
    )

    assert result.source_normalized == "A01"
    assert result.target_normalized == "A01"
    assert result.status == "MATCH"


def test_compare_business_codes_no_match():
    result = compare_business_codes(
        "A01",
        "A02",
    )

    assert result.status == "NO_MATCH"


@pytest.mark.parametrize(
    "source_code, target_code",
    [
        (None, "A01"),
        ("A01", None),
        ("", "A01"),
        ("A01", "   "),
    ],
)
def test_compare_business_codes_review(
    source_code,
    target_code,
):
    result = compare_business_codes(
        source_code,
        target_code,
    )

    assert result.status == "REVIEW"


def test_business_entity_ref_normalizes_code():
    entity = BusinessEntityRef(
        source="rrhh",
        entity="area",
        local_id=1,
        business_code=" adm ",
        display_name="Administración",
    )

    assert entity.normalized_code == "ADM"


def test_compare_entity_refs_match():
    source = BusinessEntityRef(
        source="fuente_a",
        entity="area",
        local_id=1,
        business_code="A01",
    )

    target = BusinessEntityRef(
        source="fuente_b",
        entity="area",
        local_id=99,
        business_code=" a01 ",
    )

    result = compare_entity_refs(source, target)

    assert result.status == "MATCH"


def test_compare_entity_refs_ignores_local_ids():
    source = BusinessEntityRef(
        source="fuente_a",
        entity="area",
        local_id=10,
        business_code="FIN",
    )

    target = BusinessEntityRef(
        source="fuente_b",
        entity="area",
        local_id=10,
        business_code="RRHH",
    )

    result = compare_entity_refs(source, target)

    assert result.status == "NO_MATCH"


def test_compare_entity_refs_preserves_traceability():
    source = BusinessEntityRef(
        source="fuente_a",
        entity="area",
        local_id=10,
        business_code="A01",
        display_name="Área Uno",
    )

    target = BusinessEntityRef(
        source="fuente_b",
        entity="area",
        local_id=200,
        business_code=" a01 ",
        display_name="AREA UNO",
    )

    result = compare_entity_refs(source, target)

    assert isinstance(result, EntityHomologationResult)
    assert result.source.source == "fuente_a"
    assert result.source.local_id == 10
    assert result.target.source == "fuente_b"
    assert result.target.local_id == 200
    assert result.source_normalized == "A01"
    assert result.target_normalized == "A01"
    assert result.status == "MATCH"


def test_compare_entity_refs_different_entity_types_require_review():
    source = BusinessEntityRef(
        source="fuente_a",
        entity="area",
        local_id=1,
        business_code="ADM",
    )

    target = BusinessEntityRef(
        source="fuente_b",
        entity="cargo",
        local_id=1,
        business_code="ADM",
    )

    result = compare_entity_refs(source, target)

    assert result.status == "REVIEW"


def test_homologate_entity_collections_unique_match():
    sources = [
        BusinessEntityRef(
            source="fuente_a",
            entity="area",
            local_id=1,
            business_code="A01",
        ),
        BusinessEntityRef(
            source="fuente_a",
            entity="area",
            local_id=2,
            business_code="A02",
        ),
    ]

    targets = [
        BusinessEntityRef(
            source="fuente_b",
            entity="area",
            local_id=100,
            business_code="A01",
        ),
        BusinessEntityRef(
            source="fuente_b",
            entity="area",
            local_id=200,
            business_code="A02",
        ),
    ]

    results = homologate_entity_collections(
        sources,
        targets,
    )

    matches = [
        result
        for result in results
        if result.status == "MATCH"
    ]

    assert len(matches) == 2


def test_homologate_entity_collections_detects_no_match():
    sources = [
        BusinessEntityRef(
            source="fuente_a",
            entity="area",
            local_id=1,
            business_code="A01",
        ),
    ]

    targets = [
        BusinessEntityRef(
            source="fuente_b",
            entity="area",
            local_id=100,
            business_code="A99",
        ),
    ]

    results = homologate_entity_collections(
        sources,
        targets,
    )

    assert len(results) == 1
    assert results[0].status == "NO_MATCH"


def test_homologate_entity_collections_duplicate_code_requires_review():
    sources = [
        BusinessEntityRef(
            source="fuente_a",
            entity="area",
            local_id=1,
            business_code="A01",
        ),
    ]

    targets = [
        BusinessEntityRef(
            source="fuente_b",
            entity="area",
            local_id=100,
            business_code="A01",
        ),
        BusinessEntityRef(
            source="fuente_b",
            entity="area",
            local_id=200,
            business_code=" a01 ",
        ),
    ]

    results = homologate_entity_collections(
        sources,
        targets,
    )

    assert len(results) == 2

    assert all(
        result.status == "REVIEW"
        for result in results
    )


def test_homologate_entity_collections_missing_code_requires_review():
    sources = [
        BusinessEntityRef(
            source="fuente_a",
            entity="area",
            local_id=1,
            business_code=None,
        ),
    ]

    targets = [
        BusinessEntityRef(
            source="fuente_b",
            entity="area",
            local_id=100,
            business_code="A01",
        ),
    ]

    results = homologate_entity_collections(
        sources,
        targets,
    )

    assert len(results) == 1
    assert results[0].status == "REVIEW"


def test_summarize_homologation_results_counts_statuses():
    source = BusinessEntityRef(
        source="fuente_a",
        entity="area",
        local_id=1,
        business_code="A01",
    )

    target_match = BusinessEntityRef(
        source="fuente_b",
        entity="area",
        local_id=10,
        business_code="A01",
    )

    target_no_match = BusinessEntityRef(
        source="fuente_b",
        entity="area",
        local_id=20,
        business_code="A99",
    )

    target_review = BusinessEntityRef(
        source="fuente_b",
        entity="cargo",
        local_id=30,
        business_code="A01",
    )

    results = [
        compare_entity_refs(source, target_match),
        compare_entity_refs(source, target_no_match),
        compare_entity_refs(source, target_review),
    ]

    summary = summarize_homologation_results(results)

    assert isinstance(summary, HomologationSummary)
    assert summary.total == 3
    assert summary.match == 1
    assert summary.no_match == 1
    assert summary.review == 1


def test_summarize_homologation_results_empty():
    summary = summarize_homologation_results([])

    assert summary.total == 0
    assert summary.match == 0
    assert summary.no_match == 0
    assert summary.review == 0
