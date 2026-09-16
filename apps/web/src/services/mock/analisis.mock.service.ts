import type {
  AnalisisResumen,
} from '../../types/analisis';
import type {
  AnalisisService,
} from '../contracts/analisis.service';

const mockResumen: AnalisisResumen = {
  kpis: {
    costoEmpresaJulio2026: 31500000,
    horasExtraAsistencia: 8.5,
    horasExtraRemuneradas: 42,
    comprasEneroMayo2025: 8400000,
    produccionPlanificadaAgosto2026: 7500,
    produccionRealAgosto2026: 6900,
    cumplimientoProduccion: 92,
    desviacionConsumo: -320,
  },
  laboral: [
    {
      areaId: 1,
      area: 'ADMINISTRACIÓN',
      empleadosRemunerados: 6,
      horasExtraAsistencia: 4,
      horasExtraRemuneradas: 18,
      costoEmpresa: 12000000,
      asistenciaDesde: '2026-07-27',
      asistenciaHasta: '2026-07-29',
    },
    {
      areaId: 2,
      area: 'RECURSOS HUMANOS',
      empleadosRemunerados: 5,
      horasExtraAsistencia: 4.5,
      horasExtraRemuneradas: 12,
      costoEmpresa: 8500000,
      asistenciaDesde: '2026-07-27',
      asistenciaHasta: '2026-07-29',
    },
    {
      areaId: 3,
      area: 'FINANZAS Y CONTABILIDAD',
      empleadosRemunerados: 6,
      horasExtraAsistencia: 0,
      horasExtraRemuneradas: 12,
      costoEmpresa: 11000000,
      asistenciaDesde: null,
      asistenciaHasta: null,
    },
  ],
  comprasContabilidad: [
    {
      anio: 2025,
      mes: 1,
      ordenesCompra: 1,
      totalCompras: 1700000,
      movimientosContables: 2,
      totalDebe: 3100000,
      totalHaber: 3100000,
    },
    {
      anio: 2025,
      mes: 2,
      ordenesCompra: 1,
      totalCompras: 1200000,
      movimientosContables: 2,
      totalDebe: 4600000,
      totalHaber: 4600000,
    },
    {
      anio: 2025,
      mes: 3,
      ordenesCompra: 1,
      totalCompras: 2300000,
      movimientosContables: 2,
      totalDebe: 2600000,
      totalHaber: 2600000,
    },
    {
      anio: 2025,
      mes: 4,
      ordenesCompra: 1,
      totalCompras: 1500000,
      movimientosContables: 2,
      totalDebe: 1800000,
      totalHaber: 1800000,
    },
    {
      anio: 2025,
      mes: 5,
      ordenesCompra: 1,
      totalCompras: 1700000,
      movimientosContables: 2,
      totalDebe: 3500000,
      totalHaber: 3500000,
    },
  ],
  produccionConsumo: [
    {
      numeroOrden: 'OP-MOCK-001',
      codigoProducto: 'PROD-001',
      producto: 'Producto A',
      fechaInicio: '2026-08-01',
      produccionPlanificada: 1000,
      produccionReal: 920,
      produccionRechazada: 20,
      lineasConsumo: 2,
      consumoPlanificado: 800,
      consumoReal: 760,
      desviacionConsumo: -40,
    },
    {
      numeroOrden: 'OP-MOCK-002',
      codigoProducto: 'PROD-002',
      producto: 'Producto B',
      fechaInicio: '2026-08-05',
      produccionPlanificada: 1500,
      produccionReal: 1400,
      produccionRechazada: 25,
      lineasConsumo: 3,
      consumoPlanificado: 1100,
      consumoReal: 1050,
      desviacionConsumo: -50,
    },
  ],
  calidadCruceProduccion: {
    consumosHuerfanos: 0,
    cruceValido: true,
  },
  periodos: {
    laboral: {
      anio: 2026,
      mes: 7,
      asistenciaDesde: '2026-07-27',
      asistenciaHasta: '2026-07-29',
    },
    comprasContabilidad: {
      anio: 2025,
      mesDesde: 1,
      mesHasta: 5,
    },
    produccionConsumo: {
      anio: 2026,
      mes: 8,
    },
  },
  advertencias: [
    'Modo mock: datos sintéticos para validar la interfaz.',
  ],
};

export class AnalisisMockService
  implements AnalisisService
{
  async getResumen(): Promise<AnalisisResumen> {
    return mockResumen;
  }
}

export const analisisMockService =
  new AnalisisMockService();
