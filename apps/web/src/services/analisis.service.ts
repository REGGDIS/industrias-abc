import { runtimeConfig } from '../config/runtime';
import type {
  AnalisisService,
} from './contracts/analisis.service';
import {
  analisisApiService,
} from './api/analisis.api.service';
import {
  analisisMockService,
} from './mock/analisis.mock.service';

export const analisisService: AnalisisService =
  runtimeConfig.dataMode === 'api'
    ? analisisApiService
    : analisisMockService;
