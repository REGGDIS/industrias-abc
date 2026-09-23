export interface DashboardKpis {
  totalTrabajadores: number;
  empleadosConAsistencia: number;

  horasExtrasAsistencia: number;
  minutosAtraso: number;
  diasAusentes: number;

  costoRemuneraciones: number;
  sueldoLiquido: number;

  totalCompras: number;
  ordenesCompra: number;
  ordenesCompraEfectivas: number;

  movimientosContables: number;
  totalDebeContabilidad: number;
  totalHaberContabilidad: number;
  saldoContabilidad: number;

  produccionPlanificada: number;
  produccionReal: number;
  produccionRechazada: number;
  cumplimientoProduccion: number;
  tasaRechazoProduccion: number;
  ordenesProduccion: number;
}

export interface DashboardPeriodoMes {
  anio: number;
  mes: number;
}

export interface DashboardCentroCosto {
  label: string;
  value: number;
}

export interface DashboardEvolucionMensual {
  anio: number;
  mes: number;
  label: string;
  value: number;
}

export interface DashboardPeriodos {
  rrhh: string | null;
  asistencia: string | null;
  remuneraciones: string | null;
  compras: DashboardPeriodoMes | null;
  contabilidad: DashboardPeriodoMes | null;
  produccion: DashboardPeriodoMes | null;
}

export interface DashboardCobertura {
  dominio: string;
  fechaDesde: string | null;
  fechaHasta: string | null;
  registros: number;
}

export interface DashboardResumen {
  kpis: DashboardKpis;
  periodos: DashboardPeriodos;

  principalesCentrosCosto:
    DashboardCentroCosto[];

  periodoCentrosCosto:
    number | null;

  evolucionMensual:
    DashboardEvolucionMensual[];

  cobertura: DashboardCobertura[];
  advertencias: string[];
}
