import { runtimeConfig } from '../../config/runtime';
import type { BiFilters } from '../../types/filters';
import type {
  RrhhResumen,
  TrabajadorDetalle,
  TrabajadoresResponse,
} from '../../types/rrhh';
import type { RrhhService } from '../contracts/rrhh.service';


interface ApiTrabajadoresResponse {
  items: TrabajadorDetalle[];
  page: number;
  pageSize: number;
  total: number;
  totalPages: number;
}


function buildQuery(
  filters: BiFilters,
  includePagination = false,
) {
  const params = new URLSearchParams();

  params.set(
    'anio',
    String(filters.anio ?? 2026),
  );

  if (filters.mes !== undefined) {
    params.set(
      'mes',
      String(filters.mes),
    );
  }

  if (filters.areaId !== undefined) {
    params.set(
      'areaId',
      String(filters.areaId),
    );
  }

  if (filters.cargoId !== undefined) {
    params.set(
      'cargoId',
      String(filters.cargoId),
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


export class RrhhApiService implements RrhhService {
  async getResumen(
    filters: BiFilters = {},
  ): Promise<RrhhResumen> {
    const query = buildQuery(filters);

    return fetchJson<RrhhResumen>(
      `/bi/rrhh/resumen?${query}`,
    );
  }

  async getTrabajadores(
    filters: BiFilters = {},
  ): Promise<TrabajadoresResponse> {
    const query = buildQuery(
      filters,
      true,
    );

    const response =
      await fetchJson<ApiTrabajadoresResponse>(
        `/bi/rrhh/trabajadores?${query}`,
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


export const rrhhApiService =
  new RrhhApiService();
