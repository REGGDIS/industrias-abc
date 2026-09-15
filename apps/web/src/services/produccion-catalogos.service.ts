import { runtimeConfig } from '../config/runtime';
import {
  aniosMock,
  mesesMock,
} from '../mocks/catalogs.mock';
import {
  produccionMockRecords,
} from '../mocks/produccion.mock';
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

export interface ProduccionCatalogos {
  anios: SelectOption[];
  meses: SelectOption[];
  productos: SelectOption[];
  insumos: SelectOption[];
  ultimoPeriodoDisponible: {
    anio: number;
    mes: number;
  } | null;
  fechaMaximaDisponible: string | null;
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

async function getApiCatalogos(
  filters: BiFilters,
): Promise<ProduccionCatalogos> {
  const [
    periodos,
    productosResponse,
    insumosResponse,
  ] = await Promise.all([
    fetchJson<PeriodosApiResponse>(
      `/bi/catalogos/periodos?dominio=produccion${
        filters.anio
          ? `&anio=${filters.anio}`
          : ''
      }`,
    ),
    fetchJson<ItemsResponse>(
      '/bi/catalogos/productos-produccion',
    ),
    fetchJson<ItemsResponse>(
      '/bi/catalogos/insumos-produccion',
    ),
  ]);

  return {
    anios: periodos.anios.map(
      (anio) => ({
        id: anio,
        label: String(anio),
      }),
    ),
    meses: periodos.meses,
    productos: productosResponse.items,
    insumos: insumosResponse.items,
    ultimoPeriodoDisponible:
      periodos.ultimoPeriodoDisponible,
    fechaMaximaDisponible:
      periodos.fechaMaximaDisponible,
  };
}

function getMockCatalogos():
  ProduccionCatalogos {
  const productos = Array.from(
    new Map(
      produccionMockRecords.map(
        (record) => [
          record.productoId,
          {
            id: record.productoId,
            label: record.producto,
          },
        ],
      ),
    ).values(),
  );

  const insumos = Array.from(
    new Map(
      produccionMockRecords.map(
        (record) => [
          record.insumo,
          {
            id: record.insumo,
            label: record.insumo,
          },
        ],
      ),
    ).values(),
  );

  return {
    anios: aniosMock,
    meses: mesesMock,
    productos,
    insumos,
    ultimoPeriodoDisponible: null,
    fechaMaximaDisponible: null,
  };
}

export async function getProduccionCatalogos(
  filters: BiFilters,
): Promise<ProduccionCatalogos> {
  if (runtimeConfig.dataMode === 'api') {
    return getApiCatalogos(filters);
  }

  return getMockCatalogos();
}
