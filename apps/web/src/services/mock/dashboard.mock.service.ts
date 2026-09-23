import {
  dashboardMockRecords,
} from '../../mocks/dashboard.mock';
import type {
  DashboardResumen,
} from '../../types/dashboard';
import type { DashboardService } from '../contracts/dashboard.service';

function sum(
  values: number[],
): number {
  return values.reduce(
    (total, value) => total + value,
    0,
  );
}

function getLatestPeriod() {
  const latestYear = Math.max(
    ...dashboardMockRecords.map(
      (record) => record.anio,
    ),
  );

  const latestMonth = Math.max(
    ...dashboardMockRecords
      .filter(
        (record) =>
          record.anio === latestYear,
      )
      .map(
        (record) => record.mes,
      ),
  );

  return {
    anio: latestYear,
    mes: latestMonth,
  };
}

export class DashboardMockService
  implements DashboardService
{
  async getResumen(): Promise<DashboardResumen> {
    const periodo = getLatestPeriod();

    const latest = dashboardMockRecords.filter(
      (record) =>
        record.anio === periodo.anio &&
        record.mes === periodo.mes,
    );

    const totalTrabajadores = sum(
      latest.map(
        (record) =>
          record.totalTrabajadores,
      ),
    );

    const trabajadoresActivos = sum(
      latest.map(
        (record) =>
          record.trabajadoresActivos,
      ),
    );

    const horasExtras = sum(
      latest.map(
        (record) => record.horasExtras,
      ),
    );

    const costoRemuneraciones = sum(
      latest.map(
        (record) =>
          record.costoRemuneraciones,
      ),
    );

    const totalCompras = sum(
      latest.map(
        (record) => record.totalCompras,
      ),
    );

    const produccionPlanificada = sum(
      latest.map(
        (record) =>
          record.produccionPlanificada,
      ),
    );

    const produccionReal = sum(
      latest.map(
        (record) =>
          record.produccionReal,
      ),
    );

    const cumplimientoProduccion =
      produccionPlanificada === 0
        ? 0
        : (
            produccionReal /
            produccionPlanificada
          ) * 100;

    const produccionRechazada = 128;

    const tasaRechazoProduccion =
      produccionReal === 0
        ? 0
        : (
            produccionRechazada /
            produccionReal
          ) * 100;

    const fechaMock =
      `${periodo.anio}-` +
      `${String(periodo.mes).padStart(
        2,
        '0',
      )}-01`;

    return {
      kpis: {
        totalTrabajadores,
        empleadosConAsistencia:
          trabajadoresActivos,

        horasExtrasAsistencia:
          horasExtras,
        minutosAtraso: 0,
        diasAusentes: 0,

        costoRemuneraciones,
        costoHorasExtra: 782082,
        sueldoLiquido: 0,

        totalCompras,
        ordenesCompra: 0,
        ordenesCompraEfectivas: 0,

        movimientosContables: 0,
        totalDebeContabilidad: 0,
        totalHaberContabilidad: 0,
        saldoContabilidad: 0,

        produccionPlanificada,
        produccionReal,
        produccionRechazada,
        cumplimientoProduccion,
        tasaRechazoProduccion,
        ordenesProduccion: 0,
      },

      periodos: {
        rrhh: fechaMock,
        asistencia: fechaMock,
        remuneraciones: fechaMock,
        compras: periodo,
        contabilidad: periodo,
        produccion: periodo,
      },

      principalesCentrosCosto: [
        {
          label: 'ADMINISTRACIÓN GENERAL',
          value: 3500000,
        },
        {
          label: 'MANTENCIÓN INDUSTRIAL',
          value: 1800000,
        },
        {
          label: 'LOGÍSTICA Y BODEGA',
          value: 950000,
        },
      ],

      periodoCentrosCosto: 2025,

      evolucionMensual: [
        {
          anio: 2025,
          mes: 1,
          label: 'Ene 2025',
          value: 3500000,
        },
        {
          anio: 2025,
          mes: 2,
          label: 'Feb 2025',
          value: 0,
        },
        {
          anio: 2025,
          mes: 3,
          label: 'Mar 2025',
          value: 1800000,
        },
        {
          anio: 2025,
          mes: 4,
          label: 'Abr 2025',
          value: 950000,
        },
        {
          anio: 2025,
          mes: 5,
          label: 'May 2025',
          value: 0,
        },
      ],

      cobertura: [
        {
          dominio: 'ASISTENCIA',
          fechaDesde: '2025-01-01',
          fechaHasta: fechaMock,
          registros:
            dashboardMockRecords.length,
        },
        {
          dominio: 'COMPRAS',
          fechaDesde: '2025-01-01',
          fechaHasta: fechaMock,
          registros:
            dashboardMockRecords.length,
        },
        {
          dominio: 'CONTABILIDAD',
          fechaDesde: '2025-01-01',
          fechaHasta: fechaMock,
          registros:
            dashboardMockRecords.length,
        },
        {
          dominio: 'PRODUCCION',
          fechaDesde: '2025-01-01',
          fechaHasta: fechaMock,
          registros:
            dashboardMockRecords.length,
        },
        {
          dominio: 'REMUNERACIONES',
          fechaDesde: '2025-01-01',
          fechaHasta: fechaMock,
          registros:
            dashboardMockRecords.length,
        },
      ],

      advertencias: [
        (
          'Modo mock activo: los valores mostrados '
          + 'son datos sintéticos para demostración.'
        ),
      ],
    };
  }
}

export const dashboardMockService =
  new DashboardMockService();
