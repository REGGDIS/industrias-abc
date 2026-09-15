export interface AnalisisKpis {
  costoEmpresaJulio2026: number;
  horasExtraAsistencia: number;
  horasExtraRemuneradas: number;
  comprasEneroMayo2025: number;
  produccionPlanificadaAgosto2026: number;
  produccionRealAgosto2026: number;
  cumplimientoProduccion: number;
  desviacionConsumo: number;
}

export interface AnalisisLaboral {
  areaId: number;
  area: string;
  empleadosRemunerados: number;
  horasExtraAsistencia: number;
  horasExtraRemuneradas: number;
  costoEmpresa: number;
  asistenciaDesde: string | null;
  asistenciaHasta: string | null;
}

export interface AnalisisComprasContabilidad {
  anio: number;
  mes: number;
  ordenesCompra: number;
  totalCompras: number;
  movimientosContables: number;
  totalDebe: number;
  totalHaber: number;
}

export interface AnalisisProduccionConsumo {
  numeroOrden: string;
  codigoProducto: string;
  producto: string;
  fechaInicio: string;
  produccionPlanificada: number;
  produccionReal: number;
  produccionRechazada: number;
  lineasConsumo: number;
  consumoPlanificado: number;
  consumoReal: number;
  desviacionConsumo: number;
}

export interface AnalisisCalidadCruce {
  consumosHuerfanos: number;
  cruceValido: boolean;
}

export interface AnalisisPeriodos {
  laboral: {
    anio: number;
    mes: number;
    asistenciaDesde: string;
    asistenciaHasta: string;
  };
  comprasContabilidad: {
    anio: number;
    mesDesde: number;
    mesHasta: number;
  };
  produccionConsumo: {
    anio: number;
    mes: number;
  };
}

export interface AnalisisResumen {
  kpis: AnalisisKpis;
  laboral: AnalisisLaboral[];
  comprasContabilidad: AnalisisComprasContabilidad[];
  produccionConsumo: AnalisisProduccionConsumo[];
  calidadCruceProduccion: AnalisisCalidadCruce;
  periodos: AnalisisPeriodos;
  advertencias: string[];
}
