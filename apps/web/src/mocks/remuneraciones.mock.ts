import { asistenciaMockRecords } from './asistencia.mock';
import { rrhhMockEmpleados } from './rrhh.mock';

export interface RemuneracionMockRecord {
  empleadoId: number;
  empleado: string;

  areaId: number;
  area: string;

  cargoId: number;
  cargo: string;

  anio: number;
  mes: number;

  sueldoBase: number;

  horasExtrasCantidad: number;
  costoHorasExtras: number;

  bonos: number;
  descuentos: number;

  totalHaberes: number;
  liquidoEstimado: number;
  costoEmpresa: number;
}

const sueldoBasePorCargo: Record<number, number> = {
  1: 1050000,
  2: 850000,
  3: 1100000,
  4: 1050000,
  5: 1150000,
  6: 1350000,
  7: 780000,
  8: 1150000,
  9: 900000,
  10: 1650000,
};

function roundAmount(value: number) {
  return Math.round(value);
}

function buildRemuneraciones() {
  const records: RemuneracionMockRecord[] = [];

  const periods = [
    ...Array.from(
      { length: 12 },
      (_, index) => ({
        anio: 2025,
        mes: index + 1,
      }),
    ),
    ...Array.from(
      { length: 9 },
      (_, index) => ({
        anio: 2026,
        mes: index + 1,
      }),
    ),
  ];

  for (const period of periods) {
    for (const employee of rrhhMockEmpleados) {
      const attendance =
        asistenciaMockRecords.filter(
          (record) =>
            record.empleadoId ===
              employee.empleadoId &&
            record.anio === period.anio &&
            record.mes === period.mes,
        );

      if (attendance.length === 0) {
        continue;
      }

      const horasExtrasCantidad =
        attendance.reduce(
          (total, record) =>
            total + record.horasExtras,
          0,
        );

      const sueldoBase =
        sueldoBasePorCargo[
          employee.cargoId
        ] ?? 900000;

      const valorHora =
        sueldoBase / 180;

      const costoHorasExtras =
        roundAmount(
          horasExtrasCantidad *
            valorHora *
            1.5,
        );

      const seed =
        employee.empleadoId * 19 +
        period.mes * 11 +
        period.anio;

      const bonoRate =
        seed % 5 === 0
          ? 0.08
          : seed % 3 === 0
            ? 0.05
            : 0.03;

      const bonos =
        roundAmount(
          sueldoBase * bonoRate,
        );

      const totalHaberes =
        sueldoBase +
        costoHorasExtras +
        bonos;

      const descuentoRate =
        0.17 +
        (seed % 4) * 0.005;

      const descuentos =
        roundAmount(
          totalHaberes *
            descuentoRate,
        );

      const liquidoEstimado =
        totalHaberes - descuentos;

      const costoEmpresa =
        roundAmount(
          totalHaberes * 1.075,
        );

      records.push({
        empleadoId:
          employee.empleadoId,
        empleado: employee.nombre,

        areaId: employee.areaId,
        area: employee.area,

        cargoId: employee.cargoId,
        cargo: employee.cargo,

        anio: period.anio,
        mes: period.mes,

        sueldoBase,

        horasExtrasCantidad,
        costoHorasExtras,

        bonos,
        descuentos,

        totalHaberes,
        liquidoEstimado,
        costoEmpresa,
      });
    }
  }

  return records;
}

export const remuneracionesMockRecords =
  buildRemuneraciones();
