import {
  useEffect,
  useState,
} from 'react';
import {
  ArrowDownToLine,
  ArrowUpFromLine,
  BadgeDollarSign,
  Building2,
  Scale,
  TrendingUp,
} from 'lucide-react';
import {
  Bar,
  BarChart,
  CartesianGrid,
  Line,
  LineChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts';

import { ChartCard } from '../components/charts/ChartCard';
import { AlertCard } from '../components/feedback/AlertCard';
import { ContabilidadFilterBar } from '../components/filters/ContabilidadFilterBar';
import { KpiCard } from '../components/kpi/KpiCard';
import {
  DataTable,
  type DataTableColumn,
} from '../components/tables/DataTable';
import { contabilidadMockService } from '../services/mock/contabilidad.mock.service';
import type {
  ContabilidadResumen,
  MovimientoContable,
  MovimientosContablesResponse,
} from '../types/contabilidad';
import type { BiFilters } from '../types/filters';

const currencyFormatter =
  new Intl.NumberFormat('es-CL', {
    style: 'currency',
    currency: 'CLP',
    maximumFractionDigits: 0,
  });

function formatCurrency(
  value: number,
) {
  return currencyFormatter.format(value);
}

function formatCompactCurrencyAxis(
  value: number,
) {
  if (Math.abs(value) >= 1000000) {
    return `${(
      value / 1000000
    ).toLocaleString('es-CL', {
      maximumFractionDigits: 1,
    })}M`;
  }

  if (Math.abs(value) >= 1000) {
    return `${Math.round(
      value / 1000,
    ).toLocaleString('es-CL')}K`;
  }

  return value.toLocaleString('es-CL');
}

function formatDate(value: string) {
  return new Intl.DateTimeFormat(
    'es-CL',
  ).format(
    new Date(`${value}T00:00:00`),
  );
}

const columns: DataTableColumn<MovimientoContable>[] = [
  {
    key: 'fecha',
    label: 'Fecha',
    render: (row) =>
      formatDate(row.fecha),
  },
  {
    key: 'documento',
    label: 'Documento',
    render: (row) =>
      row.documento ?? '—',
  },
  {
    key: 'cuenta',
    label: 'Cuenta contable',
    render: (row) =>
      row.cuentaContable,
  },
  {
    key: 'centroCosto',
    label: 'Centro costo',
    render: (row) =>
      row.centroCosto,
  },
  {
    key: 'debe',
    label: 'Debe',
    align: 'right',
    render: (row) =>
      formatCurrency(row.debe),
  },
  {
    key: 'haber',
    label: 'Haber',
    align: 'right',
    render: (row) =>
      formatCurrency(row.haber),
  },
  {
    key: 'saldo',
    label: 'Saldo',
    align: 'right',
    render: (row) =>
      formatCurrency(row.saldo),
  },
];

export function ContabilidadPage() {
  const [filters, setFilters] =
    useState<BiFilters>({
      anio: 2026,
    });

  const [summary, setSummary] =
    useState<ContabilidadResumen | null>(
      null,
    );

  const [movements, setMovements] =
    useState<MovimientosContablesResponse | null>(
      null,
    );

  useEffect(() => {
    let active = true;

    Promise.all([
      contabilidadMockService.getResumen(
        filters,
      ),
      contabilidadMockService.getMovimientos(
        filters,
      ),
    ]).then(
      ([summaryResult, movementResult]) => {
        if (!active) {
          return;
        }

        setSummary(summaryResult);
        setMovements(movementResult);
      },
    );

    return () => {
      active = false;
    };
  }, [filters]);

  const hasData =
    Boolean(
      movements &&
        movements.pagination.total > 0,
    );

  return (
    <section className="module-page">
      <div className="page-heading">
        <div>
          <p className="page-eyebrow">
            Operaciones
          </p>

          <h1>Contabilidad</h1>

          <p>
            Gastos, cuentas contables,
            movimientos y centros de costo.
          </p>
        </div>
      </div>

      <ContabilidadFilterBar
        filters={filters}
        onChange={setFilters}
      />

      {summary &&
      movements &&
      !hasData ? (
        <AlertCard
          tone="info"
          title="Sin movimientos contables"
          description="No existen movimientos mock para la combinación de período, centro de costo y cuenta seleccionada."
        />
      ) : null}

      {summary &&
      movements &&
      hasData ? (
        <>
          <div className="kpi-grid contabilidad-kpi-grid">
            <KpiCard
              title="Gastos totales"
              value={formatCurrency(
                summary.kpis
                  .gastosTotales,
              )}
              helper="período seleccionado"
              icon={BadgeDollarSign}
            />

            <KpiCard
              title="Debe total"
              value={formatCurrency(
                summary.kpis.debeTotal,
              )}
              helper="movimientos al debe"
              icon={ArrowDownToLine}
            />

            <KpiCard
              title="Haber total"
              value={formatCurrency(
                summary.kpis.haberTotal,
              )}
              helper="movimientos al haber"
              icon={ArrowUpFromLine}
            />

            <KpiCard
              title="Saldo"
              value={formatCurrency(
                summary.kpis.saldo,
              )}
              helper="debe menos haber"
              icon={Scale}
            />

            <KpiCard
              title="Mayor centro de costo"
              value={
                summary.kpis
                  .mayorCentroCosto ??
                '—'
              }
              helper="mayor gasto acumulado"
              icon={Building2}
            />

            <KpiCard
              title="Variación mensual"
              value={
                summary.kpis
                  .variacionMensual ===
                undefined
                  ? '—'
                  : `${summary.kpis.variacionMensual.toLocaleString(
                      'es-CL',
                      {
                        maximumFractionDigits: 1,
                      },
                    )} %`
              }
              helper="respecto al mes anterior"
              icon={TrendingUp}
            />
          </div>

          <div className="dashboard-two-columns">
            <ChartCard
              title="Gastos por cuenta"
              description="Distribución del gasto por cuenta contable."
            >
              <div className="chart-demo">
                <ResponsiveContainer
                  width="100%"
                  height={300}
                >
                  <BarChart
                    data={
                      summary.gastosPorCuenta
                    }
                    layout="vertical"
                    margin={{
                      left: 35,
                      right: 25,
                    }}
                  >
                    <CartesianGrid
                      strokeDasharray="3 3"
                      horizontal={false}
                    />

                    <XAxis
                      type="number"
                      tickFormatter={(value) =>
                        formatCompactCurrencyAxis(
                          Number(value),
                        )
                      }
                    />

                    <YAxis
                      type="category"
                      dataKey="label"
                      width={190}
                      tickLine={false}
                      axisLine={false}
                    />

                    <Tooltip
                      formatter={(value) =>
                        formatCurrency(
                          Number(value),
                        )
                      }
                    />

                    <Bar
                      dataKey="value"
                      fill="var(--primary)"
                      radius={[0, 5, 5, 0]}
                    />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </ChartCard>

            <ChartCard
              title="Gastos por centro de costo"
              description="Distribución del gasto por centro de costo."
            >
              <div className="chart-demo">
                <ResponsiveContainer
                  width="100%"
                  height={300}
                >
                  <BarChart
                    data={
                      summary
                        .gastosPorCentroCosto
                    }
                    layout="vertical"
                    margin={{
                      left: 35,
                      right: 25,
                    }}
                  >
                    <CartesianGrid
                      strokeDasharray="3 3"
                      horizontal={false}
                    />

                    <XAxis
                      type="number"
                      tickFormatter={(value) =>
                        formatCompactCurrencyAxis(
                          Number(value),
                        )
                      }
                    />

                    <YAxis
                      type="category"
                      dataKey="label"
                      width={165}
                      tickLine={false}
                      axisLine={false}
                    />

                    <Tooltip
                      formatter={(value) =>
                        formatCurrency(
                          Number(value),
                        )
                      }
                    />

                    <Bar
                      dataKey="value"
                      fill="var(--primary)"
                      radius={[0, 5, 5, 0]}
                    />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </ChartCard>
          </div>

          <ChartCard
            title="Evolución mensual de gastos"
            description="Gastos contabilizados por mes."
          >
            <div className="chart-demo">
              <ResponsiveContainer
                width="100%"
                height={300}
              >
                <LineChart
                  data={
                    summary.evolucionGastos
                  }
                >
                  <CartesianGrid
                    strokeDasharray="3 3"
                    vertical={false}
                  />

                  <XAxis
                    dataKey="label"
                    tickLine={false}
                    axisLine={false}
                  />

                  <YAxis
                    tickFormatter={(value) =>
                      formatCompactCurrencyAxis(
                        Number(value),
                      )
                    }
                  />

                  <Tooltip
                    formatter={(value) =>
                      formatCurrency(
                        Number(value),
                      )
                    }
                  />

                  <Line
                    type="monotone"
                    dataKey="value"
                    stroke="var(--primary)"
                    strokeWidth={3}
                    dot={{ r: 3 }}
                    activeDot={{ r: 5 }}
                  />
                </LineChart>
              </ResponsiveContainer>
            </div>
          </ChartCard>

          <ChartCard
            title="Gastos por área"
            description="Distribución del gasto por área organizacional."
          >
            <div className="chart-demo">
              <ResponsiveContainer
                width="100%"
                height={280}
              >
                <BarChart
                  data={
                    summary.gastosPorArea
                  }
                >
                  <CartesianGrid
                    strokeDasharray="3 3"
                    vertical={false}
                  />

                  <XAxis
                    dataKey="label"
                    tickLine={false}
                    axisLine={false}
                  />

                  <YAxis
                    tickFormatter={(value) =>
                      formatCompactCurrencyAxis(
                        Number(value),
                      )
                    }
                  />

                  <Tooltip
                    formatter={(value) =>
                      formatCurrency(
                        Number(value),
                      )
                    }
                  />

                  <Bar
                    dataKey="value"
                    fill="var(--primary)"
                    radius={[5, 5, 0, 0]}
                  />
                </BarChart>
              </ResponsiveContainer>
            </div>
          </ChartCard>

          <ChartCard
            title="Detalle de movimientos contables"
            description={`Primeros ${movements.items.length} registros de ${movements.pagination.total} movimientos mock filtrados.`}
          >
            <DataTable
              columns={columns}
              rows={movements.items}
              getRowKey={(row) =>
                row.movimientoId
              }
            />
          </ChartCard>
        </>
      ) : null}
    </section>
  );
}