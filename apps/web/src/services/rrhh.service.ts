import { runtimeConfig } from '../config/runtime';
import type { RrhhService } from './contracts/rrhh.service';
import { rrhhApiService } from './api/rrhh.api.service';
import { rrhhMockService } from './mock/rrhh.mock.service';


export const rrhhService: RrhhService =
  runtimeConfig.dataMode === 'api'
    ? rrhhApiService
    : rrhhMockService;
