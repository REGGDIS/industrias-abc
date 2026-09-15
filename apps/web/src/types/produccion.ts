import type {
  CategoryValue,
  PaginatedResponse,
} from './common';

export interface ProduccionKpis {
  cantidadPlanificada: number;
  cantidadProducida: number;
  cumplimientoProduccion: number;
  cantidadRechazada: number;
  tasaRechazo: number;
  totalOrdenes: number;
  productosActivos: number;
}

export interface ProduccionEvolucion {
  anio: number;
  mes: number;
  label: string;
  planificada: number;
  producida: number;
  rechazada: number;
}

export interface ProduccionConsumoInsumo {
  label: string;
  planificado: number;
  consumido: number;
  desviacion: number;
}

export interface ProduccionDetalle {
  produccionId: number;
  numeroOrden: string;
  fechaInicio: string;
  fechaTermino: string | null;
  productoCodigo: string;
  producto: string;
  categoria: string;
  unidadMedida: string;
  cantidadPlanificada: number;
  cantidadProducida: number;
  cantidadRechazada: number;
  estado: string;
}

export interface ProduccionResumen {
  periodo: {
    anio: number;
    mes: number;
  };
  filtrosAplicados: {
    productoId: number | null;
    insumoRef: string | null;
  };
  kpis: ProduccionKpis;
  evolucionMensual: ProduccionEvolucion[];
  rechazoPorProducto: CategoryValue[];
  ordenesPorEstado: CategoryValue[];
  consumoPorInsumo: ProduccionConsumoInsumo[];
}

export type ProduccionDetalleResponse =
  PaginatedResponse<ProduccionDetalle>;
