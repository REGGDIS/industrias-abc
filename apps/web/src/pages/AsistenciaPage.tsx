import {
  useEffect,
  useState,
} from 'react';
import {
  AlarmClock,
  CalendarX2,
  Clock3,
  Gauge,
  Timer,
  TimerReset,
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
import { AsistenciaFilterBar } from '../components/filters/AsistenciaFilterBar';
import { KpiCard } from '../components/kpi/KpiCard';
import {
  DataTable,
  type DataTableColumn,
} from '../components/tables/DataTable';
import { asistenciaService } from '../services/asistencia.service';
import type {
  AsistenciaDetalle,
  AsistenciaDetalleResponse,
  AsistenciaResumen,
} from '../types/asistencia';
import type { BiFilters } from '../types/filters';

const numberFormatter =
  new Intl.NumberFormat('es-CL', {
    maximumFractionDigits: 1,
  });

const columns: DataTableColumn<AsistenciaDetalle>[] = [
  {
    key: 'empleado',
    label: 'Trabajador',
    render: (row) => row.empleado,
  },
  {
    key: 'fecha',
    label: 'Fecha',
    render: (row) =>
      new Intl.DateTimeFormat('es-CL').format(
        new Date(`${row.fecha}T00:00:00`),
      ),
  },
  {
    key: 'area',
    label: 'Área',
    render: (row) => row.area,
  },
  {
    key: 'horas',
    label: 'Horas trabajadas',
    align: 'right',
    render: (row) =>
      `${numberFormatter.format(
        row.horasTrabajadas,
      )} h`,
  },
  {
    key: 'extras',
    label: 'Horas extra',
    align: 'right',
    render: (row) =>
      `${numberFormatter.format(
        row.horasExtras,
      )} h`,
  },
  {
    key: 'atraso',
    label: 'Atraso',
    align: 'right',
    render: (row) =>
      `${numberFormatter.format(
        row.minutosAtraso,
      )} min`,
  },
  {
    key: 'estado',
    label: 'Estado',
    align: 'center',
    render: (row) => (
      <StatusBadge
        label={row.estado}
        tone={
          row.estado === 'PRESENTE'
            ? 'success'
            : row.estado === 'ATRASO'
              ? 'warning'
              : 'danger'
        }
      />
    ),
  },
];

export function AsistenciaPage() {
  const [filters, setFilters] =
    useState<BiFilters>({});

  const [summary, setSummary] =
    useState<AsistenciaResumen | null>(null);

  const [detail, setDetail] =
    useState<AsistenciaDetalleResponse | null>(
      null,
    );

  useEffect(() => {
    let active = true;

    Promise.all([
      asistenciaService.getResumen(filters),
      asistenciaService.getDetalle(filters),
    ]).then(([summaryResult, detailResult]) => {
      if (!active) {
        return;
      }

      setSummary(summaryResult);
      setDetail(detailResult);
    });

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

          <h1>Asistencia</h1>

          <p>
            Horas trabajadas, horas extras,
            atrasos y ausentismo.
          </p>
        </div>
      </div>

      <AsistenciaFilterBar
        filters={filters}
        onChange={setFilters}
      />

      {summary && detail && !hasData ? (
        <AlertCard
          tone="info"
          title="Sin registros de asistencia"
          description="No existen registros de asistencia para la combinación de período, área y trabajador seleccionada."
        />
      ) : null}

      {summary?.calidadDatos?.coberturaParcial ? (
        <div style={{ marginBottom: '18px' }}>
          <AlertCard
          tone="warning"
          title="Cobertura parcial de asistencia"
          description={`Los registros disponibles cubren ${summary.calidadDatos.trabajadoresConAsistencia} de ${summary.calidadDatos.totalTrabajadoresPeriodo} trabajadores (${summary.calidadDatos.porcentajeCobertura?.toLocaleString(
            'es-CL',
            {
              maximumFractionDigits: 1,
            },
          )} %). Los indicadores de asistencia deben interpretarse sobre esta muestra y no como resultados globales de toda la dotación.`}
          />
        </div>
      ) : null}

      {summary && detail && hasData ? (
        <>
          <div className="kpi-grid asistencia-kpi-grid">
            <KpiCard
              title="Horas trabajadas"
              value={`${numberFormatter.format(
                summary.kpis.horasTrabajadas,
              )} h`}
              helper="período seleccionado"
              icon={Clock3}
            />

            <KpiCard
              title="Horas normales"
              value={`${numberFormatter.format(
                summary.kpis.horasNormales,
              )} h`}
              helper="jornada regular"
              icon={Timer}
            />

            <KpiCard
              title="Horas extra"
              value={`${numberFormatter.format(
                summary.kpis.horasExtras,
              )} h`}
              helper="período seleccionado"
              icon={TimerReset}
            />

            <KpiCard
              title="Minutos de atraso"
              value={numberFormatter.format(
                summary.kpis.minutosAtraso,
              )}
              helper="acumulados"
              icon={AlarmClock}
            />

            <KpiCard
              title="Días ausentes"
              value={numberFormatter.format(
                summary.kpis.diasAusentes,
              )}
              helper="registros de ausencia"
              icon={CalendarX2}
            />

            <KpiCard
              title="Ausentismo"
              value={
                summary.kpis.ausentismo === null
                  ? 'Sin datos'
                  : `${summary.kpis.ausentismo.toLocaleString(
                      'es-CL',
                      {
                        maximumFractionDigits: 1,
                      },
                    )} %`
              }
              helper={
                summary.calidadDatos?.datosDisponibles
                  ? 'sobre jornadas observadas'
                  : 'sin datos para el período'
              }
              icon={Gauge}
            />
          </div>

          <div className="dashboard-two-columns">
            <ChartCard
              title="Horas extra por área"
              description="Distribución de horas extra en el período seleccionado."
            >
              <div className="chart-demo">
                <ResponsiveContainer
                  width="100%"
                  height={280}
                >
                  <BarChart
                    data={
                      summary.horasExtrasPorArea
                    }
                    layout="vertical"
                    margin={{
                      left: 40,
                      right: 20,
                    }}
                  >
                    <CartesianGrid
                      strokeDasharray="3 3"
                      horizontal={false}
                    />

                    <XAxis
                      type="number"
                      tickLine={false}
                      axisLine={false}
                    />

                    <YAxis
                      type="category"
                      dataKey="label"
                      width={155}
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
              title="Atrasos por área"
              description="Minutos de atraso acumulados."
            >
              <div className="chart-demo">
                <ResponsiveContainer
                  width="100%"
                  height={280}
                >
                  <BarChart
                    data={summary.atrasosPorArea}
                    layout="vertical"
                    margin={{
                      left: 40,
                      right: 20,
                    }}
                  >
                    <CartesianGrid
                      strokeDasharray="3 3"
                      horizontal={false}
                    />

                    <XAxis
                      type="number"
                      tickLine={false}
                      axisLine={false}
                    />

                    <YAxis
                      type="category"
                      dataKey="label"
                      width={155}
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
            title="Evolución mensual de horas extra"
            description="Horas extra acumuladas por mes."
          >
            <div className="chart-demo">
              <ResponsiveContainer
                width="100%"
                height={280}
              >
                <LineChart
                  data={
                    summary.evolucionHorasExtras
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
            title="Detalle de asistencia"
            description={`Primeros ${detail.items.length} registros de ${detail.pagination.total} eventos filtrados.`}
          >
            <DataTable
              columns={columns}
              rows={detail.items}
              getRowKey={(row) =>
                `${row.trabajadorId}-${row.fecha}`
              }
            />
          </ChartCard>
        </>
      ) : null}
    </section>
  );
}
