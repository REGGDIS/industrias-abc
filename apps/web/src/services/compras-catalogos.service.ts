import { runtimeConfig } from '../config/runtime';
import {
  proveedoresComprasMock,
  insumosComprasMock,
} from '../mocks/compras.mock';
import {
  aniosMock,
  mesesMock,
} from '../mocks/catalogs.mock';
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

export interface ComprasCatalogos {
  anios: SelectOption[];
  meses: SelectOption[];
  proveedores: SelectOption[];
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
): Promise<ComprasCatalogos> {
  const [
    periodos,
    proveedoresResponse,
    insumosResponse,
  ] = await Promise.all([
    fetchJson<PeriodosApiResponse>(
      `/bi/catalogos/periodos?dominio=compras${
        filters.anio
          ? `&anio=${filters.anio}`
          : ''
      }`,
    ),
    fetchJson<ItemsResponse>(
      '/bi/catalogos/proveedores-compras',
    ),
    fetchJson<ItemsResponse>(
      '/bi/catalogos/insumos-compras',
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
    proveedores:
      proveedoresResponse.items,
    insumos:
      insumosResponse.items,
    ultimoPeriodoDisponible:
      periodos.ultimoPeriodoDisponible,
    fechaMaximaDisponible:
      periodos.fechaMaximaDisponible,
  };
}

function getMockCatalogos():
  ComprasCatalogos {
  return {
    anios: aniosMock,
    meses: mesesMock,
    proveedores:
      proveedoresComprasMock.map(
        (proveedor) => ({
          id: proveedor.proveedorId,
          label: proveedor.nombre,
        }),
      ),
    insumos:
      insumosComprasMock.map(
        (insumo) => ({
          id: insumo.insumoId,
          label: insumo.nombre,
        }),
      ),
    ultimoPeriodoDisponible: null,
    fechaMaximaDisponible: null,
  };
}

export async function getComprasCatalogos(
  filters: BiFilters,
): Promise<ComprasCatalogos> {
  if (runtimeConfig.dataMode === 'api') {
    return getApiCatalogos(filters);
  }

  return getMockCatalogos();
}
