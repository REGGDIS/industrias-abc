import type { CategoryValue, MonthlyValue, PaginatedResponse } from './common';

export interface ComprasKpis {
  totalComprado: number;
  totalOrdenes: number;
  compraPromedio: number;
  proveedoresActivos: number;
  cumplimientoProveedores: number;
  insumosAdquiridos: number;
}

export interface CompraDetalle {
  ordenCompraId: number;
  fecha: string;
  proveedor: string;
  insumo: string;
  centroCosto: string;
  cantidad: number;
  total: number;
}

export interface ComprasResumen {
  kpis: ComprasKpis;
  evolucionMensual: MonthlyValue[];
  topProveedores: CategoryValue[];
  topInsumos: CategoryValue[];
  comprasPorCentroCosto: CategoryValue[];
}

export type ComprasDetalleResponse =
  PaginatedResponse<CompraDetalle>;
