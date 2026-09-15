import {
  useEffect,
  useState,
} from 'react';
import {
  BadgeDollarSign,
  Banknote,
  CircleDollarSign,
  Clock3,
  Coins,
  ReceiptText,
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
import { RemuneracionesFilterBar } from '../components/filters/RemuneracionesFilterBar';
import { KpiCard } from '../components/kpi/KpiCard';
import {
  DataTable,
  type DataTableColumn,
} from '../components/tables/DataTable';
import { remuneracionesService } from '../services/remuneraciones.service';
import type { BiFilters } from '../types/filters';
import type {
  RemuneracionDetalle,
  RemuneracionesDetalleResponse,
  RemuneracionesResumen,
} from '../types/remuneraciones';

const currencyFormatter =
  new Intl.NumberFormat('es-CL', {
    style: 'currency',
    currency: 'CLP',
    maximumFractionDigits: 0,
  });

const numberFormatter =
  new Intl.NumberFormat('es-CL', {
    maximumFractionDigits: 1,
  });

function formatCurrency(
  value: number,
) {
  return currencyFormatter.format(value);
}

const columns: DataTableColumn<RemuneracionDetalle>[] = [
  {
    key: 'empleado',
    label: 'Trabajador',
    render: (row) => row.empleado,
  },
  {
    key: 'area',
    label: 'Área',
    render: (row) => row.area,
  },
  {
    key: 'periodo',
    label: 'Período',
    render: (row) => row.periodo,
  },
  {
    key: 'base',
    label: 'Sueldo base',
    align: 'right',
    render: (row) =>
      formatCurrency(row.sueldoBase),
  },
  {
    key: 'horasExtras',
    label: 'Horas extra',
    align: 'right',
    render: (row) =>
      `${numberFormatter.format(
        row.horasExtras,
      )} h`,
  },
  {
    key: 'sueldoLiquido',
    label: 'Sueldo líquido',
    align: 'right',
    render: (row) =>
      formatCurrency(row.sueldoLiquido),
  },
  {
    key: 'descuentos',
    label: 'Descuentos',
    align: 'right',
    render: (row) =>
      formatCurrency(row.descuentos),
  },
  {
    key: 'costoEmpresa',
    label: 'Costo empresa',
    align: 'right',
    render: (row) =>
      formatCurrency(row.costoEmpresa),
  },
];

export function RemuneracionesPage() {
  const [filters, setFilters] =
    useState<BiFilters>({
      anio: 2026,
    });

  const [summary, setSummary] =
    useState<RemuneracionesResumen | null>(
      null,
    );

  const [detail, setDetail] =
    useState<RemuneracionesDetalleResponse | null>(
      null,
    );

  useEffect(() => {
    let active = true;

    Promise.all([
      remuneracionesService.getResumen(
        filters,
      ),
      remuneracionesService.getDetalle(
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
            Personas
          </p>

          <h1>Remuneraciones</h1>

          <p>
            Costos laborales, horas
            extra, sueldo líquido y
            costo empresa.
          </p>
        </div>
      </div>

      <RemuneracionesFilterBar
        filters={filters}
        onChange={setFilters}
      />

      {summary?.calidadDatos?.coberturaParcial ? (
        <div style={{ marginBottom: '18px' }}>
          <AlertCard
            tone="warning"
            title="Cobertura parcial de remuneraciones"
            description={`Existen remuneraciones para ${summary.calidadDatos.trabajadoresConRemuneracion} de ${summary.calidadDatos.totalTrabajadoresRrhh} trabajadores (${summary.calidadDatos.porcentajeCobertura}%). Los indicadores corresponden solo a los trabajadores con liquidación disponible en el período.`}
          />
        </div>
      ) : null}

      {summary &&
      detail &&
      !hasData ? (
        <AlertCard
          tone="info"
          title="Sin registros de remuneraciones"
          description="No existen registros para la combinación de período, área y trabajador seleccionada."
        />
      ) : null}

      {summary &&
      detail &&
      hasData ? (
        <>
          <div className="kpi-grid remuneraciones-kpi-grid">
            <KpiCard
              title="Total haberes"
              value={formatCurrency(
                summary.kpis.costoTotal,
              )}
              helper="período seleccionado"
              icon={Banknote}
            />

            <KpiCard
              title="Remuneración promedio"
              value={formatCurrency(
                summary.kpis.sueldoPromedio,
              )}
              helper="promedio por registro"
              icon={CircleDollarSign}
            />

            <KpiCard
              title="Horas extra"
              value={`${numberFormatter.format(
                summary.kpis.horasExtras,
              )} h`}
              helper="período seleccionado"
              icon={Clock3}
            />

            <KpiCard
              title="Sueldo líquido"
              value={formatCurrency(
                summary.kpis.sueldoLiquido,
              )}
              helper="total acumulado"
              icon={Coins}
            />

            <KpiCard
              title="Descuentos"
              value={formatCurrency(
                summary.kpis.descuentos,
              )}
              helper="total acumulado"
              icon={ReceiptText}
            />

            <KpiCard
              title="Costo empresa"
              value={formatCurrency(
                summary.kpis
                  .costoEmpresa,
              )}
              helper="costo laboral estimado"
              icon={BadgeDollarSign}
            />
          </div>

          <div className="dashboard-two-columns">
            <ChartCard
              title="Costo por área"
              description="Costo empresa acumulado por área."
            >
              <div className="chart-demo">
                <ResponsiveContainer
                  width="100%"
                  height={300}
                >
                  <BarChart
                    data={
                      summary.costoPorArea
                    }
                    layout="vertical"
                    margin={{
                      top: 5,
                      right: 25,
                      bottom: 28,
                      left: 30,
                    }}
                  >
                    <CartesianGrid
                      strokeDasharray="3 3"
                      horizontal={false}
                    />

                    <XAxis
                      type="number" height={30}
                      tickFormatter={(value) =>
                        `${Math.round(
                          Number(value) /
                            1000000,
                        )}M`
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
                      radius={[
                        0,
                        5,
                        5,
                        0,
                      ]}
                    />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </ChartCard>

            <ChartCard
              title="Horas extra por área"
              description="Horas extra acumuladas según asistencia."
            >
              <div className="chart-demo">
                <ResponsiveContainer
                  width="100%"
                  height={300}
                >
                  <BarChart
                    data={
                      summary
                        .horasExtrasPorArea
                    }
                    layout="vertical"
                    margin={{
                      top: 5,
                      right: 25,
                      bottom: 28,
                      left: 30,
                    }}
                  >
                    <CartesianGrid
                      strokeDasharray="3 3"
                      horizontal={false}
                    />

                    <XAxis
                      type="number" height={30}
                    />

                    <YAxis
                      type="category"
                      dataKey="label"
                      width={165}
                      tickLine={false}
                      axisLine={false}
                    />

                    <Tooltip />

                    <Bar
                      dataKey="value"
                      fill="var(--primary)"
                      radius={[
                        0,
                        5,
                        5,
                        0,
                      ]}
                    />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </ChartCard>
          </div>

          <ChartCard
            title="Evolución mensual del costo empresa"
            description="Costo laboral mensual para los filtros seleccionados."
          >
            <div className="chart-demo">
              <ResponsiveContainer
                width="100%"
                height={300}
              >
                <LineChart
                  data={
                    summary.evolucionMensual
                  }
                  margin={{
                    top: 10,
                    right: 25,
                    bottom: 28,
                    left: 10,
                  }}
                >
                  <CartesianGrid
                    strokeDasharray="3 3"
                    vertical={false}
                  />

                  <XAxis
                    dataKey="label" height={34}
                    tickLine={false}
                    axisLine={false}
                  />

                  <YAxis
                    tickFormatter={(value) =>
                      `${Math.round(
                        Number(value) /
                          1000000,
                      )}M`
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
            title="Detalle de remuneraciones"
            description={`Primeros ${detail.items.length} registros de ${detail.pagination.total} liquidaciones filtradas.`}
          >
            <DataTable
              columns={columns}
              rows={detail.items}
              getRowKey={(row) =>
                `${row.trabajadorId}-${row.periodo}`
              }
            />
          </ChartCard>
        </>
      ) : null}
    </section>
  );
}
