import { runtimeConfig } from '../config/runtime';
import type { ContabilidadService } from './contracts/contabilidad.service';
import { contabilidadApiService } from './api/contabilidad.api.service';
import { contabilidadMockService } from './mock/contabilidad.mock.service';

export const contabilidadService: ContabilidadService =
  runtimeConfig.dataMode === 'api'
    ? contabilidadApiService
    : contabilidadMockService;
