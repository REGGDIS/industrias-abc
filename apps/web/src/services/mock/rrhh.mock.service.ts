import {
  rrhhMockEmpleados,
  type RrhhMockEmpleado,
} from '../../mocks/rrhh.mock';
import type { BiFilters } from '../../types/filters';
import type {
  RrhhResumen,
  TrabajadorDetalle,
  TrabajadoresResponse,
} from '../../types/rrhh';
import type { RrhhService } from '../contracts/rrhh.service';

function resolvePeriod(filters: BiFilters) {
  const anio = filters.anio ?? 2026;

  const mes =
    filters.mes ??
    (anio === 2026 ? 9 : 12);

  return { anio, mes };
}

function periodEnd(anio: number, mes: number) {
  return new Date(anio, mes, 0, 23, 59, 59);
}

function parseDate(value: string) {
  return new Date(`${value}T00:00:00`);
}

function isEmployeeInPeriod(
  employee: RrhhMockEmpleado,
  end: Date,
) {
  const ingreso = parseDate(employee.fechaIngreso);

  if (ingreso > end) {
    return false;
  }

  if (
    employee.fechaSalida &&
    parseDate(employee.fechaSalida) <= end
  ) {
    return false;
  }

  return true;
}

function filterByDimensions(
  employees: RrhhMockEmpleado[],
  filters: BiFilters,
) {
  return employees.filter((employee) => {
    if (
      filters.areaId &&
      employee.areaId !== filters.areaId
    ) {
      return false;
    }

    if (
      filters.cargoId &&
      employee.cargoId !== filters.cargoId
    ) {
      return false;
    }

    if (
      filters.empleadoId &&
      employee.empleadoId !== filters.empleadoId
    ) {
      return false;
    }

    return true;
  });
}

function absenceDays(
  employeeId: number,
  mes: number,
) {
  const value = (employeeId + mes * 2) % 11;

  if (value < 6) {
    return 0;
  }

  if (value < 9) {
    return 1;
  }

  return 2;
}

function buildSnapshot(
  filters: BiFilters,
  anio: number,
  mes: number,
) {
  const end = periodEnd(anio, mes);

  return filterByDimensions(
    rrhhMockEmpleados.filter((employee) =>
      isEmployeeInPeriod(employee, end),
    ),
    filters,
  );
}

function percentage(
  numerator: number,
  denominator: number,
) {
  if (denominator === 0) {
    return 0;
  }

  return (numerator / denominator) * 100;
}

export class RrhhMockService implements RrhhService {
  async getResumen(
    filters: BiFilters = {},
  ): Promise<RrhhResumen> {
    const { anio, mes } = resolvePeriod(filters);

    const snapshot = buildSnapshot(
      filters,
      anio,
      mes,
    );

    const activos = snapshot.filter(
      (employee) => employee.estado === 'ACTIVO',
    );

    const inactivos = snapshot.filter(
      (employee) => employee.estado === 'INACTIVO',
    );

    const salidasMes = filterByDimensions(
      rrhhMockEmpleados,
      filters,
    ).filter((employee) => {
      if (!employee.fechaSalida) {
        return false;
      }

      const salida = parseDate(employee.fechaSalida);

      return (
        salida.getFullYear() === anio &&
        salida.getMonth() + 1 === mes
      );
    }).length;

    const totalAusencias = activos.reduce(
      (total, employee) =>
        total + absenceDays(employee.empleadoId, mes),
      0,
    );

    const end = periodEnd(anio, mes);
    const expiryLimit = new Date(end);
    expiryLimit.setDate(expiryLimit.getDate() + 90);

    const contratosProximosVencer =
      activos.filter((employee) => {
        if (!employee.fechaTerminoContrato) {
          return false;
        }

        const expiry = parseDate(
          employee.fechaTerminoContrato,
        );

        return expiry > end && expiry <= expiryLimit;
      }).length;

    const areas = new Map<string, number>();
    const cargos = new Map<string, number>();

    for (const employee of snapshot) {
      areas.set(
        employee.area,
        (areas.get(employee.area) ?? 0) + 1,
      );

      cargos.set(
        employee.cargo,
        (cargos.get(employee.cargo) ?? 0) + 1,
      );
    }

    const ultimoMes =
      anio === 2026 ? 9 : 12;

    const evolucionDotacion = Array.from(
      { length: ultimoMes },
      (_, index) => {
        const currentMonth = index + 1;

        const currentSnapshot = buildSnapshot(
          {
            ...filters,
            mes: currentMonth,
          },
          anio,
          currentMonth,
        );

        return {
          anio,
          mes: currentMonth,
          label: new Intl.DateTimeFormat('es-CL', {
            month: 'short',
          }).format(
            new Date(anio, currentMonth - 1, 1),
          ),
          value: currentSnapshot.length,
        };
      },
    );

    return {
      kpis: {
        totalTrabajadores: snapshot.length,
        trabajadoresActivos: activos.length,
        trabajadoresInactivos: inactivos.length,

        rotacion: percentage(
          salidasMes,
          Math.max(snapshot.length, 1),
        ),

        ausentismo: percentage(
          totalAusencias,
          activos.length * 22,
        ),

        contratosProximosVencer,
      },

      trabajadoresPorArea: Array.from(
        areas.entries(),
      )
        .map(([label, value]) => ({
          label,
          value,
        }))
        .sort((a, b) => b.value - a.value),

      trabajadoresPorCargo: Array.from(
        cargos.entries(),
      )
        .map(([label, value]) => ({
          label,
          value,
        }))
        .sort((a, b) => b.value - a.value),

      evolucionDotacion,
    };
  }

  async getTrabajadores(
    filters: BiFilters = {},
  ): Promise<TrabajadoresResponse> {
    const { anio, mes } = resolvePeriod(filters);

    const snapshot = buildSnapshot(
      filters,
      anio,
      mes,
    );

    const items: TrabajadorDetalle[] = snapshot
      .sort((a, b) => a.empleadoId - b.empleadoId)
      .slice(0, 20)
      .map((employee) => ({
        empleadoId: employee.empleadoId,
        nombre: employee.nombre,
        rut: employee.rut,
        area: employee.area,
        cargo: employee.cargo,
        fechaIngreso: employee.fechaIngreso,
        estado: employee.estado,
      }));

    return {
      items,
      pagination: {
        page: 1,
        pageSize: 20,
        total: snapshot.length,
      },
    };
  }
}

export const rrhhMockService =
  new RrhhMockService();
