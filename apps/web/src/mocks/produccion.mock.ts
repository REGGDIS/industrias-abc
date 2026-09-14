import {
  insumosMock,
  productosMock,
} from './catalogs.mock';

export interface ProduccionMockRecord {
  ordenProduccionId: number;

  anio: number;
  mes: number;
  fecha: string;

  productoId: number;
  producto: string;

  insumoId: number;
  insumo: string;

  cantidadPlanificada: number;
  cantidadProducida: number;
  cantidadRechazada: number;

  consumoInsumo: number;
}

function pad(value: number) {
  return String(value).padStart(2, '0');
}

function buildProduccionMock() {
  const records: ProduccionMockRecord[] = [];

  let ordenProduccionId = 1;

  for (const anio of [2025, 2026]) {
    const ultimoMes =
      anio === 2026 ? 9 : 12;

    for (
      let mes = 1;
      mes <= ultimoMes;
      mes += 1
    ) {
      const diasOrden =
        anio === 2026 && mes === 9
          ? [3, 6, 9, 12]
          : [4, 10, 16, 22];

      for (const producto of productosMock) {
        const productoId =
          Number(producto.id);

        for (
          let index = 0;
          index < diasOrden.length;
          index += 1
        ) {
          const dia = diasOrden[index];

          const seed =
            anio +
            mes * 17 +
            productoId * 31 +
            index * 13;

          const cantidadPlanificada =
            420 +
            productoId * 55 +
            mes * 8 +
            (seed % 75);

          const desviacion =
            8 + (seed % 34);

          const cantidadProducida =
            Math.max(
              0,
              cantidadPlanificada -
                desviacion,
            );

          const cantidadRechazada =
            Math.max(
              1,
              Math.round(
                cantidadProducida *
                  (0.012 +
                    (seed % 25) /
                      1000),
              ),
            );

          const insumoIndex =
            (productoId +
              mes +
              index) %
            insumosMock.length;

          const insumo =
            insumosMock[insumoIndex];

          const consumoInsumo =
            Math.round(
              cantidadProducida *
                (1.6 +
                  productoId * 0.12) *
                10,
            ) / 10;

          records.push({
            ordenProduccionId,
            anio,
            mes,
            fecha: `${anio}-${pad(
              mes,
            )}-${pad(dia)}`,

            productoId,
            producto: producto.label,

            insumoId: Number(insumo.id),
            insumo: insumo.label,

            cantidadPlanificada,
            cantidadProducida,
            cantidadRechazada,
            consumoInsumo,
          });

          ordenProduccionId += 1;
        }
      }
    }
  }

  return records;
}

export const produccionMockRecords =
  buildProduccionMock();
