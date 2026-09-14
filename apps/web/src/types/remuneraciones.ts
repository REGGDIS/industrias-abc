import type { CategoryValue, MonthlyValue, PaginatedResponse } from './common';

export interface RemuneracionesKpis {
  costoTotal: number;
  sueldoPromedio: number;
  costoHorasExtras: number;
  bonificaciones: number;
  descuentos: number;
  costoEmpresa: number;
}

export interface RemuneracionDetalle {
  empleadoId: number;
  empleado: string;
  area: string;
  periodo: string;
  sueldoBase: number;
  horasExtras: number;
  bonos: number;
  descuentos: number;
  costoEmpresa: number;
}

export interface RemuneracionesResumen {
  kpis: RemuneracionesKpis;
  costoPorArea: CategoryValue[];
  evolucionMensual: MonthlyValue[];
  horasExtrasPorArea: CategoryValue[];
}

export type RemuneracionesDetalleResponse =
  PaginatedResponse<RemuneracionDetalle>;
