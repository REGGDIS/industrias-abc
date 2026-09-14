import type {
  CategoryValue,
  MonthlyValue,
  PaginatedResponse,
} from './common';

export interface RrhhKpis {
  totalTrabajadores: number;
  trabajadoresActivos: number;
  trabajadoresInactivos: number;
  rotacion: number | null;
  ausentismo: number | null;
  contratosProximosVencer: number;
}

export interface RrhhCalidadDatos {
  contextoHistoricoEstimado: boolean;
  rotacion?: {
    fechaDesde: string;
    fechaHasta: string;
    salidas: number;
    dotacionInicio: number;
    dotacionFin: number;
    dotacionPromedio: number;
  };
  contratos?: {
    ventanaDias: number;
    fechaCorte: string;
    trabajadoresConContrato: number;
    totalTrabajadoresPeriodo: number;
    porcentajeCobertura: number | null;
    coberturaParcial: boolean;
  };
  ausentismo?: {
    periodoSolicitadoDesde: string;
    periodoSolicitadoHasta: string;
    fechaDesdeDatos: string | null;
    fechaHastaDatos: string | null;
    registros: number;
    trabajadoresConAsistencia: number;
    totalTrabajadoresPeriodo: number;
    porcentajeCobertura: number | null;
    diasTrabajados: number;
    diasAusentes: number;
    jornadasObservadas: number;
    coberturaParcial: boolean;
    datosDisponibles: boolean;
  };
}

export interface RrhhResumen {
  kpis: RrhhKpis;
  trabajadoresPorArea: CategoryValue[];
  trabajadoresPorCargo: CategoryValue[];
  evolucionDotacion: MonthlyValue[];
  calidadDatos?: RrhhCalidadDatos;
}

export interface TrabajadorDetalle {
  trabajadorId: string;
  nombre: string;
  rut: string;
  area: string;
  cargo: string;
  fechaIngreso: string;
  fechaSalida?: string | null;
  estado: string;
  contextoHistoricoEstimado?: boolean;
}

export type TrabajadoresResponse =
  PaginatedResponse<TrabajadorDetalle>;
