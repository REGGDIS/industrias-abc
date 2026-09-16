import { runtimeConfig } from '../config/runtime';
import type {
  CalidadService,
} from './contracts/calidad.service';
import {
  calidadApiService,
} from './api/calidad.api.service';
import {
  calidadMockService,
} from './mock/calidad.mock.service';

export const calidadService: CalidadService =
  runtimeConfig.dataMode === 'api'
    ? calidadApiService
    : calidadMockService;
