export type EtlStatus =
  | 'SUCCESS'
  | 'PARTIAL'
  | 'ERROR'
  | 'RUNNING';

export interface EtlKpis {
  procesosMonitoreados: number;
  success: number;
  partial: number;
  error: number;
  running: number;
  registrosLeidos: number;
  registrosRechazados: number;
  registrosReview: number;
  ultimaEjecucion: string | null;
}

export interface EtlEjecucion {
  executionId: number;
  source: string;
  process: string;
  startedAt: string;
  finishedAt: string | null;
  duracionSegundos: number | null;
  recordsRead: number;
  recordsValid: number;
  recordsInserted: number;
  recordsUpdated: number;
  recordsUnchanged: number;
  recordsRejected: number;
  recordsReview: number;
  status: EtlStatus;
  message: string | null;
}

export interface EtlResumen {
  kpis: EtlKpis;
  ultimasEjecuciones: EtlEjecucion[];
  historial: EtlEjecucion[];
  advertencias: string[];
}
