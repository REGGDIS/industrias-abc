import type { CategoryValue, MonthlyValue, PaginatedResponse } from './common';

export interface AsistenciaKpis {
  horasTrabajadas: number;
  horasNormales: number;
  horasExtras: number;
  minutosAtraso: number;
  diasAusentes: number;
  ausentismo: number;
}

export interface AsistenciaDetalle {
  empleadoId: number;
  empleado: string;
  fecha: string;
  area: string;
  horasTrabajadas: number;
  horasExtras: number;
  minutosAtraso: number;
  estado: string;
}

export interface AsistenciaResumen {
  kpis: AsistenciaKpis;
  horasExtrasPorArea: CategoryValue[];
  evolucionHorasExtras: MonthlyValue[];
  atrasosPorArea: CategoryValue[];
}

export type AsistenciaDetalleResponse =
  PaginatedResponse<AsistenciaDetalle>;
