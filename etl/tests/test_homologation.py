import pytest

from etl.transform.homologation import (
    BusinessEntityRef,
    compare_business_codes,
    compare_entity_refs,
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
