import { runtimeConfig } from '../../config/runtime';
import type {
  AnalisisResumen,
} from '../../types/analisis';
import type {
  AnalisisService,
} from '../contracts/analisis.service';

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

export class AnalisisApiService
  implements AnalisisService
{
  getResumen(): Promise<AnalisisResumen> {
    return fetchJson<AnalisisResumen>(
      '/bi/analisis/resumen',
    );
  }
}

export const analisisApiService =
  new AnalisisApiService();
