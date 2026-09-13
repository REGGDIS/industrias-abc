import { mesesMock } from '../../mocks/catalogs.mock';
import {
  comprasMockRecords,
  type CompraMockRecord,
} from '../../mocks/compras.mock';
import type {
  CompraDetalle,
  ComprasDetalleResponse,
  ComprasResumen,
} from '../../types/compras';
import type { BiFilters } from '../../types/filters';
import type { ComprasService } from '../contracts/compras.service';

function filterRecords(
  filters: BiFilters,
) {
  return comprasMockRecords.filter(
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
        filters.proveedorId &&
        record.proveedorId !==
          filters.proveedorId
      ) {
        return false;
      }

      if (
        filters.insumoId &&
        record.insumoId !==
          filters.insumoId
      ) {
        return false;
      }

      if (
        filters.centroCostoId &&
        record.centroCostoId !==
          filters.centroCostoId
      ) {
        return false;
      }

      return true;
    },
  );
}

function sum(
  records: CompraMockRecord[],
  selector: (
    record: CompraMockRecord,
  ) => number,
) {
  return records.reduce(
    (total, record) =>
      total + selector(record),
    0,
  );
}

function groupBy(
  records: CompraMockRecord[],
  keySelector: (
    record: CompraMockRecord,
  ) => string,
  valueSelector: (
    record: CompraMockRecord,
  ) => number,
) {
  const grouped = new Map<
    string,
    number
  >();

  for (const record of records) {
    const key = keySelector(record);

    grouped.set(
      key,
      (grouped.get(key) ?? 0) +
        valueSelector(record),
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
  records: CompraMockRecord[],
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

    current.value += record.total;

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
        label: `${monthName.slice(
          0,
          3,
        )} ${item.anio}`,
        value: Math.round(item.value),
      };
    });
}

function toDetail(
  record: CompraMockRecord,
): CompraDetalle {
  return {
    ordenCompraId:
      record.ordenCompraId,

    fecha: record.fecha,

    proveedor:
      record.proveedor,

    insumo:
      record.insumo,

    centroCosto:
      record.centroCosto,

    cantidad:
      record.cantidad,

    total:
      record.total,
  };
}

export class ComprasMockService
  implements ComprasService
{
  async getResumen(
    filters: BiFilters = {},
  ): Promise<ComprasResumen> {
    const records =
      filterRecords(filters);

    const totalComprado = sum(
      records,
      (record) => record.total,
    );

    const totalOrdenes =
      records.length;

    const compraPromedio =
      totalOrdenes > 0
        ? Math.round(
            totalComprado /
              totalOrdenes,
          )
        : 0;

    const proveedoresActivos =
      new Set(
        records.map(
          (record) =>
            record.proveedorId,
        ),
      ).size;

    const cumplidas =
      records.filter(
        (record) => record.cumplida,
      ).length;

    const cumplimientoProveedores =
      totalOrdenes > 0
        ? Number(
            (
              (cumplidas /
                totalOrdenes) *
              100
            ).toFixed(1),
          )
        : 0;

    const insumosAdquiridos = sum(
      records,
      (record) =>
        record.cantidad,
    );

    return {
      kpis: {
        totalComprado:
          Math.round(totalComprado),

        totalOrdenes,

        compraPromedio,

        proveedoresActivos,

        cumplimientoProveedores,

        insumosAdquiridos:
          Math.round(
            insumosAdquiridos,
          ),
      },

      evolucionMensual:
        buildMonthlyEvolution(records),

      topProveedores: groupBy(
        records,
        (record) =>
          record.proveedor,
        (record) => record.total,
      ).slice(0, 5),

      topInsumos: groupBy(
        records,
        (record) => record.insumo,
        (record) => record.total,
      ).slice(0, 6),

      comprasPorCentroCosto:
        groupBy(
          records,
          (record) =>
            record.centroCosto,
          (record) => record.total,
        ),
    };
  }

  async getDetalle(
    filters: BiFilters = {},
  ): Promise<ComprasDetalleResponse> {
    const records =
      filterRecords(filters)
        .sort((a, b) =>
          b.fecha.localeCompare(
            a.fecha,
          ),
        )
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

export const comprasMockService =
  new ComprasMockService();
