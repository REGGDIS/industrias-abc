import psycopg

from etl.config.settings import (
    get_compras_db_config,
    get_contabilidad_db_config,
    get_rrhh_db_config,
)
from etl.transform.homologation import (
    BusinessEntityRef,
    homologate_entity_collections,
    summarize_homologation_results,
)


def fetch_areas(source_name, config):
    with psycopg.connect(
        host=config.host,
        port=config.port,
        dbname=config.database,
        user=config.user,
        password=config.password,
    ) as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT area_id, codigo_area, nombre_area
                FROM areas
                ORDER BY area_id
                """
            )
            rows = cur.fetchall()

    return [
        BusinessEntityRef(
            source=source_name,
            entity="area",
            local_id=area_id,
            business_code=codigo_area,
            display_name=nombre_area,
        )
        for area_id, codigo_area, nombre_area in rows
    ]


def print_results(title, results):
    print()
    print(title)
    print("-" * len(title))

    for result in results:
        source_name = (result.source.display_name or "").strip()
        target_name = (result.target.display_name or "").strip()

        names_match = source_name.casefold() == target_name.casefold()
        name_status = "OK" if names_match else "DIFERENTE"

        print(
            f'{result.source.source}:{result.source.local_id} '
            f'{result.source.business_code} '
            f'"{source_name}" '
            f'-> '
            f'{result.target.source}:{result.target.local_id} '
            f'{result.target.business_code} '
            f'"{target_name}" '
            f'[{result.status} | nombre={name_status}]'
        )

    summary = summarize_homologation_results(results)

    print(
        f"Resumen: total={summary.total}, "
        f"match={summary.match}, "
        f"no_match={summary.no_match}, "
        f"review={summary.review}"
    )


def main():
    rrhh_areas = fetch_areas("rrhh", get_rrhh_db_config())
    compras_areas = fetch_areas("compras", get_compras_db_config())
    contabilidad_areas = fetch_areas(
        "contabilidad",
        get_contabilidad_db_config(),
    )

    rrhh_vs_compras = homologate_entity_collections(
        rrhh_areas,
        compras_areas,
    )

    rrhh_vs_contabilidad = homologate_entity_collections(
        rrhh_areas,
        contabilidad_areas,
    )

    print_results(
        "RRHH vs Compras",
        rrhh_vs_compras,
    )

    print_results(
        "RRHH vs Contabilidad",
        rrhh_vs_contabilidad,
    )


if __name__ == "__main__":
    main()
