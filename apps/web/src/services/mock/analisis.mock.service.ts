import {
  areasMock,
  centrosCostoMock,
} from '../../mocks/catalogs.mock';
import type {
  CostoArea,
  CostoCentroCosto,
  HorasExtraDiferencia,
  HorasExtraProduccion,
} from '../../types/analisis';
import type { BiFilters } from '../../types/filters';
import type { AnalisisService } from '../contracts/analisis.service';

import { asistenciaMockService } from './asistencia.mock.service';
import { comprasMockService } from './compras.mock.service';
import { contabilidadMockService } from './contabilidad.mock.service';
import { produccionMockService } from './produccion.mock.service';
import { remuneracionesMockService } from './remuneraciones.mock.service';

const AREA_PRODUCCION_ID = 4;

function findCategoryValue(
  values: {
    label: string;
    value: number;
  }[],
  label: string,
) {
  return (
    values.find(
      (item) => item.label === label,
    )?.value ?? 0
  );
}

function getCentroCostoIdForArea(
  areaId: number,
) {
  return areaId;
}

function getAreaIdForCentroCosto(
  centroCostoId: number,
) {
  return centroCostoId;
}

function getAreaLabel(
  areaId: number,
) {
  return (
    areasMock.find(
      (area) =>
        Number(area.id) === areaId,
    )?.label ?? `Área ${areaId}`
  );
}

function getCentroCostoLabel(
  centroCostoId: number,
) {
  return (
    centrosCostoMock.find(
      (centro) =>
        Number(centro.id) ===
        centroCostoId,
    )?.label ??
    `Centro ${centroCostoId}`
  );
}

function areasForFilters(
  filters: BiFilters,
) {
  if (filters.areaId) {
    return [filters.areaId];
  }

  if (filters.centroCostoId) {
    return [
      getAreaIdForCentroCosto(
        filters.centroCostoId,
      ),
    ];
  }

  return areasMock.map((area) =>
    Number(area.id),
  );
}

function centrosForFilters(
  filters: BiFilters,
) {
  if (filters.centroCostoId) {
    return [filters.centroCostoId];
  }

  if (filters.areaId) {
    return [
      getCentroCostoIdForArea(
        filters.areaId,
      ),
    ];
  }

  return centrosCostoMock.map(
    (centro) => Number(centro.id),
  );
}

export class AnalisisMockService
  implements AnalisisService
{
  async getCostoPorArea(
    filters: BiFilters = {},
  ): Promise<CostoArea[]> {
    const result: CostoArea[] = [];

    for (const areaId of areasForFilters(
      filters,
    )) {
      const area =
        getAreaLabel(areaId);

      const centroCostoId =
        getCentroCostoIdForArea(
          areaId,
        );

      const [
        remuneraciones,
        compras,
        contabilidad,
      ] = await Promise.all([
        remuneracionesMockService.getResumen({
          anio: filters.anio,
          mes: filters.mes,
          areaId,
        }),

        comprasMockService.getResumen({
          anio: filters.anio,
          mes: filters.mes,
          centroCostoId,
        }),

        contabilidadMockService.getResumen({
          anio: filters.anio,
          mes: filters.mes,
          areaId,
          centroCostoId,
        }),
      ]);

      const costoRemuneraciones =
        remuneraciones.kpis.costoEmpresa;

      const costoCompras =
        compras.kpis.totalComprado;

      const gastosContables =
        contabilidad.kpis.gastosTotales;

      result.push({
        areaId,
        area,
        remuneraciones:
          costoRemuneraciones,
        compras: costoCompras,
        gastosContables,
        costoTotal:
          costoRemuneraciones +
          costoCompras +
          gastosContables,
      });
    }

    return result.sort(
      (a, b) =>
        b.costoTotal - a.costoTotal,
    );
  }

  async getHorasExtraProduccion(
    filters: BiFilters = {},
  ): Promise<
    HorasExtraProduccion[]
  > {
    if (
      filters.areaId &&
      filters.areaId !==
        AREA_PRODUCCION_ID
    ) {
      return [];
    }

    if (
      filters.centroCostoId &&
      filters.centroCostoId !==
        AREA_PRODUCCION_ID
    ) {
      return [];
    }

    const [
      asistencia,
      produccion,
    ] = await Promise.all([
      asistenciaMockService.getResumen({
        anio: filters.anio,
        mes: filters.mes,
        areaId: AREA_PRODUCCION_ID,
      }),

      produccionMockService.getResumen({
        anio: filters.anio,
        mes: filters.mes,
      }),
    ]);

    return [
      {
        areaId:
          AREA_PRODUCCION_ID,

        area: getAreaLabel(
          AREA_PRODUCCION_ID,
        ),

        horasExtras:
          asistencia.kpis.horasExtras,

        produccion:
          produccion.kpis.produccionReal,
      },
    ];
  }

  async getHorasExtraDiferencias(
    filters: BiFilters = {},
  ): Promise<
    HorasExtraDiferencia[]
  > {
    const result: HorasExtraDiferencia[] =
      [];

    for (const areaId of areasForFilters(
      filters,
    )) {
      const area =
        getAreaLabel(areaId);

      const [
        asistencia,
        remuneraciones,
      ] = await Promise.all([
        asistenciaMockService.getResumen({
          anio: filters.anio,
          mes: filters.mes,
          areaId,
        }),

        remuneracionesMockService.getResumen({
          anio: filters.anio,
          mes: filters.mes,
          areaId,
        }),
      ]);

      const horasRegistradas =
        asistencia.kpis.horasExtras;

      const horasPagadas =
        findCategoryValue(
          remuneraciones.horasExtrasPorArea,
          area,
        );

      result.push({
        areaId,
        area,
        horasRegistradas,
        horasPagadas,
        diferencia:
          Math.round(
            (horasRegistradas -
              horasPagadas) *
              10,
          ) / 10,
      });
    }

    return result;
  }

  async getCostoCentroCosto(
    filters: BiFilters = {},
  ): Promise<CostoCentroCosto[]> {
    const result: CostoCentroCosto[] =
      [];

    for (const centroCostoId of centrosForFilters(
      filters,
    )) {
      const centroCosto =
        getCentroCostoLabel(
          centroCostoId,
        );

      const areaId =
        getAreaIdForCentroCosto(
          centroCostoId,
        );

      const [
        remuneraciones,
        compras,
        contabilidad,
      ] = await Promise.all([
        remuneracionesMockService.getResumen({
          anio: filters.anio,
          mes: filters.mes,
          areaId,
        }),

        comprasMockService.getResumen({
          anio: filters.anio,
          mes: filters.mes,
          centroCostoId,
        }),

        contabilidadMockService.getResumen({
          anio: filters.anio,
          mes: filters.mes,
          centroCostoId,
          areaId,
        }),
      ]);

      const costoRemuneraciones =
        remuneraciones.kpis.costoEmpresa;

      const costoCompras =
        compras.kpis.totalComprado;

      const gastosContables =
        contabilidad.kpis.gastosTotales;

      result.push({
        centroCostoId,
        centroCosto,
        remuneraciones:
          costoRemuneraciones,
        compras: costoCompras,
        gastosContables,
        costoTotal:
          costoRemuneraciones +
          costoCompras +
          gastosContables,
      });
    }

    return result.sort(
      (a, b) =>
        b.costoTotal - a.costoTotal,
    );
  }
}

export const analisisMockService =
  new AnalisisMockService();
