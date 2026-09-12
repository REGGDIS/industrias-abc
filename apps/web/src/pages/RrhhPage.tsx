import {
  useEffect,
  useState,
} from 'react';
import {
  Activity,
  CalendarClock,
  RefreshCcw,
  UserCheck,
  Users,
  UserX,
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
import { StatusBadge } from '../components/feedback/StatusBadge';
import { RrhhFilterBar } from '../components/filters/RrhhFilterBar';
import { KpiCard } from '../components/kpi/KpiCard';
import {
  DataTable,
  type DataTableColumn,
} from '../components/tables/DataTable';
import { rrhhMockService } from '../services/mock/rrhh.mock.service';
import type { BiFilters } from '../types/filters';
import type {
  RrhhResumen,
  TrabajadorDetalle,
  TrabajadoresResponse,
} from '../types/rrhh';

const numberFormatter = new Intl.NumberFormat('es-CL');

const columns: DataTableColumn<TrabajadorDetalle>[] = [
  {
    key: 'nombre',
    label: 'Trabajador',
    render: (row) => row.nombre,
  },
  {
    key: 'rut',
    label: 'RUT',
    render: (row) => row.rut,
  },
  {
    key: 'area',
    label: 'Área',
    render: (row) => row.area,
  },
  {
    key: 'cargo',
    label: 'Cargo',
    render: (row) => row.cargo,
  },
  {
    key: 'ingreso',
    label: 'Ingreso',
    render: (row) =>
      new Intl.DateTimeFormat('es-CL').format(
        new Date(`${row.fechaIngreso}T00:00:00`),
      ),
  },
  {
    key: 'estado',
    label: 'Estado',
    align: 'center',
    render: (row) => (
      <StatusBadge
        label={row.estado}
        tone={
          row.estado === 'ACTIVO'
            ? 'success'
            : 'warning'
        }
      />
    ),
  },
];

export function RrhhPage() {
  const [filters, setFilters] = useState<BiFilters>({
    anio: 2026,
  });

  const [summary, setSummary] =
    useState<RrhhResumen | null>(null);

  const [workers, setWorkers] =
    useState<TrabajadoresResponse | null>(null);

  useEffect(() => {
    let active = true;

    Promise.all([
      rrhhMockService.getResumen(filters),
      rrhhMockService.getTrabajadores(filters),
    ]).then(([summaryResult, workersResult]) => {
      if (!active) {
        return;
      }

      setSummary(summaryResult);
      setWorkers(workersResult);
    });

    return () => {
      active = false;
    };
  }, [filters]);

  const hasData =
    Boolean(
      summary &&
        summary.kpis.totalTrabajadores > 0,
    );

  return (
    <section className="module-page">
      <div className="page-heading">
        <div>
          <p className="page-eyebrow">
            Personas
          </p>

          <h1>Recursos Humanos</h1>

          <p>
            Dotación, situación laboral, rotación,
            ausentismo y contratos próximos a vencer.
          </p>
        </div>
      </div>

      <RrhhFilterBar
        filters={filters}
        onChange={setFilters}
      />

      {summary && !hasData ? (
        <AlertCard
          tone="info"
          title="Sin trabajadores para los filtros seleccionados"
          description="No existen registros mock para esta combinación de período, área y cargo."
        />
      ) : null}

      {summary && workers && hasData ? (
        <>
          <div className="kpi-grid rrhh-kpi-grid">
            <KpiCard
              title="Total trabajadores"
              value={numberFormatter.format(
                summary.kpis.totalTrabajadores,
              )}
              helper="dotación del período"
              icon={Users}
            />

            <KpiCard
              title="Trabajadores activos"
              value={numberFormatter.format(
                summary.kpis.trabajadoresActivos,
              )}
              helper="estado activo"
              icon={UserCheck}
            />

            <KpiCard
              title="Trabajadores inactivos"
              value={numberFormatter.format(
                summary.kpis.trabajadoresInactivos,
              )}
              helper="estado inactivo"
              icon={UserX}
            />

            <KpiCard
              title="Rotación"
              value={`${summary.kpis.rotacion.toLocaleString(
                'es-CL',
                {
                  maximumFractionDigits: 1,
                },
              )} %`}
              helper="salidas del mes"
              icon={RefreshCcw}
            />

            <KpiCard
              title="Ausentismo"
              value={`${summary.kpis.ausentismo.toLocaleString(
                'es-CL',
                {
                  maximumFractionDigits: 1,
                },
              )} %`}
              helper="días ausentes estimados"
              icon={Activity}
            />

            <KpiCard
              title="Contratos por vencer"
              value={numberFormatter.format(
                summary.kpis.contratosProximosVencer,
              )}
              helper="próximos 90 días"
              icon={CalendarClock}
            />
          </div>

          <div className="dashboard-two-columns">
            <ChartCard
              title="Trabajadores por área"
              description="Distribución de la dotación seleccionada."
            >
              <div className="chart-demo">
                <ResponsiveContainer
                  width="100%"
                  height={280}
                >
                  <BarChart
                    data={summary.trabajadoresPorArea}
                    layout="vertical"
                    margin={{
                      left: 35,
                      right: 20,
                    }}
                  >
                    <CartesianGrid
                      strokeDasharray="3 3"
                      horizontal={false}
                    />

                    <XAxis
                      type="number"
                      allowDecimals={false}
                      tickLine={false}
                      axisLine={false}
                    />

                    <YAxis
                      type="category"
                      dataKey="label"
                      width={150}
                      tickLine={false}
                      axisLine={false}
                    />

                    <Tooltip />

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
              title="Trabajadores por cargo"
              description="Principales cargos de la dotación seleccionada."
            >
              <div className="chart-demo">
                <ResponsiveContainer
                  width="100%"
                  height={280}
                >
                  <BarChart
                    data={summary.trabajadoresPorCargo.slice(
                      0,
                      8,
                    )}
                    layout="vertical"
                    margin={{
                      left: 45,
                      right: 20,
                    }}
                  >
                    <CartesianGrid
                      strokeDasharray="3 3"
                      horizontal={false}
                    />

                    <XAxis
                      type="number"
                      allowDecimals={false}
                      tickLine={false}
                      axisLine={false}
                    />

                    <YAxis
                      type="category"
                      dataKey="label"
                      width={180}
                      tickLine={false}
                      axisLine={false}
                    />

                    <Tooltip />

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
            title="Evolución de la dotación"
            description="Cantidad de trabajadores por mes para el año seleccionado."
          >
            <div className="chart-demo">
              <ResponsiveContainer
                width="100%"
                height={280}
              >
                <LineChart
                  data={summary.evolucionDotacion}
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
                    tickLine={false}
                    axisLine={false}
                  />

                  <Tooltip />

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
            title="Detalle de trabajadores"
            description={`Primeros ${workers.items.length} registros de ${workers.pagination.total} trabajadores filtrados.`}
          >
            <DataTable
              columns={columns}
              rows={workers.items}
              getRowKey={(row) => row.empleadoId}
            />
          </ChartCard>
        </>
      ) : null}
    </section>
  );
}
