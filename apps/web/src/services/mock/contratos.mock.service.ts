import { mesesMock } from '../../mocks/catalogs.mock';
import {
  contratosMockRecords,
  type ContratoMockRecord,
} from '../../mocks/contratos.mock';
import type {
  ContratoDetalle,
  ContratosDetalleResponse,
  ContratosResumen,
} from '../../types/contratos';
import type { BiFilters } from '../../types/filters';
import type { ContratosService } from '../contracts/contratos.service';

const MOCK_CURRENT_DATE = new Date(
  '2026-09-12T23:59:59',
);

function parseDate(value: string) {
  return new Date(`${value}T00:00:00`);
}

function resolvePeriod(filters: BiFilters) {
  const anio = filters.anio ?? 2026;

  const mes =
    filters.mes ??
    (anio === 2026 ? 9 : 12);

  let end = new Date(
    anio,
    mes,
    0,
    23,
    59,
    59,
  );

  if (end > MOCK_CURRENT_DATE) {
    end = MOCK_CURRENT_DATE;
  }

  return {
    anio,
    mes,
    end,
  };
}

function filterDimensions(
  records: ContratoMockRecord[],
  filters: BiFilters,
) {
  return records.filter((record) => {
    if (
      filters.areaId &&
      record.areaId !== filters.areaId
    ) {
      return false;
    }

    if (
      filters.empleadoId &&
      record.empleadoId !== filters.empleadoId
    ) {
      return false;
    }

    return true;
  });
}

function getEffectiveEndDate(
  record: ContratoMockRecord,
) {
  const dates = [
    record.fechaTermino,
    record.fechaSalida,
  ].filter(
    (value): value is string => Boolean(value),
  );

  if (dates.length === 0) {
    return undefined;
  }

  return dates.sort()[0];
}

function isStarted(
  record: ContratoMockRecord,
  end: Date,
) {
  return parseDate(record.fechaInicio) <= end;
}

function isCurrent(
  record: ContratoMockRecord,
  end: Date,
) {
  if (!isStarted(record, end)) {
    return false;
  }

  const effectiveEnd =
    getEffectiveEndDate(record);

  if (!effectiveEnd) {
    return true;
  }

  return parseDate(effectiveEnd) >= end;
}

function isExpired(
  record: ContratoMockRecord,
  end: Date,
) {
  const effectiveEnd =
    getEffectiveEndDate(record);

  return Boolean(
    effectiveEnd &&
      parseDate(effectiveEnd) < end,
  );
}

function daysBetween(
  from: Date,
  to: Date,
) {
  const milliseconds =
    to.getTime() - from.getTime();

  return Math.ceil(
    milliseconds / (1000 * 60 * 60 * 24),
  );
}

function buildDetail(
  record: ContratoMockRecord,
  end: Date,
): ContratoDetalle {
  const effectiveEnd =
    getEffectiveEndDate(record);

  const expiry = effectiveEnd
    ? parseDate(effectiveEnd)
    : undefined;

  const diasRestantes =
    expiry && expiry >= end
      ? daysBetween(end, expiry)
      : undefined;

  return {
    contratoId: record.contratoId,
    empleadoId: record.empleadoId,
    empleado: record.empleado,
    tipoContrato: record.tipoContrato,
    fechaInicio: record.fechaInicio,
    fechaTermino: effectiveEnd,
    diasRestantes,
    estado: isCurrent(record, end)
      ? 'VIGENTE'
      : 'VENCIDO',
  };
}

export class ContratosMockService
  implements ContratosService
{
  async getResumen(
    filters: BiFilters = {},
  ): Promise<ContratosResumen> {
    const { anio, mes, end } =
      resolvePeriod(filters);

    const dimensionRecords = filterDimensions(
      contratosMockRecords,
      filters,
    );

    const visible = dimensionRecords.filter(
      (record) => isStarted(record, end),
    );

    const vigentes = visible.filter(
      (record) => isCurrent(record, end),
    );

    const vencidos = visible.filter(
      (record) => isExpired(record, end),
    );

    const expiryLimit = new Date(end);

    expiryLimit.setDate(
      expiryLimit.getDate() + 90,
    );

    const proximosVencer = vigentes.filter(
      (record) => {
        const effectiveEnd =
          getEffectiveEndDate(record);

        if (!effectiveEnd) {
          return false;
        }

        const expiry = parseDate(
          effectiveEnd,
        );

        return (
          expiry > end &&
          expiry <= expiryLimit
        );
      },
    );

    const typeGroups = new Map<
      string,
      number
    >();

    for (const record of vigentes) {
      typeGroups.set(
        record.tipoContrato,
        (typeGroups.get(record.tipoContrato) ?? 0) + 1,
      );
    }

    const contratosPorTipo = Array.from(
      typeGroups.entries(),
    )
      .map(([label, value]) => ({
        label,
        value,
      }))
      .sort((a, b) => b.value - a.value);

    const ultimoMes = 12;

    const vencimientosPorMes = Array.from(
      { length: ultimoMes },
      (_, index) => {
        const currentMonth = index + 1;

        const count = dimensionRecords.filter(
          (record) => {
            const effectiveEnd =
              getEffectiveEndDate(record);

            if (!effectiveEnd) {
              return false;
            }

            const expiry = parseDate(
              effectiveEnd,
            );

            return (
              expiry.getFullYear() === anio &&
              expiry.getMonth() + 1 ===
                currentMonth
            );
          },
        ).length;

        const monthName =
          mesesMock.find(
            (option) =>
              option.id === currentMonth,
          )?.label ?? String(currentMonth);

        return {
          anio,
          mes: currentMonth,
          label: monthName.slice(0, 3),
          value: count,
        };
      },
    ).filter((item) =>
      filters.mes
        ? item.mes === mes
        : true,
    );

    return {
      kpis: {
        vigentes: vigentes.length,

        indefinidos: vigentes.filter(
          (record) =>
            record.tipoContrato ===
            'INDEFINIDO',
        ).length,

        plazoFijo: vigentes.filter(
          (record) =>
            record.tipoContrato ===
            'PLAZO_FIJO',
        ).length,

        temporales: vigentes.filter(
          (record) =>
            record.tipoContrato ===
            'TEMPORAL',
        ).length,

        proximosVencer:
          proximosVencer.length,

        vencidos: vencidos.length,
      },

      contratosPorTipo,
      vencimientosPorMes,
    };
  }

  async getDetalle(
    filters: BiFilters = {},
  ): Promise<ContratosDetalleResponse> {
    const { end } =
      resolvePeriod(filters);

    const records = filterDimensions(
      contratosMockRecords,
      filters,
    )
      .filter((record) =>
        isStarted(record, end),
      )
      .map((record) =>
        buildDetail(record, end),
      )
      .sort((a, b) => {
        if (
          a.estado === 'VIGENTE' &&
          b.estado !== 'VIGENTE'
        ) {
          return -1;
        }

        if (
          b.estado === 'VIGENTE' &&
          a.estado !== 'VIGENTE'
        ) {
          return 1;
        }

        return a.empleado.localeCompare(
          b.empleado,
        );
      });

    return {
      items: records.slice(0, 20),

      pagination: {
        page: 1,
        pageSize: 20,
        total: records.length,
      },
    };
  }
}

export const contratosMockService =
  new ContratosMockService();