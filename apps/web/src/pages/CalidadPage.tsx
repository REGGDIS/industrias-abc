import {
  useEffect,
  useMemo,
  useState,
} from 'react';
import {
  AlertTriangle,
  CheckCircle2,
  Database,
  ShieldCheck,
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
  calidadService,
} from '../services/calidad.service';
import type {
  CalidadDominio,
  CalidadEvaluacionEspecial,
  CalidadRegla,
  CalidadResumen,
  CalidadEstado,
} from '../types/calidad';

const numberFormatter =
  new Intl.NumberFormat('es-CL');

const percentFormatter =
  new Intl.NumberFormat('es-CL', {
    maximumFractionDigits: 2,
  });

function estadoStyle(
  estado: CalidadEstado,
) {
  switch (estado) {
    case 'OK':
      return {
        background: '#e8f5e9',
        color: '#2e7d32',
        border: '1px solid #a5d6a7',
      };
    case 'INCIDENCIA':
      return {
        background: '#fdecea',
        color: '#b3261e',
        border: '1px solid #ef9a9a',
      };
    case 'ADVERTENCIA':
      return {
        background: '#fff8e1',
        color: '#8d6e00',
        border: '1px solid #ffe082',
      };
    case 'NO_EVALUABLE':
      return {
        background: '#eaf2f8',
        color: '#1f4e78',
        border: '1px solid #90caf9',
      };
  }
}

function EstadoBadge({
  estado,
}: {
  estado: CalidadEstado;
}) {
  return (
    <span
      style={{
        ...estadoStyle(estado),
        display: 'inline-flex',
        alignItems: 'center',
        borderRadius: '999px',
        padding: '0.25rem 0.6rem',
        fontSize: '0.75rem',
        fontWeight: 700,
        whiteSpace: 'nowrap',
      }}
    >
      {estado.replaceAll('_', ' ')}
    </span>
  );
}

function labelDominio(
  value: string,
) {
  return value
    .replaceAll('_', ' ')
    .replace(
      /\b\w/g,
      (char) => char.toUpperCase(),
    );
}

const dominioColumns:
  DataTableColumn<CalidadDominio>[] = [
    {
      key: 'dominio',
      label: 'Dominio',
      render: (row) =>
        labelDominio(row.dominio),
    },
    {
      key: 'registros',
      label: 'Registros',
      align: 'right',
      render: (row) =>
        numberFormatter.format(
          row.registros,
        ),
    },
    {
      key: 'incidencias',
      label: 'Con incidencia',
      align: 'right',
      render: (row) =>
        numberFormatter.format(
          row.registrosConIncidencia,
        ),
    },
    {
      key: 'porcentaje',
      label: 'Sin incidencia',
      align: 'right',
      render: (row) =>
        `${percentFormatter.format(
          row.porcentajeSinIncidencia,
        )} %`,
    },
    {
      key: 'area',
      label: 'Área desconocida',
      align: 'right',
      render: (row) =>
        numberFormatter.format(
          row.areaDesconocida,
        ),
    },
    {
      key: 'cc',
      label: 'CC desconocido',
      align: 'right',
      render: (row) =>
        numberFormatter.format(
          row.centroCostoDesconocido,
        ),
    },
    {
      key: 'estado',
      label: 'Estado',
      render: (row) => (
        <EstadoBadge
          estado={row.estado}
        />
      ),
    },
  ];

const reglaColumns:
  DataTableColumn<CalidadRegla>[] = [
    {
      key: 'nombre',
      label: 'Control',
      render: (row) => row.nombre,
    },
    {
      key: 'incidencias',
      label: 'Incidencias',
      align: 'right',
      render: (row) =>
        numberFormatter.format(
          row.incidencias,
        ),
    },
    {
      key: 'estado',
      label: 'Estado',
      render: (row) => (
        <EstadoBadge
          estado={row.estado}
        />
      ),
    },
  ];

const evaluacionColumns:
  DataTableColumn<CalidadEvaluacionEspecial>[] = [
    {
      key: 'nombre',
      label: 'Evaluación',
      render: (row) => row.nombre,
    },
    {
      key: 'estado',
      label: 'Estado',
      render: (row) => (
        <EstadoBadge
          estado={row.estado}
        />
      ),
    },
    {
      key: 'detalle',
      label: 'Detalle',
      render: (row) => row.detalle,
    },
  ];

