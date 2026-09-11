import { mesesMock } from '../../mocks/catalogs.mock';
import {
  dashboardMockRecords,
  type DashboardMockRecord,
} from '../../mocks/dashboard.mock';
import type { BiFilters } from '../../types/filters';
import type {
  DashboardAreaSummary,
  DashboardResumen,
} from '../../types/dashboard';
import type { DashboardService } from '../contracts/dashboard.service';

function filterRecords(
  filters: BiFilters = {},
): DashboardMockRecord[] {
  return dashboardMockRecords.filter((record) => {
    if (filters.anio && record.anio !== filters.anio) {
      return false;
    }

    if (filters.mes && record.mes !== filters.mes) {
      return false;
    }

    if (filters.areaId && record.areaId !== filters.areaId) {
      return false;
    }

    if (
      filters.centroCostoId &&
      record.centroCostoId !== filters.centroCostoId
    ) {
      return false;
    }

    return true;
  });
}

function latestPeriodRecords(
  records: DashboardMockRecord[],
): DashboardMockRecord[] {
  if (records.length === 0) {
    return [];
  }

  const latestYear = Math.max(
    ...records.map((record) => record.anio),
  );

  const recordsLatestYear = records.filter(
    (record) => record.anio === latestYear,
  );

  const latestMonth = Math.max(
    ...recordsLatestYear.map((record) => record.mes),
  );

  return recordsLatestYear.filter(
    (record) => record.mes === latestMonth,
  );
}

function sum(
  records: DashboardMockRecord[],
  selector: (record: DashboardMockRecord) => number,
): number {
  return records.reduce(
    (total, record) => total + selector(record),
    0,
  );
}

function buildAreaSummary(
  records: DashboardMockRecord[],
): DashboardAreaSummary[] {
  const groups = new Map<
    number,
    DashboardMockRecord[]
  >();

  for (const record of records) {
    const group = groups.get(record.areaId) ?? [];
    group.push(record);
    groups.set(record.areaId, group);
  }

  const latestRecords = latestPeriodRecords(records);
  const latestByArea = new Map(
    latestRecords.map((record) => [
      record.areaId,
      record,
    ]),
  );

  return Array.from(groups.entries())
    .map(([areaId, group]) => {
      const latest = latestByArea.get(areaId);
      const first = group[0];

      return {
        areaId,
        area: first.area,
        trabajadores:
          latest?.trabajadoresActivos ?? 0,
        costoRemuneraciones: sum(
          group,
          (record) => record.costoRemuneraciones,
        ),
        horasExtras: sum(
          group,
          (record) => record.horasExtras,
        ),
        compras: sum(
          group,
          (record) => record.totalCompras,
        ),
        gastosContables: sum(
          group,
          (record) => record.gastosContables,
        ),
        produccion: sum(
          group,
          (record) => record.produccionReal,
        ),
      };
    })
    .sort(
      (a, b) =>
        b.costoRemuneraciones +
        b.compras +
        b.gastosContables -
        (a.costoRemuneraciones +
          a.compras +
          a.gastosContables),
    );
}

export class DashboardMockService
  implements DashboardService
{
  async getResumen(
    filters: BiFilters = {},
  ): Promise<DashboardResumen> {
    const records = filterRecords(filters);
    const latest = latestPeriodRecords(records);

    const produccionReal = sum(
      records,
      (record) => record.produccionReal,
    );

    const produccionPlanificada = sum(
      records,
      (record) => record.produccionPlanificada,
    );

    const monthGroups = new Map<
      string,
      DashboardMockRecord[]
    >();

    for (const record of records) {
      const key = `${record.anio}-${record.mes}`;
      const group = monthGroups.get(key) ?? [];
      group.push(record);
      monthGroups.set(key, group);
    }

    const evolucionMensual = Array.from(
      monthGroups.entries(),
    )
      .map(([key, group]) => {
        const [anio, mes] = key
          .split('-')
          .map(Number);

        const monthName =
          mesesMock.find(
            (option) => option.id === mes,
          )?.label ?? String(mes);

        return {
          anio,
          mes,
          label: `${monthName.slice(0, 3)} ${anio}`,
          value:
            sum(
              group,
              (record) =>
                record.costoRemuneraciones,
            ) +
            sum(
              group,
              (record) => record.totalCompras,
            ) +
            sum(
              group,
              (record) => record.gastosContables,
            ),
        };
      })
      .sort(
        (a, b) =>
          a.anio - b.anio || a.mes - b.mes,
      );

    const centroGroups = new Map<
      string,
      DashboardMockRecord[]
    >();

    for (const record of records) {
      const group =
        centroGroups.get(record.centroCosto) ?? [];

      group.push(record);
      centroGroups.set(record.centroCosto, group);
    }

    const principalesCentrosCosto = Array.from(
      centroGroups.entries(),
    )
      .map(([label, group]) => ({
        label,
        value:
          sum(
            group,
            (record) =>
              record.costoRemuneraciones,
          ) +
          sum(
            group,
            (record) => record.totalCompras,
          ) +
          sum(
            group,
            (record) => record.gastosContables,
          ),
      }))
      .sort((a, b) => b.value - a.value);

    return {
      kpis: {
        totalTrabajadores: sum(
          latest,
          (record) => record.totalTrabajadores,
        ),

        trabajadoresActivos: sum(
          latest,
          (record) => record.trabajadoresActivos,
        ),

        costoRemuneraciones: sum(
          records,
          (record) => record.costoRemuneraciones,
        ),

        horasExtras: sum(
          records,
          (record) => record.horasExtras,
        ),

        totalCompras: sum(
          records,
          (record) => record.totalCompras,
        ),

        gastosContables: sum(
          records,
          (record) => record.gastosContables,
        ),

        produccionReal,

        cumplimientoProduccion:
          produccionPlanificada === 0
            ? 0
            : (produccionReal /
                produccionPlanificada) *
              100,
      },

      evolucionMensual,
      principalesCentrosCosto,
      resumenPorArea: buildAreaSummary(records),
    };
  }
}

export const dashboardMockService =
  new DashboardMockService();
