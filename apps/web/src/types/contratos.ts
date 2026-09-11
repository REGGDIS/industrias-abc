import type { CategoryValue, MonthlyValue, PaginatedResponse } from './common';

export interface ContratosKpis {
  vigentes: number;
  indefinidos: number;
  plazoFijo: number;
  temporales: number;
  proximosVencer: number;
  vencidos: number;
}

export interface ContratoDetalle {
  contratoId: number;
  empleadoId: number;
  empleado: string;
  tipoContrato: string;
  fechaInicio: string;
  fechaTermino?: string;
  diasRestantes?: number;
  estado: string;
}

export interface ContratosResumen {
  kpis: ContratosKpis;
  contratosPorTipo: CategoryValue[];
  vencimientosPorMes: MonthlyValue[];
}

export type ContratosDetalleResponse =
  PaginatedResponse<ContratoDetalle>;
