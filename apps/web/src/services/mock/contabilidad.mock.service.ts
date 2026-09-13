import { mesesMock } from '../../mocks/catalogs.mock';
import {
  contabilidadMockRecords,
  cuentasGastoMock,
  type MovimientoContableMock,
} from '../../mocks/contabilidad.mock';
import type {
  ContabilidadResumen,
  MovimientoContable,
  MovimientosContablesResponse,
} from '../../types/contabilidad';
import type { BiFilters } from '../../types/filters';
import type { ContabilidadService } from '../contracts/contabilidad.service';

const gastoAccountIds = new Set(
  cuentasGastoMock.map(
    (cuenta) =>
      cuenta.cuentaContableId,
  ),
);

function filterRecords(
  filters: BiFilters,
) {
  return contabilidadMockRecords.filter(
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
        filters.centroCostoId &&
        record.centroCostoId !==
          filters.centroCostoId
      ) {
        return false;
      }

      if (
        filters.cuentaContableId &&
        record.cuentaContableId !==
          filters.cuentaContableId
      ) {
        return false;
      }

      if (
        filters.areaId &&
        record.areaId !== filters.areaId
      ) {
        return false;
      }

      return true;
    },
  );
}

function sum(
  records: MovimientoContableMock[],
  selector: (
    record: MovimientoContableMock,
  ) => number,
) {
  return records.reduce(
    (total, record) =>
      total + selector(record),
    0,
  );
}

function onlyExpenses(
  records: MovimientoContableMock[],
) {
  return records.filter((record) =>
    gastoAccountIds.has(
      record.cuentaContableId,
    ),
  );
}

function groupExpenses(
  records: MovimientoContableMock[],
  keySelector: (
    record: MovimientoContableMock,
  ) => string,
) {
  const grouped = new Map<
    string,
    number
  >();

  for (const record of onlyExpenses(records)) {
    const key = keySelector(record);

    grouped.set(
      key,
      (grouped.get(key) ?? 0) +
        record.debe,
    );
  }

  return Array.from(grouped.entries())
    .map(([label, value]) => ({
      label,
      value: Math.round(value),
    }))
    .sort((a, b) => b.value - a.value);
}

function buildEvolution(
  records: MovimientoContableMock[],
) {
  const grouped = new Map<
    string,
    {
      anio: number;
      mes: number;
      value: number;
    }
  >();

  for (const record of onlyExpenses(records)) {
    const key =
      `${record.anio}-${record.mes}`;

    const current =
      grouped.get(key) ?? {
        anio: record.anio,
        mes: record.mes,
        value: 0,
      };

    current.value += record.debe;

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

function calculateVariation(
  filters: BiFilters,
) {
  if (!filters.anio) {
    return undefined;
  }

  const targetMonth =
    filters.mes ??
    (filters.anio === 2026
      ? 9
      : 12);

  const isPartialCurrentMonth =
    filters.anio === 2026 &&
    targetMonth === 9;

  if (isPartialCurrentMonth) {
    return undefined;
  }

  const currentRecords =
    contabilidadMockRecords.filter(
      (record) =>
        record.anio === filters.anio &&
        record.mes === targetMonth &&
        (!filters.centroCostoId ||
          record.centroCostoId ===
            filters.centroCostoId) &&
        (!filters.cuentaContableId ||
          record.cuentaContableId ===
            filters.cuentaContableId),
    );

  let previousYear =
    filters.anio;
  let previousMonth =
    targetMonth - 1;

  if (previousMonth === 0) {
    previousMonth = 12;
    previousYear -= 1;
  }

  const previousRecords =
    contabilidadMockRecords.filter(
      (record) =>
        record.anio === previousYear &&
        record.mes === previousMonth &&
        (!filters.centroCostoId ||
          record.centroCostoId ===
            filters.centroCostoId) &&
        (!filters.cuentaContableId ||
          record.cuentaContableId ===
            filters.cuentaContableId),
    );

  const current =
    sum(
      onlyExpenses(currentRecords),
      (record) => record.debe,
    );

  const previous =
    sum(
      onlyExpenses(previousRecords),
      (record) => record.debe,
    );

  if (previous === 0) {
    return undefined;
  }

  return Number(
    (
      ((current - previous) /
        previous) *
      100
    ).toFixed(1),
  );
}

function toDetail(
  record: MovimientoContableMock,
): MovimientoContable {
  return {
    movimientoId:
      record.movimientoId,

    fecha:
      record.fecha,

    cuentaContable:
      record.cuentaContable,

    centroCosto:
      record.centroCosto,

    documento:
      record.documento,

    debe:
      record.debe,

    haber:
      record.haber,

    saldo:
      record.debe -
      record.haber,
  };
}

export class ContabilidadMockService
  implements ContabilidadService
{
  async getResumen(
    filters: BiFilters = {},
  ): Promise<ContabilidadResumen> {
    const records =
      filterRecords(filters);

    const expenses =
      onlyExpenses(records);

    const gastosTotales = sum(
      expenses,
      (record) => record.debe,
    );

    const debeTotal = sum(
      records,
      (record) => record.debe,
    );

    const haberTotal = sum(
      records,
      (record) => record.haber,
    );

    const saldo =
      debeTotal - haberTotal;

    const gastosPorCentroCosto =
      groupExpenses(
        records,
        (record) =>
          record.centroCosto,
      );

    return {
      kpis: {
        gastosTotales:
          Math.round(
            gastosTotales,
          ),

        debeTotal:
          Math.round(debeTotal),

        haberTotal:
          Math.round(haberTotal),

        saldo:
          Math.round(saldo),

        mayorCentroCosto:
          gastosPorCentroCosto[0]
            ?.label,

        variacionMensual:
          calculateVariation(filters),
      },

      evolucionGastos:
        buildEvolution(records),

      gastosPorCuenta:
        groupExpenses(
          records,
          (record) =>
            record.cuentaContable,
        ),

      gastosPorCentroCosto,

      gastosPorArea:
        groupExpenses(
          records,
          (record) => record.area,
        ),
    };
  }

  async getMovimientos(
    filters: BiFilters = {},
  ): Promise<MovimientosContablesResponse> {
    const records =
      filterRecords(filters)
        .sort((a, b) => {
          const dateCompare =
            b.fecha.localeCompare(
              a.fecha,
            );

          if (dateCompare !== 0) {
            return dateCompare;
          }

          return (
            b.movimientoId -
            a.movimientoId
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

export const contabilidadMockService =
  new ContabilidadMockService();
