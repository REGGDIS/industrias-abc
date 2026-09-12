import {
  rrhhMockEmpleados,
  type RrhhMockEmpleado,
} from './rrhh.mock';

export type AsistenciaMockEstado =
  | 'PRESENTE'
  | 'ATRASO'
  | 'AUSENTE';

export interface AsistenciaMockRecord {
  empleadoId: number;
  empleado: string;

  areaId: number;
  area: string;

  fecha: string;
  anio: number;
  mes: number;

  horasNormales: number;
  horasExtras: number;
  horasTrabajadas: number;

  minutosAtraso: number;
  estado: AsistenciaMockEstado;
}

function parseDate(value: string) {
  return new Date(`${value}T00:00:00`);
}

function formatDate(
  anio: number,
  mes: number,
  dia: number,
) {
  return `${anio}-${String(mes).padStart(2, '0')}-${String(
    dia,
  ).padStart(2, '0')}`;
}

function isWorkday(date: Date) {
  const day = date.getDay();

  return day !== 0 && day !== 6;
}

function employeeExistsOnDate(
  employee: RrhhMockEmpleado,
  date: Date,
) {
  const ingreso = parseDate(employee.fechaIngreso);

  if (ingreso > date) {
    return false;
  }

  if (
    employee.fechaSalida &&
    parseDate(employee.fechaSalida) <= date
  ) {
    return false;
  }

  return true;
}

function createAttendanceRecord(
  employee: RrhhMockEmpleado,
  anio: number,
  mes: number,
  dia: number,
): AsistenciaMockRecord {
  const seed =
    employee.empleadoId * 17 +
    mes * 13 +
    dia * 7;

  const isAbsent = seed % 37 === 0;
  const isLate = !isAbsent && seed % 9 === 0;

  const horasExtras =
    isAbsent
      ? 0
      : seed % 11 === 0
        ? 1.5
        : seed % 7 === 0
          ? 1
          : seed % 5 === 0
            ? 0.5
            : 0;

  const minutosAtraso =
    isLate
      ? 5 + (seed % 26)
      : 0;

  const horasNormales = isAbsent ? 0 : 8;

  return {
    empleadoId: employee.empleadoId,
    empleado: employee.nombre,

    areaId: employee.areaId,
    area: employee.area,

    fecha: formatDate(anio, mes, dia),
    anio,
    mes,

    horasNormales,
    horasExtras,
    horasTrabajadas:
      horasNormales + horasExtras,

    minutosAtraso,

    estado: isAbsent
      ? 'AUSENTE'
      : isLate
        ? 'ATRASO'
        : 'PRESENTE',
  };
}

function buildMonth(
  anio: number,
  mes: number,
): AsistenciaMockRecord[] {
  const records: AsistenciaMockRecord[] = [];

  const monthLastDay = new Date(
    anio,
    mes,
    0,
  ).getDate();

  const mockCurrentYear = 2026;
  const mockCurrentMonth = 9;
  const mockCurrentDay = 12;

  const daysInMonth =
    anio === mockCurrentYear &&
    mes === mockCurrentMonth
      ? Math.min(monthLastDay, mockCurrentDay)
      : monthLastDay;

  for (let dia = 1; dia <= daysInMonth; dia += 1) {
    const date = new Date(anio, mes - 1, dia);

    if (!isWorkday(date)) {
      continue;
    }

    for (const employee of rrhhMockEmpleados) {
      if (!employeeExistsOnDate(employee, date)) {
        continue;
      }

      records.push(
        createAttendanceRecord(
          employee,
          anio,
          mes,
          dia,
        ),
      );
    }
  }

  return records;
}

function buildYear(
  anio: number,
  ultimoMes: number,
) {
  const records: AsistenciaMockRecord[] = [];

  for (
    let mes = 1;
    mes <= ultimoMes;
    mes += 1
  ) {
    records.push(...buildMonth(anio, mes));
  }

  return records;
}

export const asistenciaMockRecords: AsistenciaMockRecord[] = [
  ...buildYear(2025, 12),
  ...buildYear(2026, 9),
];
