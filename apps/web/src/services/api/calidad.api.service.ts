import { runtimeConfig } from '../../config/runtime';
import type {
  CalidadResumen,
} from '../../types/calidad';
import type {
  CalidadService,
} from '../contracts/calidad.service';

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

export class CalidadApiService
  implements CalidadService
{
  getResumen(): Promise<CalidadResumen> {
    return fetchJson<CalidadResumen>(
      '/bi/calidad/resumen',
    );
  }
}

export const calidadApiService =
  new CalidadApiService();
