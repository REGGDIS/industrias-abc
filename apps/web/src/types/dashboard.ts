import type { CategoryValue, MonthlyValue } from './common';

export interface DashboardKpis {
  totalTrabajadores: number;
  trabajadoresActivos: number;

  costoRemuneraciones: number;
  horasExtras: number;

  totalCompras: number;
  gastosContables: number;

  produccionReal: number;
  cumplimientoProduccion: number;
}

export interface DashboardAreaSummary {
  areaId: number;
  area: string;

  trabajadores: number;
  costoRemuneraciones: number;
  horasExtras: number;
  compras: number;
  gastosContables: number;
  produccion?: number;
}

export interface DashboardResumen {
  kpis: DashboardKpis;
  evolucionMensual: MonthlyValue[];
  principalesCentrosCosto: CategoryValue[];
  resumenPorArea: DashboardAreaSummary[];
}
