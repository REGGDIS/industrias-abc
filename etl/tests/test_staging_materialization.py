import pytest

from etl.load.staging import build_postgres_clean_table_sql


def test_build_postgres_clean_table_sql():
    sql = build_postgres_clean_table_sql(
        "rrhh",
        "empleados",
        "SELECT empleado_id FROM stg_rrhh_empleados_raw;",
    )

    assert "DROP TABLE IF EXISTS stg_rrhh_empleados_clean;" in sql
    assert "CREATE TABLE stg_rrhh_empleados_clean AS" in sql
    assert "SELECT empleado_id FROM stg_rrhh_empleados_raw;" in sql


def test_build_postgres_clean_table_sql_normalizes_names():
    sql = build_postgres_clean_table_sql(
        " CONTABILIDAD ",
        " AREAS ",
        "SELECT area_id FROM stg_contabilidad_areas_raw;",
    )

    assert "stg_contabilidad_areas_clean" in sql


@pytest.mark.parametrize(
    "select_sql",
    [
        "",
        "   ",
        ";",
        " ; ",
    ],
)
def test_build_postgres_clean_table_sql_rejects_empty_query(select_sql):
    with pytest.raises(ValueError):
        build_postgres_clean_table_sql(
            "rrhh",
            "empleados",
            select_sql,
        )
