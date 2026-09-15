import { runtimeConfig } from '../../config/runtime';
import type {
  ContratosDetalleResponse,
  ContratosResumen,
} from '../../types/contratos';
import type { BiFilters } from '../../types/filters';
import type { ContratosService } from '../contracts/contratos.service';

interface ApiDetalleResponse {
  items: ContratosDetalleResponse['items'];
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
    String(filters.anio ?? 2026),
  );

  if (filters.mes) {
    params.set('mes', String(filters.mes));
  }

  if (filters.areaId) {
    params.set(
      'areaId',
      String(filters.areaId),
    );
  }

  if (filters.trabajadorId) {
    params.set(
      'trabajadorId',
      filters.trabajadorId,
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

export class ContratosApiService
  implements ContratosService
{
  async getResumen(
    filters: BiFilters = {},
  ): Promise<ContratosResumen> {
    return fetchJson<ContratosResumen>(
      `/bi/contratos/resumen?${buildQuery(filters)}`,
    );
  }

  async getDetalle(
    filters: BiFilters = {},
  ): Promise<ContratosDetalleResponse> {
    const response =
      await fetchJson<ApiDetalleResponse>(
        `/bi/contratos/detalle?${buildQuery(
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

export const contratosApiService =
  new ContratosApiService();
