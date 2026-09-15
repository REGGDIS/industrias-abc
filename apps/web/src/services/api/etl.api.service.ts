import { runtimeConfig } from '../../config/runtime';
import type {
  EtlResumen,
} from '../../types/etl';
import type {
  EtlService,
} from '../contracts/etl.service';

async function fetchJson<T>(
  path: string,
): Promise<T> {
  const response = await fetch(
    `${runtimeConfig.apiUrl}${path}`,
  );

  if (!response.ok) {
    throw new Error(
      `Error API ${response.status}`,
    );
  }

  return response.json() as Promise<T>;
}

export class EtlApiService
  implements EtlService
{
  getResumen(): Promise<EtlResumen> {
    return fetchJson<EtlResumen>(
      '/bi/etl/resumen',
    );
  }
}

export const etlApiService =
  new EtlApiService();
