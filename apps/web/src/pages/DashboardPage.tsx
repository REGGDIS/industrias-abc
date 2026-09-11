import {
  useEffect,
  useMemo,
  useState,
} from 'react';
import {
  Banknote,
  BarChart3,
  Clock3,
  Factory,
  ReceiptText,
  ShoppingCart,
  UserCheck,
  Users,
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
import { FilterBar } from '../components/filters/FilterBar';
import { KpiCard } from '../components/kpi/KpiCard';
import {
  DataTable,
  type DataTableColumn,
} from '../components/tables/DataTable';
import { dashboardMockService } from '../services/mock/dashboard.mock.service';
import type {
  DashboardAreaSummary,
  DashboardResumen,
} from '../types/dashboard';
import type { BiFilters } from '../types/filters';

const moneyFormatter = new Intl.NumberFormat('es-CL', {
  style: 'currency',
  currency: 'CLP',
  maximumFractionDigits: 0,
});

const numberFormatter = new Intl.NumberFormat('es-CL');

function formatMoney(value: number) {
  if (value >= 1_000_000_000) {
    return `$${(value / 1_000_000_000).toLocaleString(
      'es-CL',
      { maximumFractionDigits: 1 },
    )} mil MM`;
  }

  if (value >= 1_000_000) {
    return `$${(value / 1_000_000).toLocaleString(
      'es-CL',
      { maximumFractionDigits: 1 },
    )} MM`;
  }

  return moneyFormatter.format(value);
}

function formatAxisMoney(value: number) {
  if (value >= 1_000_000) {
    return `${Math.round(value / 1_000_000)} MM`;
  }

  return numberFormatter.format(value);
}

const columns: DataTableColumn<DashboardAreaSummary>[] = [
  {
    key: 'area',
    label: 'Área',
    render: (row) => row.area,
  },
  {
    key: 'trabajadores',
    label: 'Trabajadores',
    align: 'right',
    render: (row) =>
      numberFormatter.format(row.trabajadores),
  },
  {
    key: 'remuneraciones',
    label: 'Remuneraciones',
    align: 'right',
    render: (row) =>
      formatMoney(row.costoRemuneraciones),
  },
  {
    key: 'horasExtras',
    label: 'Horas extra',
    align: 'right',
    render: (row) =>
      `${numberFormatter.format(row.horasExtras)} h`,
  },
  {
    key: 'compras',
    label: 'Compras',
    align: 'right',
    render: (row) => formatMoney(row.compras),
  },
  {
    key: 'gastos',
    label: 'Gastos',
    align: 'right',
    render: (row) =>
      formatMoney(row.gastosContables),
  },
];

export function DashboardPage() {
  const [filters, setFilters] = useState<BiFilters>({
    anio: 2026,
  });

  const [data, setData] =
    useState<DashboardResumen | null>(null);

  useEffect(() => {
    let active = true;

    dashboardMockService
      .getResumen(filters)
      .then((result) => {
        if (active) {
          setData(result);
        }
      });

    return () => {
      active = false;
    };
  }, [filters]);

  const hasData = Boolean(
    data && data.resumenPorArea.length > 0,
  );

  const centerCostData = useMemo(
    () =>
      data?.principalesCentrosCosto.slice(0, 5) ?? [],
    [data],
  );

  return (
    <section className="module-page">
      <div className="page-heading">
        <div>
          <p className="page-eyebrow">
            Industrias ABC
          </p>

          <h1>Dashboard Ejecutivo</h1>

          <p>
            Visión consolidada de personas, costos,
            compras, contabilidad y producción.
          </p>
        </div>
      </div>

      <FilterBar
        filters={filters}
        onChange={setFilters}
      />

      {!hasData && data ? (
        <AlertCard
          tone="info"
          title="Sin información para los filtros seleccionados"
          description="No existen registros mock para esta combinación. Prueba otro período, área o centro de costo."
        />
      ) : null}

      {data && hasData ? (
        <>
          <div className="kpi-grid">
            <KpiCard
              title="Total trabajadores"
              value={numberFormatter.format(
                data.kpis.totalTrabajadores,
              )}
              helper="dotación último período"
              icon={Users}
            />

            <KpiCard
              title="Trabajadores activos"
              value={numberFormatter.format(
                data.kpis.trabajadoresActivos,
              )}
              helper="último período disponible"
              icon={UserCheck}
            />

            <KpiCard
              title="Costo remuneraciones"
              value={formatMoney(
                data.kpis.costoRemuneraciones,
              )}
              helper="período filtrado"
              icon={Banknote}
            />

            <KpiCard
              title="Horas extra"
              value={`${numberFormatter.format(
                data.kpis.horasExtras,
              )} h`}
              helper="período filtrado"
              icon={Clock3}
            />

            <KpiCard
              title="Compras"
              value={formatMoney(
                data.kpis.totalCompras,
              )}
              helper="período filtrado"
              icon={ShoppingCart}
            />

            <KpiCard
              title="Gastos contables"
              value={formatMoney(
                data.kpis.gastosContables,
              )}
              helper="período filtrado"
              icon={ReceiptText}
            />

            <KpiCard
              title="Producción real"
              value={numberFormatter.format(
                data.kpis.produccionReal,
              )}
              helper="unidades producidas"
              icon={Factory}
            />

            <KpiCard
              title="Cumplimiento producción"
              value={`${data.kpis.cumplimientoProduccion.toLocaleString(
                'es-CL',
                {
                  maximumFractionDigits: 1,
                },
              )} %`}
              helper="real versus plan"
              icon={BarChart3}
            />
          </div>

          <div className="dashboard-two-columns">
            <ChartCard
              title="Evolución mensual de costos"
              description="Remuneraciones, compras y gastos contables consolidados."
            >
              <div className="chart-demo">
                <ResponsiveContainer
                  width="100%"
                  height={280}
                >
                  <LineChart
                    data={data.evolucionMensual}
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
                      tickFormatter={formatAxisMoney}
                      tickLine={false}
                      axisLine={false}
                    />

                    <Tooltip
                      formatter={(value) =>
                        formatMoney(Number(value))
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
              title="Principales centros de costo"
              description="Costo integrado del período filtrado."
            >
              <div className="chart-demo">
                <ResponsiveContainer
                  width="100%"
                  height={280}
                >
                  <BarChart
                    data={centerCostData}
                    layout="vertical"
                    margin={{
                      left: 25,
                      right: 20,
                    }}
                  >
                    <CartesianGrid
                      strokeDasharray="3 3"
                      horizontal={false}
                    />

                    <XAxis
                      type="number"
                      tickFormatter={formatAxisMoney}
                      tickLine={false}
                      axisLine={false}
                    />

                    <YAxis
                      type="category"
                      dataKey="label"
                      width={135}
                      tickLine={false}
                      axisLine={false}
                    />

                    <Tooltip
                      formatter={(value) =>
                        formatMoney(Number(value))
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
            title="Resumen por área"
            description="Indicadores integrados para el período seleccionado."
          >
            <DataTable
              columns={columns}
              rows={data.resumenPorArea}
              getRowKey={(row) => row.areaId}
            />
          </ChartCard>
        </>
      ) : null}
    </section>
  );
}
