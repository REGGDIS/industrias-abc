import { runtimeConfig } from '../config/runtime';
import type { AsistenciaService } from './contracts/asistencia.service';
import { asistenciaApiService } from './api/asistencia.api.service';
import { asistenciaMockService } from './mock/asistencia.mock.service';

export const asistenciaService: AsistenciaService =
  runtimeConfig.dataMode === 'api'
    ? asistenciaApiService
    : asistenciaMockService;
