import { runtimeConfig } from '../config/runtime';
import type { DashboardService } from './contracts/dashboard.service';
import { dashboardApiService } from './api/dashboard.api.service';
import { dashboardMockService } from './mock/dashboard.mock.service';

export const dashboardService: DashboardService =
  runtimeConfig.dataMode === 'api'
    ? dashboardApiService
    : dashboardMockService;
