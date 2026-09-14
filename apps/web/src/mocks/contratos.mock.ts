import { rrhhMockEmpleados } from './rrhh.mock';

export type ContratoMockTipo =
  | 'INDEFINIDO'
  | 'PLAZO_FIJO'
  | 'TEMPORAL';

export interface ContratoMockRecord {
  contratoId: number;
  empleadoId: number;
  empleado: string;

  areaId: number;
  area: string;

  tipoContrato: ContratoMockTipo;

  fechaInicio: string;
  fechaTermino?: string;
  fechaSalida?: string;
}

function addMonths(
  isoDate: string,
  months: number,
) {
  const date = new Date(`${isoDate}T00:00:00`);

  date.setMonth(date.getMonth() + months);

  return date.toISOString().slice(0, 10);
}

function resolveType(
  empleadoId: number,
  fechaTerminoContrato?: string,
): ContratoMockTipo {
  if (fechaTerminoContrato) {
    return 'PLAZO_FIJO';
  }

  if (empleadoId % 9 === 0) {
    return 'TEMPORAL';
  }

  return 'INDEFINIDO';
}

function resolveEndDate(
  empleadoId: number,
  fechaIngreso: string,
  fechaTerminoContrato?: string,
) {
  if (fechaTerminoContrato) {
    return fechaTerminoContrato;
  }

  const temporalExpirations: Record<number, string> = {
    9: '2026-10-10',
    18: '2026-10-25',
    27: '2026-11-10',
    36: '2026-11-25',
    45: '2026-12-10',
    54: '2026-12-20',
    72: '2027-01-15',
  };

  if (empleadoId % 9 === 0) {
    return (
      temporalExpirations[empleadoId] ??
      addMonths(fechaIngreso, 9)
    );
  }

  return undefined;
}

export const contratosMockRecords: ContratoMockRecord[] =
  rrhhMockEmpleados.map((employee) => ({
    contratoId: employee.empleadoId,
    empleadoId: employee.empleadoId,
    empleado: employee.nombre,

    areaId: employee.areaId,
    area: employee.area,

    tipoContrato: resolveType(
      employee.empleadoId,
      employee.fechaTerminoContrato,
    ),

    fechaInicio: employee.fechaIngreso,

    fechaTermino: resolveEndDate(
      employee.empleadoId,
      employee.fechaIngreso,
      employee.fechaTerminoContrato,
    ),

    fechaSalida: employee.fechaSalida,
  }));