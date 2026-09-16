from etl.transform.rut import normalize_rut


def test_normalize_rut_with_dots_and_dash():
    assert normalize_rut("12.345.678-5") == "12345678-5"


def test_normalize_rut_without_dots():
    assert normalize_rut("12345678-5") == "12345678-5"


def test_normalize_rut_without_dash():
    assert normalize_rut("123456785") == "12345678-5"


def test_normalize_rut_with_k():
    assert normalize_rut("12.345.678-k") == "12345678-K"


def test_normalize_rut_none():
    assert normalize_rut(None) is None
