import { runtimeConfig } from '../config/runtime';
import {
  aniosMock,
  centrosCostoMock,
  mesesMock,
} from '../mocks/catalogs.mock';
import { cuentasGastoMock } from '../mocks/contabilidad.mock';
import type { SelectOption } from '../types/common';

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

export interface ContabilidadCatalogos {
  anios: SelectOption[];
  meses: SelectOption[];
  centrosCosto: SelectOption[];
  cuentasContables: SelectOption[];
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

async function getApiCatalogos():
  Promise<ContabilidadCatalogos> {
  const [
    periodos,
    centrosResponse,
    cuentasResponse,
  ] = await Promise.all([
    fetchJson<PeriodosApiResponse>(
      '/bi/catalogos/periodos?dominio=contabilidad',
    ),
    fetchJson<ItemsResponse>(
      '/bi/catalogos/centros-costo',
    ),
    fetchJson<ItemsResponse>(
      '/bi/catalogos/cuentas-contables',
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
    centrosCosto: centrosResponse.items,
    cuentasContables: cuentasResponse.items,
    ultimoPeriodoDisponible:
      periodos.ultimoPeriodoDisponible,
    fechaMaximaDisponible:
      periodos.fechaMaximaDisponible,
  };
}

function getMockCatalogos():
  ContabilidadCatalogos {
  return {
    anios: aniosMock,
    meses: mesesMock,
    centrosCosto: centrosCostoMock,
    cuentasContables: cuentasGastoMock.map(
      (cuenta) => ({
        id: cuenta.cuentaContableId,
        label:
          `${cuenta.codigo} - ${cuenta.nombre}`,
      }),
    ),
    ultimoPeriodoDisponible: null,
    fechaMaximaDisponible: null,
  };
}

export async function getContabilidadCatalogos():
  Promise<ContabilidadCatalogos> {
  if (runtimeConfig.dataMode === 'api') {
    return getApiCatalogos();
  }

  return getMockCatalogos();
}
