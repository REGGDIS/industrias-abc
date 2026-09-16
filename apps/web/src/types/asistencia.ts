import type {
  CategoryValue,
  MonthlyValue,
  PaginatedResponse,
} from './common';

export interface AsistenciaKpis {
  horasTrabajadas: number;
  horasNormales: number;
  horasExtras: number;
  minutosAtraso: number;
  diasAusentes: number;
  ausentismo: number | null;
}

export interface AsistenciaCalidadDatos {
  datosDisponibles: boolean;
  registros: number;
  trabajadoresConAsistencia: number;
  totalTrabajadoresPeriodo: number;
  porcentajeCobertura: number | null;
  coberturaParcial: boolean;
  fechaDesdeDatos: string | null;
  fechaHastaDatos: string | null;
  diasTrabajados: number;
  diasAusentes: number;
  jornadasObservadas: number;
}

export interface AsistenciaDetalle {
  asistenciaId: number | string;
  trabajadorId: string;
  empleado: string;
  fecha: string;
  area: string;
  turno?: string;
  horaEntrada?: string | null;
  horaSalida?: string | null;
  horasTrabajadas: number;
  horasNormales?: number;
  horasExtras: number;
  minutosAtraso: number;
  estado: string;
}

export interface AsistenciaResumen {
  kpis: AsistenciaKpis;
  horasExtrasPorArea: CategoryValue[];
  evolucionHorasExtras: MonthlyValue[];
  atrasosPorArea: CategoryValue[];
  calidadDatos?: AsistenciaCalidadDatos;
}

export type AsistenciaDetalleResponse =
  PaginatedResponse<AsistenciaDetalle>;
