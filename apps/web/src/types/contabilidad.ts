import type { CategoryValue, MonthlyValue, PaginatedResponse } from './common';

export interface ContabilidadKpis {
  gastosTotales: number;
  debeTotal: number;
  haberTotal: number;
  saldo: number;
  mayorCentroCosto?: string;
  variacionMensual?: number;
}

export interface MovimientoContable {
  movimientoId: number;
  fecha: string;
  cuentaContable: string;
  centroCosto: string;
  documento?: string;
  debe: number;
  haber: number;
  saldo: number;
}

export interface ContabilidadResumen {
  kpis: ContabilidadKpis;
  evolucionGastos: MonthlyValue[];
  gastosPorCuenta: CategoryValue[];
  gastosPorCentroCosto: CategoryValue[];
  gastosPorArea: CategoryValue[];
}

export type MovimientosContablesResponse =
  PaginatedResponse<MovimientoContable>;
