import { runtimeConfig } from '../config/runtime';
import type { RemuneracionesService } from './contracts/remuneraciones.service';
import { remuneracionesApiService } from './api/remuneraciones.api.service';
import { remuneracionesMockService } from './mock/remuneraciones.mock.service';

export const remuneracionesService: RemuneracionesService =
  runtimeConfig.dataMode === 'api'
    ? remuneracionesApiService
    : remuneracionesMockService;
