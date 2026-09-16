import {
  useEffect,
  useMemo,
  useState,
} from 'react';
import {
  Activity,
  AlertTriangle,
  DatabaseZap,
  ListChecks,
} from 'lucide-react';
import {
  Bar,
  BarChart,
  CartesianGrid,
  Legend,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts';

import {
  ChartCard,
} from '../components/charts/ChartCard';
import {
  AlertCard,
} from '../components/feedback/AlertCard';
import {
  KpiCard,
} from '../components/kpi/KpiCard';
import {
  DataTable,
  type DataTableColumn,
} from '../components/tables/DataTable';
import {
  etlService,
} from '../services/etl.service';
import type {
  EtlEjecucion,
  EtlResumen,
  EtlStatus,
} from '../types/etl';

const numberFormatter =
  new Intl.NumberFormat('es-CL');

function sourceLabel(
  source: string,
) {
  const labels:
    Record<string, string> = {
      RRHH: 'RRHH',
      PRODUCCION: 'Producción',
      COMPRAS: 'Compras',
      CONTABILIDAD: 'Contabilidad',
      ASISTENCIA: 'Asistencia',
      CONTRATOS_REMUNERACIONES:
        'Contratos / Remuneraciones',
    };

  return labels[source] ?? source;
}

function formatDateTime(
  value: string | null,
) {
  if (!value) {
    return 'En ejecución';
  }

  const date = new Date(value);

  return new Intl.DateTimeFormat(
    'es-CL',
    {
      dateStyle: 'short',
      timeStyle: 'medium',
    },
  ).format(date);
}

function statusStyle(
  status: EtlStatus,
) {
  switch (status) {
    case 'SUCCESS':
      return {
        background: '#e8f5e9',
        color: '#2e7d32',
        border: '1px solid #a5d6a7',
      };
    case 'PARTIAL':
      return {
        background: '#fff8e1',
        color: '#8d6e00',
        border: '1px solid #ffe082',
      };
    case 'ERROR':
      return {
        background: '#fdecea',
        color: '#b3261e',
        border: '1px solid #ef9a9a',
      };
    case 'RUNNING':
      return {
        background: '#eaf2f8',
        color: '#1f4e78',
        border: '1px solid #90caf9',
      };
  }
}

function StatusBadge({
  status,
}: {
  status: EtlStatus;
}) {
  return (
    <span
      style={{
        ...statusStyle(status),
        display: 'inline-flex',
        alignItems: 'center',
        borderRadius: '999px',
        padding: '0.25rem 0.6rem',
        fontSize: '0.75rem',
        fontWeight: 700,
        whiteSpace: 'nowrap',
      }}
    >
      {status}
    </span>
  );
}

const latestColumns:
  DataTableColumn<EtlEjecucion>[] = [
    {
      key: 'source',
      label: 'Fuente',
      render: (row) =>
        sourceLabel(row.source),
    },
    {
      key: 'status',
      label: 'Estado',
      render: (row) => (
        <StatusBadge
          status={row.status}
        />
      ),
    },
    {
      key: 'startedAt',
      label: 'Última ejecución',
      render: (row) =>
        formatDateTime(
          row.startedAt,
        ),
    },
    {
      key: 'duracion',
      label: 'Duración',
      align: 'right',
      render: (row) =>
        row.duracionSegundos === null
          ? '—'
          : `${row.duracionSegundos.toLocaleString(
              'es-CL',
              {
                maximumFractionDigits: 3,
              },
            )} s`,
    },
    {
      key: 'read',
      label: 'Leídos',
      align: 'right',
      render: (row) =>
        numberFormatter.format(
          row.recordsRead,
        ),
    },
    {
      key: 'valid',
      label: 'Válidos',
      align: 'right',
      render: (row) =>
        numberFormatter.format(
          row.recordsValid,
        ),
    },
    {
      key: 'rejected',
      label: 'Rechazados',
      align: 'right',
      render: (row) =>
        numberFormatter.format(
          row.recordsRejected,
        ),
    },
    {
      key: 'review',
      label: 'Review',
      align: 'right',
      render: (row) =>
        numberFormatter.format(
          row.recordsReview,
        ),
    },
  ];

const historyColumns:
  DataTableColumn<EtlEjecucion>[] = [
    {
      key: 'id',
      label: 'ID',
      align: 'right',
      render: (row) =>
        row.executionId,
    },
    {
      key: 'source',
      label: 'Fuente',
      render: (row) =>
        sourceLabel(row.source),
    },
    {
      key: 'startedAt',
      label: 'Inicio',
      render: (row) =>
        formatDateTime(
          row.startedAt,
        ),
    },
    {
      key: 'status',
      label: 'Estado',
      render: (row) => (
        <StatusBadge
          status={row.status}
        />
      ),
    },
    {
      key: 'read',
      label: 'Leídos',
      align: 'right',
      render: (row) =>
        numberFormatter.format(
          row.recordsRead,
        ),
    },
    {
      key: 'inserted',
      label: 'Insertados',
      align: 'right',
      render: (row) =>
        numberFormatter.format(
          row.recordsInserted,
        ),
    },
    {
      key: 'unchanged',
      label: 'Sin cambios',
      align: 'right',
      render: (row) =>
        numberFormatter.format(
          row.recordsUnchanged,
        ),
    },
    {
      key: 'review',
      label: 'Review',
      align: 'right',
      render: (row) =>
        numberFormatter.format(
          row.recordsReview,
        ),
    },
  ];

export function EtlPage() {
  const [
    data,
    setData,
  ] = useState<EtlResumen | null>(
    null,
  );

  const [
    error,
    setError,
  ] = useState<string | null>(null);

  useEffect(() => {
    let active = true;

    etlService
      .getResumen()
      .then((result) => {
        if (!active) {
          return;
        }

        setData(result);
        setError(null);
      })
      .catch(() => {
        if (!active) {
          return;
        }

        setError(
          'No fue posible cargar la auditoría ETL desde la fuente configurada.',
        );
      });

    return () => {
      active = false;
    };
  }, []);

  const chartData = useMemo(
    () =>
      data?.ultimasEjecuciones.map(
        (row) => ({
          source:
            sourceLabel(row.source),
          review:
            row.recordsReview,
          rejected:
            row.recordsRejected,
        }),
      ) ?? [],
    [data],
  );

  const visibleHistory = useMemo(
    () =>
      data?.historial.slice(
        0,
        12,
      ) ?? [],
    [data],
  );

  return (
    <section className="module-page">
      <div className="page-heading">
        <div>
          <p className="page-eyebrow">
            Operación BI
          </p>

          <h1>
            Monitoreo ETL
          </h1>

          <p>
            Seguimiento real de
            ejecuciones, estados,
            registros procesados y
            observaciones del pipeline
            hacia el Data Warehouse.
          </p>
        </div>
      </div>

      {error ? (
        <AlertCard
          tone="danger"
          title="Error al cargar ETL"
          description={error}
        />
      ) : null}

      {data ? (
        <>
          <div className="kpi-grid">
            <KpiCard
              title="Procesos monitoreados"
              value={numberFormatter.format(
                data.kpis
                  .procesosMonitoreados,
              )}
              helper="Pipelines DW"
              icon={DatabaseZap}
            />

            <KpiCard
              title="Ejecuciones OK"
              value={`${data.kpis.success}/${data.kpis.procesosMonitoreados}`}
              helper={`${data.kpis.partial} parciales · ${data.kpis.error} error`}
              icon={ListChecks}
            />

            <KpiCard
              title="Registros leídos"
              value={numberFormatter.format(
                data.kpis
                  .registrosLeidos,
              )}
              helper="Última ejecución por proceso"
              icon={Activity}
            />

            <KpiCard
              title="Registros REVIEW"
              value={numberFormatter.format(
                data.kpis
                  .registrosReview,
              )}
              helper={`${data.kpis.registrosRechazados} rechazados`}
              icon={AlertTriangle}
            />
          </div>

          {data.kpis.partial > 0 ? (
            <div
              style={{
                marginBottom: '1rem',
              }}
            >
              <AlertCard
                tone="warning"
                title="Procesos con revisión pendiente"
                description={`${data.kpis.partial} de ${data.kpis.procesosMonitoreados} procesos presentan estado PARTIAL en su última ejecución. El estado refleja registros enviados a REVIEW, no un fallo completo del ETL.`}
              />
            </div>
          ) : null}

          <ChartCard
            title="Última ejecución por proceso"
            description="Estado operacional y métricas de la ejecución más reciente de cada pipeline del Data Warehouse."
          >
            <DataTable
              columns={latestColumns}
              rows={
                data.ultimasEjecuciones
              }
              getRowKey={(row) =>
                row.process
              }
            />
          </ChartCard>

          <ChartCard
            title="Registros REVIEW y rechazados"
            description="Incidencias detectadas en la última ejecución de cada proceso. REVIEW requiere análisis; rechazado corresponde a registros descartados."
          >
            <div className="chart-demo analisis-cost-chart">
              <ResponsiveContainer
                width="100%"
                height="100%"
              >
                <BarChart
                  data={chartData}
                  margin={{
                    top: 16,
                    right: 24,
                    left: 12,
                    bottom: 65,
                  }}
                >
                  <CartesianGrid
                    strokeDasharray="3 3"
                    vertical={false}
                  />

                  <XAxis
                    dataKey="source"
                    interval={0}
                    height={85}
                    angle={-18}
                    textAnchor="end"
                  />

                  <YAxis
                    allowDecimals={false}
                  />

                  <Tooltip />

                  <Legend />

                  <Bar
                    dataKey="review"
                    name="REVIEW"
                    fill="#e6a700"
                  />

                  <Bar
                    dataKey="rejected"
                    name="Rechazados"
                    fill="#c0504d"
                  />
                </BarChart>
              </ResponsiveContainer>
            </div>
          </ChartCard>

          <ChartCard
            title="Historial reciente"
            description="Últimas ejecuciones registradas de los seis procesos que alimentan el Data Warehouse."
          >
            <DataTable
              columns={historyColumns}
              rows={visibleHistory}
              getRowKey={(row) =>
                row.executionId
              }
            />
          </ChartCard>

          <div
            style={{
              marginTop: '1rem',
            }}
          >
            <AlertCard
              tone="info"
              title="Alcance del monitoreo"
              description={
                data.advertencias.join(
                  ' · ',
                )
              }
            />
          </div>
        </>
      ) : null}
    </section>
  );
}
