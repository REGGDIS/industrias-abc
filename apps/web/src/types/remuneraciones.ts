import type {
  CategoryValue,
  MonthlyValue,
  PaginatedResponse,
} from './common';

export interface RemuneracionesKpis {
  costoTotal: number;
  sueldoPromedio: number;
  horasExtras: number;
  sueldoLiquido: number;
  descuentos: number;
  costoEmpresa: number;
}

export interface RemuneracionesCalidadDatos {
  datosDisponibles: boolean;
  registros: number;
  trabajadoresConRemuneracion: number;
  totalTrabajadoresRrhh: number;
  porcentajeCobertura: number;
  coberturaParcial: boolean;
}

export interface RemuneracionDetalle {
  remuneracionId: number;
  trabajadorId: string;
  empleado: string;
  area: string;
  periodo: string;
  sueldoBase: number;
  horasExtras: number;
  totalHaberes: number;
  descuentos: number;
  sueldoLiquido: number;
  costoEmpresa: number;
}

export interface RemuneracionesResumen {
  periodo?: {
    anio: number;
    mes: number;
  };

  filtrosAplicados?: {
    areaId?: number | null;
    trabajadorId?: string | null;
  };

  kpis: RemuneracionesKpis;
  costoPorArea: CategoryValue[];
  evolucionMensual: MonthlyValue[];
  horasExtrasPorArea: CategoryValue[];
  calidadDatos?: RemuneracionesCalidadDatos;
}

export type RemuneracionesDetalleResponse =
  PaginatedResponse<RemuneracionDetalle>;
