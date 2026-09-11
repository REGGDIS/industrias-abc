export interface CostoArea {
  areaId: number;
  area: string;
  remuneraciones: number;
  compras: number;
  gastosContables: number;
  costoTotal: number;
}

export interface HorasExtraProduccion {
  areaId: number;
  area: string;
  horasExtras: number;
  produccion: number;
}

export interface HorasExtraDiferencia {
  areaId: number;
  area: string;
  horasRegistradas: number;
  horasPagadas: number;
  diferencia: number;
}

export interface CostoCentroCosto {
  centroCostoId: number;
  centroCosto: string;
  remuneraciones: number;
  compras: number;
  gastosContables: number;
  costoTotal: number;
}
