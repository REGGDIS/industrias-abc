import {
  useEffect,
  useState,
} from 'react';
import {
  CalendarClock,
  CalendarX2,
  FileCheck2,
  FileClock,
  FileText,
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
import { ContratosFilterBar } from '../components/filters/ContratosFilterBar';
import { KpiCard } from '../components/kpi/KpiCard';
import {
  DataTable,
  type DataTableColumn,
} from '../components/tables/DataTable';
import { contratosMockService } from '../services/mock/contratos.mock.service';
import type {
  ContratoDetalle,
  ContratosDetalleResponse,
  ContratosResumen,
} from '../types/contratos';
import type { BiFilters } from '../types/filters';

const numberFormatter =
  new Intl.NumberFormat('es-CL');

function formatDate(value?: string) {
  if (!value) {
    return 'Sin término';
  }

  return new Intl.DateTimeFormat(
    'es-CL',
  ).format(
    new Date(`${value}T00:00:00`),
  );
}

const columns: DataTableColumn<ContratoDetalle>[] = [
  {
    key: 'empleado',
    label: 'Trabajador',
    render: (row) => row.empleado,
  },
  {
    key: 'tipo',
    label: 'Tipo contrato',
    render: (row) =>
      row.tipoContrato.replaceAll('_', ' '),
  },
  {
    key: 'inicio',
    label: 'Inicio',
    render: (row) =>
      formatDate(row.fechaInicio),
  },
  {
    key: 'termino',
    label: 'Término',
    render: (row) =>
      formatDate(row.fechaTermino),
  },
  {
    key: 'dias',
    label: 'Días restantes',
    align: 'right',
    render: (row) =>
      row.diasRestantes === undefined
        ? '—'
        : numberFormatter.format(
            row.diasRestantes,
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
          row.estado === 'VIGENTE'
            ? 'success'
            : 'danger'
        }
      />
    ),
  },
];

export function ContratosPage() {
  const [filters, setFilters] =
    useState<BiFilters>({
      anio: 2026,
    });

  const [summary, setSummary] =
    useState<ContratosResumen | null>(null);

  const [detail, setDetail] =
    useState<ContratosDetalleResponse | null>(
      null,
    );

  useEffect(() => {
    let active = true;

    Promise.all([
      contratosMockService.getResumen(filters),
      contratosMockService.getDetalle(filters),
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

          <h1>Contratos</h1>

          <p>
            Contratos vigentes, tipos,
            vencimientos y próximos términos.
          </p>
        </div>
      </div>

      <ContratosFilterBar
        filters={filters}
        onChange={setFilters}
      />

      {summary && detail && !hasData ? (
        <AlertCard
          tone="info"
          title="Sin contratos para los filtros seleccionados"
          description="No existen contratos mock para esta combinación de período, área y trabajador."
        />
      ) : null}

      {summary && detail && hasData ? (
        <>
          <div className="kpi-grid contratos-kpi-grid">
            <KpiCard
              title="Contratos vigentes"
              value={summary.kpis.vigentes}
              helper="al cierre del período"
              icon={FileCheck2}
            />

            <KpiCard
              title="Indefinidos"
              value={summary.kpis.indefinidos}
              helper="contratos vigentes"
              icon={FileText}
            />

            <KpiCard
              title="Plazo fijo"
              value={summary.kpis.plazoFijo}
              helper="contratos vigentes"
              icon={FileClock}
            />

            <KpiCard
              title="Temporales"
              value={summary.kpis.temporales}
              helper="contratos vigentes"
              icon={TimerReset}
            />

            <KpiCard
              title="Próximos a vencer"
              value={
                summary.kpis.proximosVencer
              }
              helper="próximos 90 días"
              icon={CalendarClock}
            />

            <KpiCard
              title="Vencidos"
              value={summary.kpis.vencidos}
              helper="al cierre del período"
              icon={CalendarX2}
            />
          </div>

          <div className="dashboard-two-columns">
            <ChartCard
              title="Contratos por tipo"
              description="Distribución de contratos vigentes."
            >
              <div className="chart-demo">
                <ResponsiveContainer
                  width="100%"
                  height={280}
                >
                  <BarChart
                    data={summary.contratosPorTipo}
                  >
                    <CartesianGrid
                      strokeDasharray="3 3"
                      vertical={false}
                    />

                    <XAxis
                      dataKey="label"
                      tickFormatter={(value) =>
                        String(value).replaceAll(
                          '_',
                          ' ',
                        )
                      }
                      tickLine={false}
                      axisLine={false}
                    />

                    <YAxis
                      allowDecimals={false}
                      tickLine={false}
                      axisLine={false}
                    />

                    <Tooltip />

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
              title="Vencimientos por mes"
              description="Contratos con fecha de término en el año seleccionado."
            >
              <div className="chart-demo">
                <ResponsiveContainer
                  width="100%"
                  height={280}
                >
                  <LineChart
                    data={
                      summary.vencimientosPorMes
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
          </div>

          <ChartCard
            title="Detalle de contratos"
            description={`Primeros ${detail.items.length} registros de ${detail.pagination.total} contratos filtrados.`}
          >
            <DataTable
              columns={columns}
              rows={detail.items}
              getRowKey={(row) =>
                row.contratoId
              }
            />
          </ChartCard>
        </>
      ) : null}
    </section>
  );
}
