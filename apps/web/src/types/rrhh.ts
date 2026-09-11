import type { CategoryValue, MonthlyValue, PaginatedResponse } from './common';

export interface RrhhKpis {
  totalTrabajadores: number;
  trabajadoresActivos: number;
  trabajadoresInactivos: number;
  rotacion: number;
  ausentismo: number;
  contratosProximosVencer: number;
}

export interface TrabajadorDetalle {
  empleadoId: number;
  nombre: string;
  rut: string;
  area: string;
  cargo: string;
  fechaIngreso: string;
  estado: string;
}

export interface RrhhResumen {
  kpis: RrhhKpis;
  trabajadoresPorArea: CategoryValue[];
  trabajadoresPorCargo: CategoryValue[];
  evolucionDotacion: MonthlyValue[];
}

export type TrabajadoresResponse = PaginatedResponse<TrabajadorDetalle>;
