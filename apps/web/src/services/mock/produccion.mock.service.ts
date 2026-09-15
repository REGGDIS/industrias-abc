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
      filters.insumoRef &&
      record.insumo !==
        filters.insumoRef
    ) {
      return false;
    }

    return true;
  });
}

function groupRechazo(
  records: ProduccionMockRecord[],
) {
  const groups = new Map<string, number>();

  for (const record of records) {
    groups.set(
      record.producto,
      (groups.get(record.producto) ?? 0) +
        record.cantidadRechazada,
    );
  }

  return Array.from(groups.entries())
    .map(([label, value]) => ({
      label,
      value:
        Math.round(value * 10) / 10,
    }))
    .filter((item) => item.value > 0)
    .sort((a, b) => b.value - a.value);
}

function groupEstados(
  records: ProduccionMockRecord[],
) {
  return [
    {
      label: 'TERMINADA',
      value: records.length,
    },
  ];
}

function groupConsumos(
  records: ProduccionMockRecord[],
) {
  const groups = new Map<
    string,
    {
      planificado: number;
      consumido: number;
    }
  >();

  for (const record of records) {
    const current =
      groups.get(record.insumo) ?? {
        planificado: 0,
        consumido: 0,
      };

    current.planificado +=
      record.consumoInsumo;

    current.consumido +=
      record.consumoInsumo;

    groups.set(
      record.insumo,
      current,
    );
  }

  return Array.from(groups.entries())
    .map(([label, value]) => ({
      label,
      planificado:
        Math.round(
          value.planificado * 10,
        ) / 10,
      consumido:
        Math.round(
          value.consumido * 10,
        ) / 10,
      desviacion: 0,
    }))
    .sort(
      (a, b) =>
        b.consumido - a.consumido,
    );
}

function buildMonthlyEvolution(
  records: ProduccionMockRecord[],
  anio: number,
) {
  const groups = new Map<
    number,
    {
      planificada: number;
      producida: number;
      rechazada: number;
    }
  >();

  for (const record of records) {
    const current =
      groups.get(record.mes) ?? {
        planificada: 0,
        producida: 0,
        rechazada: 0,
      };

    current.planificada +=
      record.cantidadPlanificada;

    current.producida +=
      record.cantidadProducida;

    current.rechazada +=
      record.cantidadRechazada;

    groups.set(
      record.mes,
      current,
    );
  }

  const labels = [
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

  return Array.from(
    groups.entries(),
  )
    .sort(
      ([mesA], [mesB]) =>
        mesA - mesB,
    )
    .map(([mes, value]) => ({
      anio,
      mes,
      label:
        `${labels[mes - 1]} ${anio}`,
      planificada:
        value.planificada,
      producida:
        value.producida,
      rechazada:
        value.rechazada,
    }));
}

function toDetalle(
  record: ProduccionMockRecord,
): ProduccionDetalle {
  return {
    produccionId:
      record.ordenProduccionId,
    numeroOrden:
      `OP-MOCK-${String(
        record.ordenProduccionId,
      ).padStart(4, '0')}`,
    fechaInicio:
      record.fecha,
    fechaTermino:
      record.fecha,
    productoCodigo:
      `MOCK-${record.productoId}`,
    producto:
      record.producto,
    categoria:
      'Producción mock',
    unidadMedida:
      'UN',
    cantidadPlanificada:
      record.cantidadPlanificada,
    cantidadProducida:
      record.cantidadProducida,
    cantidadRechazada:
      record.cantidadRechazada,
    estado:
      'TERMINADA',
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

    const planificada =
      records.reduce(
        (total, record) =>
          total +
          record.cantidadPlanificada,
        0,
      );

    const producida =
      records.reduce(
        (total, record) =>
          total +
          record.cantidadProducida,
        0,
      );

    const rechazada =
      records.reduce(
        (total, record) =>
          total +
          record.cantidadRechazada,
        0,
      );

    const cumplimiento =
      planificada > 0
        ? producida /
          planificada *
          100
        : 0;

    const tasaRechazo =
      producida > 0
        ? rechazada /
          producida *
          100
        : 0;

    const evolucionRecords =
      filterRecords(
        produccionMockRecords,
        {
          ...effectiveFilters,
          mes: undefined,
        },
      );

    const productosActivos =
      new Set(
        records.map(
          (record) =>
            record.productoId,
        ),
      ).size;

    return {
      periodo: {
        anio:
          effectiveFilters.anio ??
          2026,
        mes:
          effectiveFilters.mes ??
          0,
      },

      filtrosAplicados: {
        productoId:
          effectiveFilters.productoId ??
          null,
        insumoRef:
          effectiveFilters.insumoRef ??
          null,
      },

      kpis: {
        cantidadPlanificada:
          planificada,
        cantidadProducida:
          producida,
        cumplimientoProduccion:
          Math.round(
            cumplimiento * 100,
          ) / 100,
        cantidadRechazada:
          rechazada,
        tasaRechazo:
          Math.round(
            tasaRechazo * 100,
          ) / 100,
        totalOrdenes:
          records.length,
        productosActivos,
      },

      evolucionMensual:
        buildMonthlyEvolution(
          evolucionRecords,
          effectiveFilters.anio ??
            2026,
        ),

      rechazoPorProducto:
        groupRechazo(records),

      ordenesPorEstado:
        groupEstados(records),

      consumoPorInsumo:
        groupConsumos(records),
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
      items:
        records.slice(0, 20),
      pagination: {
        page: 1,
        pageSize: 20,
        total:
          records.length,
      },
    };
  }
}

export const produccionMockService =
  new ProduccionMockService();
