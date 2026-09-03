import pytest

from etl.config.staging import get_staging_table_names


def test_staging_names_rrhh():
    names = get_staging_table_names("rrhh", "empleados")

    assert names.raw == "stg_rrhh_empleados_raw"
    assert names.clean == "stg_rrhh_empleados_clean"


def test_staging_names_normalizes_input():
    names = get_staging_table_names(
        " CONTABILIDAD ", " MOVIMIENTOS_CONTABLES ")

    assert names.raw == "stg_contabilidad_movimientos_contables_raw"
    assert names.clean == "stg_contabilidad_movimientos_contables_clean"


@pytest.mark.parametrize(
    "source, entity",
    [
        ("", "empleados"),
        ("rrhh", ""),
        ("   ", "empleados"),
        ("rrhh", "   "),
    ],
)
def test_staging_names_rejects_empty_values(source, entity):
    with pytest.raises(ValueError):
        get_staging_table_names(source, entity)


@pytest.mark.parametrize(
    "source, entity",
    [
        ("rrhh-test", "empleados"),
        ("rrhh", "empleados;drop_table"),
        ("rrhh", "empleados test"),
        ("rrhh", "empleados.test"),
    ],
)
def test_staging_names_rejects_invalid_identifiers(source, entity):
    with pytest.raises(ValueError):
        get_staging_table_names(source, entity)
