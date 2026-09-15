import { runtimeConfig } from '../config/runtime';
import type { ComprasService } from './contracts/compras.service';
import { comprasApiService } from './api/compras.api.service';
import { comprasMockService } from './mock/compras.mock.service';

export const comprasService: ComprasService =
  runtimeConfig.dataMode === 'api'
    ? comprasApiService
    : comprasMockService;
