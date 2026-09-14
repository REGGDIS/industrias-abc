import {
  useEffect,
  useState,
} from 'react';
import {
  Boxes,
  CheckCircle2,
  Factory,
  Gauge,
  PackageCheck,
  TriangleAlert,
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
import { ProduccionFilterBar } from '../components/filters/ProduccionFilterBar';
import { KpiCard } from '../components/kpi/KpiCard';
import {
  DataTable,
  type DataTableColumn,
} from '../components/tables/DataTable';
import { produccionMockService } from '../services/mock/produccion.mock.service';
import type { BiFilters } from '../types/filters';
import type {
  ProduccionDetalle,
  ProduccionDetalleResponse,
  ProduccionResumen,
} from '../types/produccion';

const numberFormatter =
  new Intl.NumberFormat('es-CL', {
    maximumFractionDigits: 1,
  });

function formatNumber(
  value: number,
) {
  return numberFormatter.format(value);
}

const columns: DataTableColumn<ProduccionDetalle>[] = [
  {
    key: 'orden',
    label: 'Orden',
    render: (row) =>
      `OP-${String(
        row.ordenProduccionId,
      ).padStart(4, '0')}`,
  },
  {
    key: 'producto',
    label: 'Producto',
    render: (row) =>
      row.producto,
  },
  {
    key: 'planificada',
    label: 'Planificada',
    align: 'right',
    render: (row) =>
      formatNumber(
        row.cantidadPlanificada,
      ),
  },
  {
    key: 'producida',
    label: 'Producida',
    align: 'right',
    render: (row) =>
      formatNumber(
        row.cantidadProducida,
      ),
  },
  {
    key: 'rechazada',
    label: 'Rechazada',
    align: 'right',
    render: (row) =>
      formatNumber(
        row.cantidadRechazada,
      ),
  },
  {
    key: 'cumplimiento',
    label: 'Cumplimiento',
    align: 'right',
    render: (row) =>
      `${row.cumplimiento.toLocaleString(
        'es-CL',
        {
          maximumFractionDigits: 1,
        },
      )} %`,
  },
];

export function ProduccionPage() {
  const [filters, setFilters] =
    useState<BiFilters>({
      anio: 2026,
    });

  const [summary, setSummary] =
    useState<ProduccionResumen | null>(
      null,
    );

  const [detail, setDetail] =
    useState<ProduccionDetalleResponse | null>(
      null,
    );

  useEffect(() => {
    let active = true;

    Promise.all([
      produccionMockService.getResumen(
        filters,
      ),
      produccionMockService.getDetalle(
        filters,
      ),
    ]).then(
      ([summaryResult, detailResult]) => {
        if (!active) {
          return;
        }

        setSummary(summaryResult);
        setDetail(detailResult);
      },
    );

    return () => {
      active = false;
    };
  }, [filters]);

  const hasData =
    Boolean(
      detail &&
        detail.pagination.total > 0,
    );

  return (
    <section className="module-page">
      <div className="page-heading">
        <div>
          <p className="page-eyebrow">
            Operaciones
          </p>

          <h1>Producción</h1>

          <p>
            Producción planificada,
            producción real, rechazo y
            consumo de insumos.
          </p>
        </div>
      </div>

      <ProduccionFilterBar
        filters={filters}
        onChange={setFilters}
      />

      {summary &&
      detail &&
      !hasData ? (
        <AlertCard
          tone="info"
          title="Sin registros de producción"
          description="No existen órdenes de producción mock para la combinación de período, producto e insumo seleccionada."
        />
      ) : null}

      {summary &&
      detail &&
      hasData ? (
        <>
          <div className="kpi-grid produccion-kpi-grid">
            <KpiCard
              title="Producción planificada"
              value={formatNumber(
                summary.kpis
                  .produccionPlanificada,
              )}
              helper="unidades planificadas"
              icon={Factory}
            />

            <KpiCard
              title="Producción real"
              value={formatNumber(
                summary.kpis
                  .produccionReal,
              )}
              helper="unidades producidas"
              icon={PackageCheck}
            />

            <KpiCard
              title="Cumplimiento"
              value={`${summary.kpis.cumplimientoProduccion.toLocaleString(
                'es-CL',
                {
                  maximumFractionDigits: 1,
                },
              )} %`}
              helper="real vs planificado"
              icon={Gauge}
            />

            <KpiCard
              title="Cantidad rechazada"
              value={formatNumber(
                summary.kpis
                  .cantidadRechazada,
              )}
              helper="unidades rechazadas"
              icon={TriangleAlert}
            />

            <KpiCard
              title="Tasa de rechazo"
              value={`${summary.kpis.tasaRechazo.toLocaleString(
                'es-CL',
                {
                  maximumFractionDigits: 1,
                },
              )} %`}
              helper="sobre producción real"
              icon={CheckCircle2}
            />

            <KpiCard
              title="Consumo de insumos"
              value={formatNumber(
                summary.kpis
                  .consumoInsumos,
              )}
              helper="unidades equivalentes"
              icon={Boxes}
            />
          </div>

          <div className="dashboard-two-columns">
            <ChartCard
              title="Productos con mayor rechazo"
              description="Unidades rechazadas acumuladas por producto."
            >
              <div className="chart-demo">
                <ResponsiveContainer
                  width="100%"
                  height={300}
                >
                  <BarChart
                    data={
                      summary
                        .productosConMayorRechazo
                    }
                    layout="vertical"
                    margin={{
                      left: 30,
                      right: 25,
                    }}
                  >
                    <CartesianGrid
                      strokeDasharray="3 3"
                      horizontal={false}
                    />

                    <XAxis
                      type="number"
                      allowDecimals={false}
                    />

                    <YAxis
                      type="category"
                      dataKey="label"
                      width={135}
                      tickLine={false}
                      axisLine={false}
                    />

                    <Tooltip
                      formatter={(value) => [
                        formatNumber(Number(value)),
                        'Unidades rechazadas',
                      ]}
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
              title="Consumo por insumo"
              description="Consumo acumulado por tipo de insumo."
            >
              <div className="chart-demo">
                <ResponsiveContainer
                  width="100%"
                  height={300}
                >
                  <BarChart
                    data={
                      summary
                        .consumoPorInsumo
                    }
                    layout="vertical"
                    margin={{
                      left: 30,
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
                        formatNumber(Number(value))
                      }
                    />

                    <YAxis
                      type="category"
                      dataKey="label"
                      width={170}
                      tickLine={false}
                      axisLine={false}
                    />

                    <Tooltip
                      formatter={(value) => [
                        formatNumber(Number(value)),
                        'Consumo',
                      ]}
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
            title="Evolución mensual de producción"
            description="Producción real mensual para los filtros seleccionados."
          >
            <div className="chart-demo">
              <ResponsiveContainer
                width="100%"
                height={300}
              >
                <LineChart
                  data={
                    summary
                      .evolucionMensual
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
                    allowDecimals={false}
                    tickFormatter={(value) =>
                      formatNumber(Number(value))
                    }
                  />

                  <Tooltip
                    formatter={(value) => [
                      formatNumber(Number(value)),
                      'Producción real',
                    ]}
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
            title="Detalle de órdenes de producción"
            description={`Primeros ${detail.items.length} registros de ${detail.pagination.total} órdenes mock filtradas.`}
          >
            <DataTable
              columns={columns}
              rows={detail.items}
              getRowKey={(row) =>
                row.ordenProduccionId
              }
            />
          </ChartCard>
        </>
      ) : null}
    </section>
  );
}