export function CalidadPage() {
  const [
    data,
    setData,
  ] = useState<CalidadResumen | null>(
    null,
  );

  const [
    error,
    setError,
  ] = useState<string | null>(null);

  useEffect(() => {
    let active = true;

    calidadService
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
          'No fue posible cargar los controles de calidad desde la fuente configurada.',
        );
      });

    return () => {
      active = false;
    };
  }, []);

  const dominioChart = useMemo(
    () =>
      data?.dominios.map((item) => ({
        dominio: labelDominio(
          item.dominio,
        ),
        sinIncidencia:
          item.registrosSinIncidencia,
        conIncidencia:
          item.registrosConIncidencia,
      })) ?? [],
    [data],
  );

  return (
    <section className="module-page">
      <div className="page-heading">
        <div>
          <p className="page-eyebrow">
            Gobierno de datos
          </p>

          <h1>
            Calidad de Datos
          </h1>

          <p>
            Controles reales sobre
            homologación, completitud,
            integridad y consistencia del
            Data Warehouse.
          </p>
        </div>
      </div>

      {error ? (
        <AlertCard
          tone="danger"
          title="Error al cargar calidad"
          description={error}
        />
      ) : null}

      {data ? (
        <>
          <div className="kpi-grid">
            <KpiCard
              title="Registros evaluados"
              value={numberFormatter.format(
                data.kpis
                  .registrosEvaluados,
              )}
              helper="Hechos auditados en el DW"
              icon={Database}
            />

            <KpiCard
              title="Sin incidencia"
              value={`${percentFormatter.format(
                data.kpis
                  .porcentajeSinIncidencia,
              )} %`}
              helper={`${data.kpis.registrosSinIncidencia} de ${data.kpis.registrosEvaluados} registros`}
              icon={ShieldCheck}
            />

            <KpiCard
              title="Con incidencia"
              value={numberFormatter.format(
                data.kpis
                  .registrosConIncidencia,
              )}
              helper="Según controles implementados"
              icon={AlertTriangle}
            />

            <KpiCard
              title="Reglas consistentes"
              value={`${data.kpis.reglasConsistenciaOk}/${data.kpis.reglasConsistenciaTotal}`}
              helper="Reglas sin incidencias"
              icon={CheckCircle2}
            />
          </div>

          <ChartCard
            title="Calidad por dominio"
            description="Registros con y sin incidencias según las claves y reglas actualmente auditadas."
          >
            <div className="chart-demo analisis-cost-chart">
              <ResponsiveContainer
                width="100%"
                height="100%"
              >
                <BarChart
                  data={dominioChart}
                  margin={{
                    top: 16,
                    right: 24,
                    left: 12,
                    bottom: 55,
                  }}
                >
                  <CartesianGrid
                    strokeDasharray="3 3"
                    vertical={false}
                  />

                  <XAxis
                    dataKey="dominio"
                    interval={0}
                    height={75}
                    angle={-18}
                    textAnchor="end"
                  />

                  <YAxis />

                  <Tooltip />

                  <Legend />

                  <Bar
                    dataKey="sinIncidencia"
                    name="Sin incidencia"
                    stackId="calidad"
                    fill="#70ad47"
                  />

                  <Bar
                    dataKey="conIncidencia"
                    name="Con incidencia"
                    stackId="calidad"
                    fill="#c0504d"
                  />
                </BarChart>
              </ResponsiveContainer>
            </div>
          </ChartCard>

          <ChartCard
            title="Detalle por dominio"
            description="La incidencia se calcula por registro para evitar duplicar un mismo hecho con varias claves desconocidas."
          >
            <DataTable
              columns={dominioColumns}
              rows={data.dominios}
              getRowKey={(row) =>
                row.dominio
              }
            />
          </ChartCard>

          <ChartCard
            title="Reglas de consistencia"
            description="Validaciones de cantidades, montos y relaciones entre hechos que pueden evaluarse con el modelo actual."
          >
            <DataTable
              columns={reglaColumns}
              rows={data.reglas}
              getRowKey={(row) =>
                row.codigo
              }
            />
          </ChartCard>

          <ChartCard
            title="Controles de completitud"
            description="Campos críticos de negocio revisados en los hechos principales."
          >
            <DataTable
              columns={reglaColumns}
              rows={data.completitud}
              getRowKey={(row) =>
                row.codigo
              }
            />
          </ChartCard>

          <ChartCard
            title="Evaluaciones especiales"
            description="Controles que requieren contexto adicional o presentan limitaciones estructurales conocidas."
          >
            <DataTable
              columns={evaluacionColumns}
              rows={
                data.evaluacionesEspeciales
              }
              getRowKey={(row) =>
                row.codigo
              }
            />
          </ChartCard>

          <div
            style={{
              marginTop: '1rem',
            }}
          >
            <AlertCard
              tone="warning"
              title="Alcance de los controles"
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
