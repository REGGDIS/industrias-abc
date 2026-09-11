import type { BiFilters } from '../../types/filters';
import type { DashboardResumen } from '../../types/dashboard';

export interface DashboardService {
  getResumen(filters?: BiFilters): Promise<DashboardResumen>;
}
