import pytest

from etl.transform.homologation import compare_business_codes


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
