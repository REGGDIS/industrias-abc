import {
  produccionMockRecords,
  type ProduccionMockRecord,
} from '../../mocks/produccion.mock';
import type {
  ProduccionDetalle,
  ProduccionDetalleResponse,
  ProduccionResumen,
} from '../../types/produccion';
import type { BiFilters } from '../../types/filters';
import type { ProduccionService } from '../contracts/produccion.service';

function filterRecords(
  records: ProduccionMockRecord[],
  filters: BiFilters,
) {
  return records.filter((record) => {
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
      filters.productoId &&
      record.productoId !==
        filters.productoId
    ) {
      return false;
    }

    if (
      filters.insumoId &&
      record.insumoId !== filters.insumoId
    ) {
      return false;
    }

    return true;
  });
}

function groupByCategory(
  records: ProduccionMockRecord[],
  key:
    | 'producto'
    | 'insumo',
  value:
    | 'cantidadRechazada'
    | 'consumoInsumo',
) {
  const groups = new Map<
    string,
    number
  >();

  for (const record of records) {
    const label = record[key];

    groups.set(
      label,
      (groups.get(label) ?? 0) +
        record[value],
    );
  }

  return Array.from(groups.entries())
    .map(([label, total]) => ({
      label,
      value:
        Math.round(total * 10) / 10,
    }))
    .sort(
      (a, b) => b.value - a.value,
    );
}

function buildMonthlyEvolution(
  records: ProduccionMockRecord[],
  filters: BiFilters,
) {
  const anio =
    filters.anio ?? 2026;

  const grouped = new Map<
    number,
    number
  >();

  for (const record of records) {
    grouped.set(
      record.mes,
      (grouped.get(record.mes) ?? 0) +
        record.cantidadProducida,
    );
  }

  const meses =
    filters.mes
      ? [filters.mes]
      : Array.from(
          { length: anio === 2026 ? 9 : 12 },
          (_, index) => index + 1,
        );

  const monthLabels = [
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
    'Dic',
  ];

  return meses.map((mes) => ({
    anio,
    mes,
    label: `${monthLabels[mes - 1]} ${anio}`,
    value: grouped.get(mes) ?? 0,
  }));
}

function toDetalle(
  record: ProduccionMockRecord,
): ProduccionDetalle {
  const cumplimiento =
    record.cantidadPlanificada > 0
      ? (record.cantidadProducida /
          record.cantidadPlanificada) *
        100
      : 0;

  return {
    ordenProduccionId:
      record.ordenProduccionId,
    producto: record.producto,
    cantidadPlanificada:
      record.cantidadPlanificada,
    cantidadProducida:
      record.cantidadProducida,
    cantidadRechazada:
      record.cantidadRechazada,
    cumplimiento:
      Math.round(cumplimiento * 10) /
      10,
  };
}

export class ProduccionMockService
  implements ProduccionService
{
  async getResumen(
    filters: BiFilters = {},
  ): Promise<ProduccionResumen> {
    const effectiveFilters: BiFilters = {
      ...filters,
      anio: filters.anio ?? 2026,
    };

    const records = filterRecords(
      produccionMockRecords,
      effectiveFilters,
    );

    const produccionPlanificada =
      records.reduce(
        (total, record) =>
          total +
          record.cantidadPlanificada,
        0,
      );

    const produccionReal =
      records.reduce(
        (total, record) =>
          total +
          record.cantidadProducida,
        0,
      );

    const cantidadRechazada =
      records.reduce(
        (total, record) =>
          total +
          record.cantidadRechazada,
        0,
      );

    const consumoInsumos =
      records.reduce(
        (total, record) =>
          total +
          record.consumoInsumo,
        0,
      );

    const cumplimientoProduccion =
      produccionPlanificada > 0
        ? (produccionReal /
            produccionPlanificada) *
          100
        : 0;

    const tasaRechazo =
      produccionReal > 0
        ? (cantidadRechazada /
            produccionReal) *
          100
        : 0;

    return {
      kpis: {
        produccionPlanificada,
        produccionReal,
        cumplimientoProduccion:
          Math.round(
            cumplimientoProduccion * 10,
          ) / 10,
        cantidadRechazada,
        tasaRechazo:
          Math.round(
            tasaRechazo * 10,
          ) / 10,
        consumoInsumos:
          Math.round(
            consumoInsumos * 10,
          ) / 10,
      },

      evolucionMensual:
        buildMonthlyEvolution(
          filterRecords(
            produccionMockRecords,
            {
              ...effectiveFilters,
              mes: undefined,
            },
          ),
          effectiveFilters,
        ),

      productosConMayorRechazo:
        groupByCategory(
          records,
          'producto',
          'cantidadRechazada',
        ),

      consumoPorInsumo:
        groupByCategory(
          records,
          'insumo',
          'consumoInsumo',
        ),
    };
  }

  async getDetalle(
    filters: BiFilters = {},
  ): Promise<ProduccionDetalleResponse> {
    const effectiveFilters: BiFilters = {
      ...filters,
      anio: filters.anio ?? 2026,
    };

    const records = filterRecords(
      produccionMockRecords,
      effectiveFilters,
    )
      .sort(
        (a, b) =>
          b.fecha.localeCompare(
            a.fecha,
          ),
      )
      .map(toDetalle);

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

export const produccionMockService =
  new ProduccionMockService();
