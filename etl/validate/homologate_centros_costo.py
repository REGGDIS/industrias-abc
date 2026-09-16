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


ENTITY_TYPE = "centro_costo"


def fetch_rrhh_centros_costo() -> list[BusinessEntityRef]:
    config = get_rrhh_db_config()

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
                SELECT
                    centro_costo_id,
                    codigo_centro_costo,
                    nombre_centro_costo
                FROM centros_costo
                ORDER BY centro_costo_id
                """
            )

            rows = cur.fetchall()

    return [
        BusinessEntityRef(
            source="rrhh",
            entity=ENTITY_TYPE,
            local_id=centro_costo_id,
            business_code=codigo_centro_costo,
            display_name=nombre_centro_costo,
        )
        for (
            centro_costo_id,
            codigo_centro_costo,
            nombre_centro_costo,
        ) in rows
    ]


def fetch_compras_centros_costo() -> list[BusinessEntityRef]:
    config = get_compras_db_config()

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
                SELECT
                    centro_costo_id,
                    codigo_centro,
                    nombre_centro
                FROM centros_costo
                ORDER BY centro_costo_id
                """
            )

            rows = cur.fetchall()

    return [
        BusinessEntityRef(
            source="compras",
            entity=ENTITY_TYPE,
            local_id=centro_costo_id,
            business_code=codigo_centro,
            display_name=nombre_centro,
        )
        for (
            centro_costo_id,
            codigo_centro,
            nombre_centro,
        ) in rows
    ]


def fetch_contabilidad_centros_costo() -> list[BusinessEntityRef]:
    config = get_contabilidad_db_config()

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
                SELECT
                    centro_costo_id,
                    codigo,
                    nombre
                FROM centros_costo
                ORDER BY centro_costo_id
                """
            )

            rows = cur.fetchall()

    return [
        BusinessEntityRef(
            source="contabilidad",
            entity=ENTITY_TYPE,
            local_id=centro_costo_id,
            business_code=codigo,
            display_name=nombre,
        )
        for (
            centro_costo_id,
            codigo,
            nombre,
        ) in rows
    ]


def names_match(
    source_name: str | None,
    target_name: str | None,
) -> bool:
    if source_name is None or target_name is None:
        return False

    return source_name.strip().casefold() == target_name.strip().casefold()


def print_results(
    title: str,
    results,
) -> None:
    print()
    print(title)
    print("-" * len(title))

    for result in results:
        source = result.source
        target = result.target

        if result.status == "MATCH":
            name_status = (
                "OK"
                if names_match(
                    source.display_name,
                    target.display_name,
                )
                else "DIFERENTE"
            )

            print(
                f"{source.source}:{source.local_id} "
                f'{source.business_code} "{source.display_name}" '
                f"-> "
                f"{target.source}:{target.local_id} "
                f'{target.business_code} "{target.display_name}" '
                f"[MATCH | nombre={name_status}]"
            )

        elif result.status == "NO_MATCH":
            print(
                f"{source.source}:{source.local_id} "
                f'{source.business_code} "{source.display_name}" '
                f"-> sin coincidencia "
                f"[NO_MATCH]"
            )

        else:
            print(
                f"{source.source}:{source.local_id} "
                f'{source.business_code} "{source.display_name}" '
                f"-> requiere revisión "
                f"[REVIEW]"
            )

    summary = summarize_homologation_results(results)

    print()
    print(
        f"Resumen: total={summary.total}, "
        f"match={summary.match}, "
        f"no_match={summary.no_match}, "
        f"review={summary.review}"
    )


def main() -> None:
    rrhh = fetch_rrhh_centros_costo()
    compras = fetch_compras_centros_costo()
    contabilidad = fetch_contabilidad_centros_costo()

    rrhh_vs_compras = homologate_entity_collections(
        rrhh,
        compras,
    )

    rrhh_vs_contabilidad = homologate_entity_collections(
        rrhh,
        contabilidad,
    )

    print_results(
        "RRHH vs Compras - Centros de costo",
        rrhh_vs_compras,
    )

    print_results(
        "RRHH vs Contabilidad - Centros de costo",
        rrhh_vs_contabilidad,
    )


if __name__ == "__main__":
    main()
