export type CalidadEstado =
  | 'OK'
  | 'INCIDENCIA'
  | 'ADVERTENCIA'
  | 'NO_EVALUABLE';

export interface CalidadKpis {
  registrosEvaluados: number;
  registrosConIncidencia: number;
  registrosSinIncidencia: number;
  porcentajeSinIncidencia: number;
  reglasConsistenciaOk: number;
  reglasConsistenciaTotal: number;
  controlesCompletitudOk: number;
  controlesCompletitudTotal: number;
}

export interface CalidadDominio {
  dominio: string;
  registros: number;
  registrosConIncidencia: number;
  registrosSinIncidencia: number;
  porcentajeSinIncidencia: number;
  areaDesconocida: number;
  centroCostoDesconocido: number;
  estado: CalidadEstado;
}

export interface CalidadRegla {
  codigo: string;
  nombre: string;
  incidencias: number;
  estado: CalidadEstado;
}

export interface CalidadEvaluacionEspecial {
  codigo: string;
  nombre: string;
  estado: CalidadEstado;
  detalle: string;
}

export interface CalidadResumen {
  kpis: CalidadKpis;
  dominios: CalidadDominio[];
  reglas: CalidadRegla[];
  completitud: CalidadRegla[];
  evaluacionesEspeciales: CalidadEvaluacionEspecial[];
  advertencias: string[];
}
