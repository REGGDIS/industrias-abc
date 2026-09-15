import { mesesMock } from '../../mocks/catalogs.mock';
import {
  asistenciaMockRecords,
  type AsistenciaMockRecord,
} from '../../mocks/asistencia.mock';
import type {
  AsistenciaDetalle,
  AsistenciaDetalleResponse,
  AsistenciaResumen,
} from '../../types/asistencia';
import type { BiFilters } from '../../types/filters';
import type { AsistenciaService } from '../contracts/asistencia.service';

function filterRecords(
  filters: BiFilters = {},
): AsistenciaMockRecord[] {
  return asistenciaMockRecords.filter((record) => {
    if (
      filters.anio &&
      record.anio !== filters.anio
    ) {
      return false;
    }

    if (
      filters.mes &&
      record.mes !== filters.mes
    ) {
      return false;
    }

    if (
      filters.areaId &&
      record.areaId !== filters.areaId
    ) {
      return false;
    }

    if (
      filters.trabajadorId &&
      String(record.empleadoId) !== filters.trabajadorId
    ) {
      return false;
    }

    return true;
  });
}

function sum(
  records: AsistenciaMockRecord[],
  selector: (record: AsistenciaMockRecord) => number,
) {
  return records.reduce(
    (total, record) => total + selector(record),
    0,
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

export class AsistenciaMockService
  implements AsistenciaService
{
  async getResumen(
    filters: BiFilters = {},
  ): Promise<AsistenciaResumen> {
    const records = filterRecords(filters);

    const diasAusentes = records.filter(
      (record) => record.estado === 'AUSENTE',
    ).length;

    const horasTrabajadas = sum(
      records,
      (record) => record.horasTrabajadas,
    );

    const horasNormales = sum(
      records,
      (record) => record.horasNormales,
    );

    const horasExtras = sum(
      records,
      (record) => record.horasExtras,
    );

    const minutosAtraso = sum(
      records,
      (record) => record.minutosAtraso,
    );

    const areaGroups = new Map<
      string,
      AsistenciaMockRecord[]
    >();

    for (const record of records) {
      const group =
        areaGroups.get(record.area) ?? [];

      group.push(record);
      areaGroups.set(record.area, group);
    }

    const horasExtrasPorArea = Array.from(
      areaGroups.entries(),
    )
      .map(([label, group]) => ({
        label,
        value: sum(
          group,
          (record) => record.horasExtras,
        ),
      }))
      .sort((a, b) => b.value - a.value);

    const atrasosPorArea = Array.from(
      areaGroups.entries(),
    )
      .map(([label, group]) => ({
        label,
        value: sum(
          group,
          (record) => record.minutosAtraso,
        ),
      }))
      .sort((a, b) => b.value - a.value);

    const monthGroups = new Map<
      string,
      AsistenciaMockRecord[]
    >();

    for (const record of records) {
      const key = `${record.anio}-${record.mes}`;
      const group =
        monthGroups.get(key) ?? [];

      group.push(record);
      monthGroups.set(key, group);
    }

    const evolucionHorasExtras = Array.from(
      monthGroups.entries(),
    )
      .map(([key, group]) => {
        const [anio, mes] = key
          .split('-')
          .map(Number);

        const monthName =
          mesesMock.find(
            (option) => option.id === mes,
          )?.label ?? String(mes);

        return {
          anio,
          mes,
          label: `${monthName.slice(0, 3)} ${anio}`,
          value: sum(
            group,
            (record) => record.horasExtras,
          ),
        };
      })
      .sort(
        (a, b) =>
          a.anio - b.anio ||
          a.mes - b.mes,
      );

    return {
      kpis: {
        horasTrabajadas,
        horasNormales,
        horasExtras,
        minutosAtraso,
        diasAusentes,
        ausentismo: percentage(
          diasAusentes,
          records.length,
        ),
      },

      horasExtrasPorArea,
      evolucionHorasExtras,
      atrasosPorArea,
    };
  }

  async getDetalle(
    filters: BiFilters = {},
  ): Promise<AsistenciaDetalleResponse> {
    const records = filterRecords(filters)
      .sort((a, b) =>
        b.fecha.localeCompare(a.fecha) ||
        a.empleadoId - b.empleadoId,
      );

    const items: AsistenciaDetalle[] =
      records
        .slice(0, 20)
        .map((record) => ({
          asistenciaId: `${record.empleadoId}-${record.fecha}`,
          trabajadorId: String(record.empleadoId),
          empleado: record.empleado,
          fecha: record.fecha,
          area: record.area,
          horasTrabajadas:
            record.horasTrabajadas,
          horasExtras: record.horasExtras,
          minutosAtraso:
            record.minutosAtraso,
          estado: record.estado,
        }));

    return {
      items,
      pagination: {
        page: 1,
        pageSize: 20,
        total: records.length,
      },
    };
  }
}

export const asistenciaMockService =
  new AsistenciaMockService();
