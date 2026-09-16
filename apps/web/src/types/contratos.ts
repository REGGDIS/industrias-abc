import type {
  CategoryValue,
  MonthlyValue,
  PaginatedResponse,
} from './common';

export interface ContratosKpis {
  vigentes: number;
  indefinidos: number;
  plazoFijo: number;
  temporales: number;
  proximosVencer: number;
  vencidos: number;
}

export interface ContratosCalidadDatos {
  datosDisponibles: boolean;
  contratosVisibles: number;
  trabajadoresConContrato: number;
}

export interface ContratoDetalle {
  contratoId: number;
  numeroContrato?: string;
  trabajadorId: string;
  empleado: string;
  area?: string;
  tipoContrato: string;
  fechaInicio: string;
  fechaTermino?: string | null;
  diasRestantes?: number | null;
  estado: string;
  jornada?: string;
  cargoContrato?: string;
  sueldoBaseContractual?: number;
}

export interface ContratosResumen {
  periodo?: {
    anio: number;
    mes: number;
    fechaCorte?: string;
  };

  filtrosAplicados?: {
    areaId?: number | null;
    trabajadorId?: string | null;
  };

  kpis: ContratosKpis;
  contratosPorTipo: CategoryValue[];
  vencimientosPorMes: MonthlyValue[];
  calidadDatos?: ContratosCalidadDatos;
}

export type ContratosDetalleResponse =
  PaginatedResponse<ContratoDetalle>;
