import { runtimeConfig } from '../../config/runtime';
import type {
  ProduccionDetalleResponse,
  ProduccionResumen,
} from '../../types/produccion';
import type { BiFilters } from '../../types/filters';
import type { ProduccionService } from '../contracts/produccion.service';

interface ApiDetalleResponse {
  items: ProduccionDetalleResponse['items'];
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
    params.set(
      'mes',
      String(filters.mes),
    );
  }

  if (filters.productoId) {
    params.set(
      'productoId',
      String(filters.productoId),
    );
  }

  if (filters.insumoRef) {
    params.set(
      'insumoRef',
      filters.insumoRef,
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

export class ProduccionApiService
  implements ProduccionService
{
  async getResumen(
    filters: BiFilters = {},
  ): Promise<ProduccionResumen> {
    return fetchJson<ProduccionResumen>(
      `/bi/produccion/resumen?${buildQuery(
        filters,
      )}`,
    );
  }

  async getDetalle(
    filters: BiFilters = {},
  ): Promise<ProduccionDetalleResponse> {
    const response =
      await fetchJson<ApiDetalleResponse>(
        `/bi/produccion/detalle?${buildQuery(
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

export const produccionApiService =
  new ProduccionApiService();
