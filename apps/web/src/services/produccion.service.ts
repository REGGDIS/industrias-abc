import { runtimeConfig } from '../config/runtime';
import type { ProduccionService } from './contracts/produccion.service';
import { produccionApiService } from './api/produccion.api.service';
import { produccionMockService } from './mock/produccion.mock.service';

export const produccionService: ProduccionService =
  runtimeConfig.dataMode === 'api'
    ? produccionApiService
    : produccionMockService;
