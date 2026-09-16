import { runtimeConfig } from '../config/runtime';
import type { ContratosService } from './contracts/contratos.service';
import { contratosApiService } from './api/contratos.api.service';
import { contratosMockService } from './mock/contratos.mock.service';

export const contratosService: ContratosService =
  runtimeConfig.dataMode === 'api'
    ? contratosApiService
    : contratosMockService;
