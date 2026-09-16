from __future__ import annotations

import csv
from datetime import date
from decimal import Decimal
from pathlib import Path

import pymysql

from etl.config.settings import get_produccion_db_config
from etl.validate.produccion import (
    ConsumoMysqlProduccion,
    CsvConsumoProduccion,
    parse_decimal,
    reconcile_consumos,
)


PROJECT_ROOT = Path(__file__).resolve().parents[2]

CSV_PATH = (
    PROJECT_ROOT
    / "sources"
    / "produccion-mysql-csv"
    / "csv"
    / "consumo_insumos_complementario.csv"
)


def parse_date(value: str) -> date:
    return date.fromisoformat(value.strip())


def fetch_mysql_consumos() -> list[ConsumoMysqlProduccion]:
    config = get_produccion_db_config()

    conn = pymysql.connect(
        host=config.host,
        port=config.port,
        database=config.database,
        user=config.user,
        password=config.password,
        charset="utf8mb4",
        use_unicode=True,
        cursorclass=pymysql.cursors.Cursor,
    )

    try:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT
                    ci.orden_produccion_id,
                    op.numero_orden,
                    ci.insumo_id,
                    ci.cantidad_planificada,
                    ci.cantidad_consumida,
                    ci.fecha_consumo
                FROM consumo_insumos ci
                INNER JOIN ordenes_produccion op
                    ON op.orden_produccion_id = ci.orden_produccion_id
                ORDER BY
                    ci.orden_produccion_id,
                    ci.insumo_id
                """
            )

            rows = cur.fetchall()
    finally:
        conn.close()

    return [
        ConsumoMysqlProduccion(
            orden_produccion_id=int(orden_produccion_id),
            numero_orden=numero_orden,
            insumo_id=int(insumo_id),
            cantidad_planificada=Decimal(
                str(cantidad_planificada)
            ),
            cantidad_consumida=Decimal(
                str(cantidad_consumida)
            ),
            fecha_consumo=fecha_consumo,
        )
        for (
            orden_produccion_id,
            numero_orden,
            insumo_id,
            cantidad_planificada,
            cantidad_consumida,
            fecha_consumo,
        ) in rows
    ]


def read_csv_consumos(
    path: Path = CSV_PATH,
) -> list[CsvConsumoProduccion]:
    required_columns = {
        "numero_orden",
        "insumo_codigo_o_referencia",
        "cantidad_planificada",
        "cantidad_consumida",
        "fecha_consumo",
    }

    if not path.exists():
        raise FileNotFoundError(
            f"No se encontró el CSV de Producción: {path}"
        )

    with path.open(
        mode="r",
        encoding="utf-8-sig",
        newline="",
    ) as file:
        reader = csv.DictReader(file)

        actual_columns = set(reader.fieldnames or [])

        missing_columns = required_columns - actual_columns

        if missing_columns:
            raise ValueError(
                "Faltan columnas requeridas en el CSV: "
                + ", ".join(sorted(missing_columns))
            )

        rows: list[CsvConsumoProduccion] = []

        for line_number, row in enumerate(
            reader,
            start=2,
        ):
            try:
                rows.append(
                    CsvConsumoProduccion(
                        numero_orden=row["numero_orden"],
                        insumo_codigo_o_referencia=(
                            row["insumo_codigo_o_referencia"]
                        ),
                        cantidad_planificada=parse_decimal(
                            row["cantidad_planificada"]
                        ),
                        cantidad_consumida=parse_decimal(
                            row["cantidad_consumida"]
                        ),
                        fecha_consumo=parse_date(
                            row["fecha_consumo"]
                        ),
                    )
                )
            except Exception as exc:
                raise ValueError(
                    f"Error en CSV línea {line_number}: {exc}"
                ) from exc

    return rows


def print_results(results) -> None:
    match = 0
    no_match = 0
    review = 0

    print()
    print("Reconciliación Producción MySQL vs CSV")
    print("--------------------------------------")

    for result in results:
        csv_row = result.csv_row
        mysql_row = result.mysql_row

        if result.status == "MATCH":
            match += 1
        elif result.status == "NO_MATCH":
            no_match += 1
        else:
            review += 1

        print(
            f"{csv_row.numero_orden} "
            f"{csv_row.insumo_codigo_o_referencia} "
            f"[{result.status}]"
        )

        print(
            f"  CSV: "
            f"planificada={csv_row.cantidad_planificada}, "
            f"consumida={csv_row.cantidad_consumida}, "
            f"fecha={csv_row.fecha_consumo}"
        )

        if mysql_row is not None:
            print(
                f"  MySQL: "
                f"orden_id={mysql_row.orden_produccion_id}, "
                f"insumo_id={mysql_row.insumo_id}, "
                f"planificada={mysql_row.cantidad_planificada}, "
                f"consumida={mysql_row.cantidad_consumida}, "
                f"fecha={mysql_row.fecha_consumo}"
            )

        print(
            f"  detalle: {result.detail}"
        )

    print()
    print(
        f"Resumen: total={len(results)}, "
        f"match={match}, "
        f"no_match={no_match}, "
        f"review={review}"
    )


def main() -> None:
    csv_rows = read_csv_consumos()
    mysql_rows = fetch_mysql_consumos()

    results = reconcile_consumos(
        csv_rows,
        mysql_rows,
    )

    print_results(results)


if __name__ == "__main__":
    main()
