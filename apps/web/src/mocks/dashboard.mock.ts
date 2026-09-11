export interface DashboardMockRecord {
  anio: number;
  mes: number;

  areaId: number;
  area: string;

  centroCostoId: number;
  centroCosto: string;

  totalTrabajadores: number;
  trabajadoresActivos: number;

  costoRemuneraciones: number;
  horasExtras: number;

  totalCompras: number;
  gastosContables: number;

  produccionReal: number;
  produccionPlanificada: number;
}

interface AreaSeed {
  areaId: number;
  area: string;
  centroCostoId: number;
  centroCosto: string;

  trabajadores: number;
  costoRemuneraciones: number;
  horasExtras: number;
  compras: number;
  gastosContables: number;

  produccionReal: number;
  produccionPlanificada: number;
}

const areas: AreaSeed[] = [
  {
    areaId: 1,
    area: 'Recursos Humanos',
    centroCostoId: 1,
    centroCosto: 'CC-RRHH',
    trabajadores: 10,
    costoRemuneraciones: 12800000,
    horasExtras: 72,
    compras: 1400000,
    gastosContables: 2200000,
    produccionReal: 0,
    produccionPlanificada: 0,
  },
  {
    areaId: 2,
    area: 'Compras y Abastecimiento',
    centroCostoId: 2,
    centroCosto: 'CC-COMPRAS',
    trabajadores: 14,
    costoRemuneraciones: 17600000,
    horasExtras: 118,
    compras: 23500000,
    gastosContables: 3900000,
    produccionReal: 0,
    produccionPlanificada: 0,
  },
  {
    areaId: 3,
    area: 'Contabilidad',
    centroCostoId: 3,
    centroCosto: 'CC-CONTABILIDAD',
    trabajadores: 12,
    costoRemuneraciones: 15800000,
    horasExtras: 94,
    compras: 1100000,
    gastosContables: 8400000,
    produccionReal: 0,
    produccionPlanificada: 0,
  },
  {
    areaId: 4,
    area: 'Producción',
    centroCostoId: 4,
    centroCosto: 'CC-PRODUCCION',
    trabajadores: 34,
    costoRemuneraciones: 36800000,
    horasExtras: 438,
    compras: 19800000,
    gastosContables: 12600000,
    produccionReal: 8450,
    produccionPlanificada: 9800,
  },
  {
    areaId: 5,
    area: 'Administración',
    centroCostoId: 5,
    centroCosto: 'CC-ADMIN',
    trabajadores: 10,
    costoRemuneraciones: 14200000,
    horasExtras: 61,
    compras: 2800000,
    gastosContables: 4700000,
    produccionReal: 0,
    produccionPlanificada: 0,
  },
];

function monthFactor(mes: number) {
  return 0.9 + mes * 0.018;
}

function yearFactor(anio: number) {
  return anio === 2026 ? 1.06 : 1;
}

function createRecord(
  anio: number,
  mes: number,
  seed: AreaSeed,
): DashboardMockRecord {
  const factor = monthFactor(mes) * yearFactor(anio);

  const totalTrabajadores =
    seed.trabajadores +
    ((mes + seed.areaId) % 4 === 0 ? 1 : 0);

  const trabajadoresActivos =
    totalTrabajadores -
    ((mes + seed.areaId) % 7 === 0 ? 1 : 0);

  const productionFactor =
    seed.areaId === 4
      ? 0.96 + ((mes % 4) - 1) * 0.025
      : 0;

  const produccionPlanificada =
    seed.produccionPlanificada === 0
      ? 0
      : Math.round(seed.produccionPlanificada * factor);

  const produccionReal =
    produccionPlanificada === 0
      ? 0
      : Math.round(produccionPlanificada * productionFactor);

  return {
    anio,
    mes,

    areaId: seed.areaId,
    area: seed.area,

    centroCostoId: seed.centroCostoId,
    centroCosto: seed.centroCosto,

    totalTrabajadores,
    trabajadoresActivos,

    costoRemuneraciones: Math.round(
      seed.costoRemuneraciones * factor,
    ),

    horasExtras: Math.round(
      seed.horasExtras *
        factor *
        (0.92 + (mes % 3) * 0.05),
    ),

    totalCompras: Math.round(
      seed.compras *
        factor *
        (0.9 + (mes % 4) * 0.04),
    ),

    gastosContables: Math.round(
      seed.gastosContables *
        factor *
        (0.94 + (mes % 5) * 0.025),
    ),

    produccionReal,
    produccionPlanificada,
  };
}

function buildYear(
  anio: number,
  ultimoMes: number,
): DashboardMockRecord[] {
  const records: DashboardMockRecord[] = [];

  for (let mes = 1; mes <= ultimoMes; mes += 1) {
    for (const area of areas) {
      records.push(createRecord(anio, mes, area));
    }
  }

  return records;
}

export const dashboardMockRecords: DashboardMockRecord[] = [
  ...buildYear(2025, 12),
  ...buildYear(2026, 9),
];
