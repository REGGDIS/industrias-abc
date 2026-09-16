import { runtimeConfig } from '../../config/runtime';
import type {
  ContabilidadResumen,
  MovimientosContablesResponse,
} from '../../types/contabilidad';
import type { BiFilters } from '../../types/filters';
import type { ContabilidadService } from '../contracts/contabilidad.service';

interface ApiMovimientosResponse {
  items: MovimientosContablesResponse['items'];
  page: number;
  pageSize: number;
  total: number;
  totalPages: number;
}

function buildQuery(
  filters: BiFilters = {},
  includePagination = false,
) {
  const params = new URLSearchParams();

  params.set(
    'anio',
    String(filters.anio ?? 2025),
  );

  if (filters.mes) {
    params.set(
      'mes',
      String(filters.mes),
    );
  }

  if (filters.centroCostoId) {
    params.set(
      'centroCostoId',
      String(filters.centroCostoId),
    );
  }

  if (filters.cuentaContableId) {
    params.set(
      'cuentaContableId',
      String(filters.cuentaContableId),
    );
  }

  if (includePagination) {
    params.set('page', '1');
    params.set('pageSize', '20');
  }

  return params.toString();
}

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

export class ContabilidadApiService
  implements ContabilidadService
{
  async getResumen(
    filters: BiFilters = {},
  ): Promise<ContabilidadResumen> {
    return fetchJson<ContabilidadResumen>(
      `/bi/contabilidad/resumen?${buildQuery(
        filters,
      )}`,
    );
  }

  async getMovimientos(
    filters: BiFilters = {},
  ): Promise<MovimientosContablesResponse> {
    const response =
      await fetchJson<ApiMovimientosResponse>(
        `/bi/contabilidad/movimientos?${buildQuery(
          filters,
          true,
        )}`,
      );

    return {
      items: response.items,
      pagination: {
        page: response.page,
        pageSize: response.pageSize,
        total: response.total,
      },
    };
  }
}

export const contabilidadApiService =
  new ContabilidadApiService();
