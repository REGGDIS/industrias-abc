from etl.config.staging import get_staging_table_names


def build_postgres_clean_table_sql(
    source: str,
    entity: str,
    select_sql: str,
) -> str:
    names = get_staging_table_names(source, entity)

    normalized_select = select_sql.strip().rstrip(";")

    if not normalized_select:
        raise ValueError(
            "La consulta de limpieza no puede estar vacía."
        )

    return f"""
DROP TABLE IF EXISTS {names.clean};

CREATE TABLE {names.clean} AS
{normalized_select};
""".strip()
