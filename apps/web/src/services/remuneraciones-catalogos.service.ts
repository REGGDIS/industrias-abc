import { runtimeConfig } from '../config/runtime';
import {
  aniosMock,
  areasMock,
  mesesMock,
} from '../mocks/catalogs.mock';
import { rrhhMockEmpleados } from '../mocks/rrhh.mock';
import type { SelectOption } from '../types/common';
import type { BiFilters } from '../types/filters';

interface PeriodosApiResponse {
  anios: number[];
  meses: SelectOption[];
  ultimoPeriodoDisponible: {
    anio: number;
    mes: number;
  } | null;
  fechaMaximaDisponible: string | null;
}

interface ItemsResponse {
  items: SelectOption[];
}

export interface RemuneracionesCatalogos {
  anios: SelectOption[];
  meses: SelectOption[];
  areas: SelectOption[];
  trabajadores: SelectOption[];
  ultimoPeriodoDisponible: {
    anio: number;
    mes: number;
  } | null;
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

function buildTrabajadoresQuery(
  filters: BiFilters,
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

  return params.toString();
}

async function getApiCatalogos(
  filters: BiFilters,
): Promise<RemuneracionesCatalogos> {
  const [
    periodos,
    areasResponse,
    trabajadoresResponse,
  ] = await Promise.all([
    fetchJson<PeriodosApiResponse>(
      '/bi/catalogos/periodos?dominio=remuneraciones',
    ),
    fetchJson<ItemsResponse>(
      '/bi/catalogos/areas',
    ),
    fetchJson<ItemsResponse>(
      `/bi/remuneraciones/trabajadores?${buildTrabajadoresQuery(
        filters,
      )}`,
    ),
  ]);

  return {
    anios: periodos.anios.map((anio) => ({
      id: anio,
      label: String(anio),
    })),
    meses: periodos.meses,
    areas: areasResponse.items,
    trabajadores: trabajadoresResponse.items,
    ultimoPeriodoDisponible:
      periodos.ultimoPeriodoDisponible,
  };
}

function getMockCatalogos(): RemuneracionesCatalogos {
  return {
    anios: aniosMock,
    meses: mesesMock,
    areas: areasMock,
    trabajadores: rrhhMockEmpleados.map(
      (empleado) => ({
        id: String(empleado.empleadoId),
        label: empleado.nombre,
      }),
    ),
    ultimoPeriodoDisponible: null,
  };
}

export async function getRemuneracionesCatalogos(
  filters: BiFilters,
): Promise<RemuneracionesCatalogos> {
  if (runtimeConfig.dataMode === 'api') {
    return getApiCatalogos(filters);
  }

  return getMockCatalogos();
}
