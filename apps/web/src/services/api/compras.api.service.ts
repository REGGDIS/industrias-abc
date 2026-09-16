import { runtimeConfig } from '../../config/runtime';
import type {
  ComprasDetalleResponse,
  ComprasResumen,
} from '../../types/compras';
import type { BiFilters } from '../../types/filters';
import type { ComprasService } from '../contracts/compras.service';

interface ApiDetalleResponse {
  items: ComprasDetalleResponse['items'];
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

  if (filters.proveedorId) {
    params.set(
      'proveedorId',
      String(filters.proveedorId),
    );
  }

  if (filters.insumoId) {
    params.set(
      'insumoId',
      String(filters.insumoId),
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

export class ComprasApiService
  implements ComprasService
{
  async getResumen(
    filters: BiFilters = {},
  ): Promise<ComprasResumen> {
    return fetchJson<ComprasResumen>(
      `/bi/compras/resumen?${buildQuery(
        filters,
      )}`,
    );
  }

  async getDetalle(
    filters: BiFilters = {},
  ): Promise<ComprasDetalleResponse> {
    const response =
      await fetchJson<ApiDetalleResponse>(
        `/bi/compras/detalle?${buildQuery(
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

export const comprasApiService =
  new ComprasApiService();
