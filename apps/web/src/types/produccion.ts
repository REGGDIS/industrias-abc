import type { CategoryValue, MonthlyValue, PaginatedResponse } from './common';

export interface ProduccionKpis {
  produccionPlanificada: number;
  produccionReal: number;
  cumplimientoProduccion: number;
  cantidadRechazada: number;
  tasaRechazo: number;
  consumoInsumos: number;
}

export interface ProduccionDetalle {
  ordenProduccionId: number;
  producto: string;
  cantidadPlanificada: number;
  cantidadProducida: number;
  cantidadRechazada: number;
  cumplimiento: number;
}

export interface ProduccionResumen {
  kpis: ProduccionKpis;
  evolucionMensual: MonthlyValue[];
  productosConMayorRechazo: CategoryValue[];
  consumoPorInsumo: CategoryValue[];
}

export type ProduccionDetalleResponse =
  PaginatedResponse<ProduccionDetalle>;
