import type {
  EtlResumen,
} from '../../types/etl';
import type {
  EtlService,
} from '../contracts/etl.service';

const mockResumen: EtlResumen = {
  kpis: {
    procesosMonitoreados: 6,
    success: 4,
    partial: 2,
    error: 0,
    running: 0,
    registrosLeidos: 500,
    registrosRechazados: 0,
    registrosReview: 20,
    ultimaEjecucion:
      '2026-09-14T16:40:55',
  },
  ultimasEjecuciones: [
    {
      executionId: 1,
      source: 'RRHH',
      process: 'ETL_DW_RRHH',
      startedAt:
        '2026-09-14T16:40:55',
      finishedAt:
        '2026-09-14T16:40:56',
      duracionSegundos: 0.65,
      recordsRead: 100,
      recordsValid: 100,
      recordsInserted: 0,
      recordsUpdated: 0,
      recordsUnchanged: 100,
      recordsRejected: 0,
      recordsReview: 0,
      status: 'SUCCESS',
      message:
        'Modo mock: ejecución correcta.',
    },
    {
      executionId: 2,
      source: 'PRODUCCION',
      process: 'ETL_DW_PRODUCCION',
      startedAt:
        '2026-09-14T16:26:30',
      finishedAt:
        '2026-09-14T16:26:31',
      duracionSegundos: 0.31,
      recordsRead: 40,
      recordsValid: 40,
      recordsInserted: 0,
      recordsUpdated: 0,
      recordsUnchanged: 30,
      recordsRejected: 0,
      recordsReview: 20,
      status: 'PARTIAL',
      message:
        'Modo mock: registros pendientes de revisión.',
    },
  ],
  historial: [],
  advertencias: [
    'Modo mock: datos sintéticos para validar la interfaz.',
  ],
};

export class EtlMockService
  implements EtlService
{
  async getResumen(): Promise<EtlResumen> {
    return mockResumen;
  }
}

export const etlMockService =
  new EtlMockService();
