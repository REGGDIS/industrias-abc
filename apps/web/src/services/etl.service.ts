import { runtimeConfig } from '../config/runtime';
import type {
  EtlService,
} from './contracts/etl.service';
import {
  etlApiService,
} from './api/etl.api.service';
import {
  etlMockService,
} from './mock/etl.mock.service';

export const etlService: EtlService =
  runtimeConfig.dataMode === 'api'
    ? etlApiService
    : etlMockService;
