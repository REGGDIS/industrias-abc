import pytest

from etl.transform.business_keys import normalize_business_code


@pytest.mark.parametrize(
    "value, expected",
    [
        ("A01", "A01"),
        (" a01 ", "A01"),
        ("compras", "COMPRAS"),
        ("  CC-01  ", "CC-01"),
        ("", None),
        ("   ", None),
        (None, None),
    ],
)
def test_normalize_business_code(value, expected):
    assert normalize_business_code(value) == expected
