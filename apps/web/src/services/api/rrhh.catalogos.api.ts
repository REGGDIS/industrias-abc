import { runtimeConfig } from '../../config/runtime';
import type { SelectOption } from '../../types/common';

interface ApiCatalogItem {
  id: number;
  codigo?: string;
  label: string;
}

type ApiCatalogResponse =
  | ApiCatalogItem[]
  | {
      items: ApiCatalogItem[];
    };

interface ApiPeriodoResponse {
  anios: number[];
  meses: {
    id: number;
    label: string;
  }[];
  ultimoPeriodoDisponible: {
    anio: number;
    mes: number;
  };
  fechaMaximaDisponible: string;
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

function normalizeCatalog(
  response: ApiCatalogResponse,
): ApiCatalogItem[] {
  return Array.isArray(response)
    ? response
    : response.items;
}

export async function getRrhhCatalogos() {
  const [
    areasResponse,
    cargosResponse,
    periodosResponse,
  ] = await Promise.all([
    fetchJson<ApiCatalogResponse>(
      '/bi/catalogos/areas',
    ),
    fetchJson<ApiCatalogResponse>(
      '/bi/catalogos/cargos',
    ),
    fetchJson<ApiPeriodoResponse>(
      '/bi/catalogos/periodos?dominio=rrhh',
    ),
  ]);

  const areasRaw =
    normalizeCatalog(areasResponse);

  const cargosRaw =
    normalizeCatalog(cargosResponse);

  const anios: SelectOption[] =
    periodosResponse.anios.map((anio) => ({
      id: anio,
      label: String(anio),
    }));

  const meses: SelectOption[] =
    periodosResponse.meses.map((mes) => ({
      id: mes.id,
      label: mes.label,
    }));

  const areas: SelectOption[] =
    areasRaw.map((area) => ({
      id: area.id,
      label: area.label,
    }));

  const cargos: SelectOption[] =
    cargosRaw.map((cargo) => ({
      id: cargo.id,
      label: cargo.label,
    }));

  return {
    anios,
    meses,
    areas,
    cargos,
    ultimoPeriodoDisponible:
      periodosResponse.ultimoPeriodoDisponible,
    fechaMaximaDisponible:
      periodosResponse.fechaMaximaDisponible,
  };
}
