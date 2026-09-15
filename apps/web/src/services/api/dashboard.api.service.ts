import { runtimeConfig } from '../../config/runtime';
import type {
  DashboardResumen,
} from '../../types/dashboard';
import type { DashboardService } from '../contracts/dashboard.service';

async function fetchJson<T>(
  path: string,
): Promise<T> {
  const response = await fetch(
    `${runtimeConfig.apiUrl}${path}`,
  );

  if (!response.ok) {
    const message = await response.text();

    throw new Error(
      `Error API ${response.status}: ${message}`,
    );
  }

  return response.json() as Promise<T>;
}

export class DashboardApiService
  implements DashboardService
{
  async getResumen(): Promise<DashboardResumen> {
    return fetchJson<DashboardResumen>(
      '/bi/dashboard/resumen',
    );
  }
}

export const dashboardApiService =
  new DashboardApiService();
