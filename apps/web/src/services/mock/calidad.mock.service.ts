import type {
  CalidadResumen,
} from '../../types/calidad';
import type {
  CalidadService,
} from '../contracts/calidad.service';

const mockResumen: CalidadResumen = {
  kpis: {
    registrosEvaluados: 100,
    registrosConIncidencia: 20,
    registrosSinIncidencia: 80,
    porcentajeSinIncidencia: 80,
    reglasConsistenciaOk: 6,
    reglasConsistenciaTotal: 6,
    controlesCompletitudOk: 5,
    controlesCompletitudTotal: 5,
  },
  dominios: [
    {
      dominio: 'ASISTENCIA',
      registros: 30,
      registrosConIncidencia: 0,
      registrosSinIncidencia: 30,
      porcentajeSinIncidencia: 100,
      areaDesconocida: 0,
      centroCostoDesconocido: 0,
      estado: 'OK',
    },
    {
      dominio: 'PRODUCCION',
      registros: 10,
      registrosConIncidencia: 10,
      registrosSinIncidencia: 0,
      porcentajeSinIncidencia: 0,
      areaDesconocida: 10,
      centroCostoDesconocido: 10,
      estado: 'INCIDENCIA',
    },
  ],
  reglas: [
    {
      codigo: 'MOCK_REGLA',
      nombre: 'Regla de consistencia de ejemplo',
      incidencias: 0,
      estado: 'OK',
    },
  ],
  completitud: [
    {
      codigo: 'MOCK_COMPLETITUD',
      nombre: 'Campo crítico informado',
      incidencias: 0,
      estado: 'OK',
    },
  ],
  evaluacionesEspeciales: [
    {
      codigo: 'MOCK_EVALUACION',
      nombre: 'Evaluación especial',
      estado: 'NO_EVALUABLE',
      detalle:
        'Modo mock: evaluación de ejemplo.',
    },
  ],
  advertencias: [
    'Modo mock: datos sintéticos para validar la interfaz.',
  ],
};

export class CalidadMockService
  implements CalidadService
{
  async getResumen(): Promise<CalidadResumen> {
    return mockResumen;
  }
}

export const calidadMockService =
  new CalidadMockService();
