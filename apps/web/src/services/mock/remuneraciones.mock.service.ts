import { mesesMock } from '../../mocks/catalogs.mock';
import {
  remuneracionesMockRecords,
  type RemuneracionMockRecord,
} from '../../mocks/remuneraciones.mock';
import type { BiFilters } from '../../types/filters';
import type {
  RemuneracionDetalle,
  RemuneracionesDetalleResponse,
  RemuneracionesResumen,
} from '../../types/remuneraciones';
import type { RemuneracionesService } from '../contracts/remuneraciones.service';

function filterRecords(
  filters: BiFilters,
) {
  return remuneracionesMockRecords.filter(
    (record) => {
      if (
        filters.anio &&
        record.anio !== filters.anio
      ) {
        return false;
      }

      if (
        filters.mes &&
        record.mes !== filters.mes
      ) {
        return false;
      }

      if (
        filters.areaId &&
        record.areaId !== filters.areaId
      ) {
        return false;
      }

      if (
        filters.empleadoId &&
        record.empleadoId !==
          filters.empleadoId
      ) {
        return false;
      }

      return true;
    },
  );
}

function sum(
  records: RemuneracionMockRecord[],
  selector: (
    record: RemuneracionMockRecord,
  ) => number,
) {
  return records.reduce(
    (total, record) =>
      total + selector(record),
    0,
  );
}

function groupByArea(
  records: RemuneracionMockRecord[],
  selector: (
    record: RemuneracionMockRecord,
  ) => number,
) {
  const grouped = new Map<
    string,
    number
  >();

  for (const record of records) {
    grouped.set(
      record.area,
      (grouped.get(record.area) ?? 0) +
        selector(record),
    );
  }

  return Array.from(grouped.entries())
    .map(([label, value]) => ({
      label,
      value: Math.round(value),
    }))
    .sort((a, b) => b.value - a.value);
}

function buildMonthlyEvolution(
  records: RemuneracionMockRecord[],
) {
  const grouped = new Map<
    string,
    {
      anio: number;
      mes: number;
      value: number;
    }
  >();

  for (const record of records) {
    const key = `${record.anio}-${record.mes}`;

    const current =
      grouped.get(key) ?? {
        anio: record.anio,
        mes: record.mes,
        value: 0,
      };

    current.value +=
      record.costoEmpresa;

    grouped.set(key, current);
  }

  return Array.from(grouped.values())
    .sort(
      (a, b) =>
        a.anio - b.anio ||
        a.mes - b.mes,
    )
    .map((item) => {
      const monthName =
        mesesMock.find(
          (month) =>
            month.id === item.mes,
        )?.label ??
        String(item.mes);

      return {
        anio: item.anio,
        mes: item.mes,
        label: `${monthName.slice(0, 3)} ${item.anio}`,
        value: Math.round(item.value),
      };
    });
}

function toDetail(
  record: RemuneracionMockRecord,
): RemuneracionDetalle {
  const monthName =
    mesesMock.find(
      (month) =>
        month.id === record.mes,
    )?.label ??
    String(record.mes);

  return {
    remuneracionId: record.empleadoId,
    trabajadorId: String(record.empleadoId),
    empleado: record.empleado,
    area: record.area,
    periodo: `${monthName} ${record.anio}`,
    sueldoBase: record.sueldoBase,
    horasExtras:
      record.horasExtrasCantidad,
    totalHaberes: record.totalHaberes,
    sueldoLiquido: record.liquidoEstimado,
    descuentos: record.descuentos,
    costoEmpresa:
      record.costoEmpresa,
  };
}

export class RemuneracionesMockService
  implements RemuneracionesService
{
  async getResumen(
    filters: BiFilters = {},
  ): Promise<RemuneracionesResumen> {
    const records =
      filterRecords(filters);

    const totalHaberes = sum(
      records,
      (record) =>
        record.totalHaberes,
    );

    const descuentos = sum(
      records,
      (record) =>
        record.descuentos,
    );

    const costoEmpresa = sum(
      records,
      (record) =>
        record.costoEmpresa,
    );

    const sueldoPromedio =
      records.length > 0
        ? Math.round(
            totalHaberes /
              records.length,
          )
        : 0;

    return {
      kpis: {
        costoTotal:
          Math.round(totalHaberes),

        sueldoPromedio,        horasExtras: Math.round(
          sum(
            records,
            (record) =>
              record.horasExtrasCantidad,
          ),
        ),
        sueldoLiquido: Math.round(
          sum(
            records,
            (record) =>
              record.liquidoEstimado,
          ),
        ),

        descuentos:
          Math.round(descuentos),

        costoEmpresa:
          Math.round(costoEmpresa),
      },

      costoPorArea: groupByArea(
        records,
        (record) =>
          record.costoEmpresa,
      ),

      evolucionMensual:
        buildMonthlyEvolution(records),

      horasExtrasPorArea:
        groupByArea(
          records,
          (record) =>
            record.horasExtrasCantidad,
        ),
    };
  }

  async getDetalle(
    filters: BiFilters = {},
  ): Promise<RemuneracionesDetalleResponse> {
    const records =
      filterRecords(filters)
        .sort((a, b) => {
          if (a.anio !== b.anio) {
            return b.anio - a.anio;
          }

          if (a.mes !== b.mes) {
            return b.mes - a.mes;
          }

          return a.empleado.localeCompare(
            b.empleado,
          );
        })
        .map(toDetail);

    return {
      items: records.slice(0, 20),

      pagination: {
        page: 1,
        pageSize: 20,
        total: records.length,
      },
    };
  }
}

export const remuneracionesMockService =
  new RemuneracionesMockService();
