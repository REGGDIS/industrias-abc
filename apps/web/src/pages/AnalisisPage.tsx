import {
  useEffect,
  useMemo,
  useState,
} from 'react';
import {
  Banknote,
  Clock3,
  Factory,
  PackageSearch,
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
  analisisService,
} from '../services/analisis.service';
import type {
  AnalisisLaboral,
  AnalisisProduccionConsumo,
  AnalisisResumen,
} from '../types/analisis';

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

const percentFormatter =
  new Intl.NumberFormat('es-CL', {
    maximumFractionDigits: 2,
  });

const monthNames = [
  'Enero',
  'Febrero',
  'Marzo',
  'Abril',
  'Mayo',
  'Junio',
  'Julio',
  'Agosto',
  'Septiembre',
  'Octubre',
  'Noviembre',
  'Diciembre',
];

function formatCurrency(
  value: number,
) {
  return currencyFormatter.format(value);
}

function formatNumber(
  value: number,
) {
  return numberFormatter.format(value);
}

function formatCompactCurrency(
  value: number,
) {
  const abs = Math.abs(value);

  if (abs >= 1_000_000) {
    return `${(
      value / 1_000_000
    ).toLocaleString(
      'es-CL',
      {
        maximumFractionDigits: 1,
      },
    )}M`;
  }

  if (abs >= 1_000) {
    return `${(
      value / 1_000
    ).toLocaleString(
      'es-CL',
      {
        maximumFractionDigits: 1,
      },
    )}K`;
  }

  return value.toLocaleString(
    'es-CL',
  );
}

function formatDate(
  value: string | null,
) {
  if (!value) {
    return 'Sin registros';
  }

  const [year, month, day] =
    value.split('-').map(Number);

  return `${day} ${
    monthNames[month - 1]
  } ${year}`;
}

const laboralColumns:
  DataTableColumn<AnalisisLaboral>[] = [
    {
      key: 'area',
      label: 'Área',
      render: (row) => row.area,
    },
    {
      key: 'empleados',
      label: 'Empleados',
      align: 'right',
      render: (row) =>
        row.empleadosRemunerados,
    },
    {
      key: 'asistencia',
      label: 'HE asistencia',
      align: 'right',
      render: (row) =>
        formatNumber(
          row.horasExtraAsistencia,
        ),
    },
    {
      key: 'remuneradas',
      label: 'HE remuneradas',
      align: 'right',
      render: (row) =>
        formatNumber(
          row.horasExtraRemuneradas,
        ),
    },
    {
      key: 'costo',
      label: 'Costo empresa',
      align: 'right',
      render: (row) =>
        formatCurrency(
          row.costoEmpresa,
        ),
    },
    {
      key: 'cobertura',
      label: 'Cobertura asistencia',
      render: (row) =>
        row.asistenciaDesde
          ? `${formatDate(
              row.asistenciaDesde,
            )} – ${formatDate(
              row.asistenciaHasta,
            )}`
          : 'Sin registros',
    },
  ];

const productionColumns:
  DataTableColumn<AnalisisProduccionConsumo>[] = [
    {
      key: 'orden',
      label: 'Orden',
      render: (row) => row.numeroOrden,
    },
    {
      key: 'producto',
      label: 'Producto',
      render: (row) =>
        `${row.codigoProducto} · ${row.producto}`,
    },
    {
      key: 'plan',
      label: 'Prod. plan',
      align: 'right',
      render: (row) =>
        formatNumber(
          row.produccionPlanificada,
        ),
    },
    {
      key: 'real',
      label: 'Prod. real',
      align: 'right',
      render: (row) =>
        formatNumber(
          row.produccionReal,
        ),
    },
    {
      key: 'consumoPlan',
      label: 'Consumo plan',
      align: 'right',
      render: (row) =>
        formatNumber(
          row.consumoPlanificado,
        ),
    },
    {
      key: 'consumoReal',
      label: 'Consumo real',
      align: 'right',
      render: (row) =>
        formatNumber(
          row.consumoReal,
        ),
    },
    {
      key: 'desviacion',
      label: 'Desviación consumo',
      align: 'right',
      render: (row) =>
        formatNumber(
          row.desviacionConsumo,
        ),
    },
  ];

export function AnalisisPage() {
  const [
    data,
    setData,
  ] = useState<AnalisisResumen | null>(
    null,
  );

  const [
    error,
    setError,
  ] = useState<string | null>(null);

  useEffect(() => {
    let active = true;

    analisisService
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
          'No fue posible cargar el análisis desde la fuente configurada.',
        );
      });

    return () => {
      active = false;
    };
  }, []);

  const laboralChart = useMemo(
    () =>
      data?.laboral.map((item) => ({
        area: item.area,
        asistencia:
          item.horasExtraAsistencia,
        remuneradas:
          item.horasExtraRemuneradas,
      })) ?? [],
    [data],
  );

  const financieroChart = useMemo(
    () =>
      data?.comprasContabilidad.map(
        (item) => ({
          mes: monthNames[
            item.mes - 1
          ],
          compras:
            item.totalCompras,
          debe:
            item.totalDebe,
          haber:
            item.totalHaber,
        }),
      ) ?? [],
    [data],
  );

  return (
    <section className="module-page">
      <div className="page-heading">
        <div>
          <p className="page-eyebrow">
            Inteligencia de negocio
          </p>

          <h1>
            Análisis Integrado
          </h1>

          <p>
            Análisis multidominio basado
            en relaciones y períodos
            efectivamente disponibles
            en el Data Warehouse.
          </p>
        </div>
      </div>

      {error ? (
        <AlertCard
          tone="danger"
          title="Error al cargar análisis"
          description={error}
        />
      ) : null}

      {data ? (
        <>
          <div
            style={{
              marginBottom: '1rem',
            }}
          >
            <AlertCard
              tone="info"
              title="Criterio de integración"
              description={
                'Los dominios se cruzan solo cuando existe compatibilidad temporal y semántica validada. No se suman magnitudes de períodos distintos.'
              }
            />
          </div>

          <div className="kpi-grid">
            <KpiCard
              title="Costo empresa"
              value={formatCurrency(
                data.kpis
                  .costoEmpresaJulio2026,
              )}
              helper="Remuneraciones · Julio 2026"
              icon={Banknote}
            />

            <KpiCard
              title="Horas extra asistencia"
              value={`${formatNumber(
                data.kpis
                  .horasExtraAsistencia,
              )} h`}
              helper="27–29 Julio 2026"
              icon={Clock3}
            />

            <KpiCard
              title="Compras acumuladas"
              value={formatCurrency(
                data.kpis
                  .comprasEneroMayo2025,
              )}
              helper="Enero–Mayo 2025"
              icon={PackageSearch}
            />

            <KpiCard
              title="Cumplimiento producción"
              value={`${percentFormatter.format(
                data.kpis
                  .cumplimientoProduccion,
              )} %`}
              helper="Agosto 2026"
              icon={Factory}
            />
          </div>

          <ChartCard
            title="Análisis laboral · Julio 2026"
            description="Horas extra registradas en Asistencia frente a horas extra consideradas en Remuneraciones. La cobertura temporal no es equivalente."
          >
            <div className="chart-demo analisis-cost-chart">
              <ResponsiveContainer
                width="100%"
                height="100%"
              >
                <BarChart
                  data={laboralChart}
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
                    dataKey="area"
                    interval={0}
                    height={75}
                    angle={-18}
                    textAnchor="end"
                  />

                  <YAxis />

                  <Tooltip />

                  <Legend />

                  <Bar
                    dataKey="asistencia"
                    name="HE Asistencia"
                    fill="#1f4e78"
                    radius={[5, 5, 0, 0]}
                  />

                  <Bar
                    dataKey="remuneradas"
                    name="HE Remuneraciones"
                    fill="#6c8ebf"
                    radius={[5, 5, 0, 0]}
                  />
                </BarChart>
              </ResponsiveContainer>
            </div>
          </ChartCard>

          <ChartCard
            title="Detalle laboral por área"
            description="Finanzas y Contabilidad no presenta registros de Asistencia en la cobertura disponible, pero sí datos mensuales de Remuneraciones."
          >
            <DataTable
              columns={laboralColumns}
              rows={data.laboral}
              getRowKey={(row) =>
                row.areaId
              }
            />
          </ChartCard>

          <ChartCard
            title="Compras y Contabilidad · Enero–Mayo 2025"
            description="Series paralelas de Compras, Debe y Haber. No representan una suma de costos ni se interpreta el Debe como gasto."
          >
            <div className="chart-demo analisis-cost-chart">
              <ResponsiveContainer
                width="100%"
                height="100%"
              >
                <BarChart
                  data={financieroChart}
                  margin={{
                    top: 16,
                    right: 24,
                    left: 30,
                    bottom: 20,
                  }}
                >
                  <CartesianGrid
                    strokeDasharray="3 3"
                    vertical={false}
                  />

                  <XAxis
                    dataKey="mes"
                  />

                  <YAxis
                    tickFormatter={(value) =>
                      formatCompactCurrency(
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

                  <Legend />

                  <Bar
                    dataKey="compras"
                    name="Compras"
                    fill="#1f4e78"
                  />

                  <Bar
                    dataKey="debe"
                    name="Debe"
                    fill="#6c8ebf"
                  />

                  <Bar
                    dataKey="haber"
                    name="Haber"
                    fill="#70ad47"
                  />
                </BarChart>
              </ResponsiveContainer>
            </div>
          </ChartCard>

          <ChartCard
            title="Producción y consumo · Agosto 2026"
            description="Cruce validado por número de orden y producto. No utiliza Área ni Centro de costo."
          >
            <DataTable
              columns={productionColumns}
              rows={
                data.produccionConsumo
              }
              getRowKey={(row) =>
                row.numeroOrden
              }
            />
          </ChartCard>

          <div
            style={{
              marginTop: '1rem',
            }}
          >
            <AlertCard
              tone={
                data
                  .calidadCruceProduccion
                  .cruceValido
                  ? 'success'
                  : 'warning'
              }
              title="Integridad Producción–Consumo"
              description={
                data
                  .calidadCruceProduccion
                  .cruceValido
                  ? 'Todas las líneas de consumo encuentran una orden de producción asociada mediante número de orden y producto.'
                  : `${data.calidadCruceProduccion.consumosHuerfanos} líneas de consumo no tienen una orden de producción asociada.`
              }
            />
          </div>

          <div
            style={{
              marginTop: '1rem',
            }}
          >
            <AlertCard
              tone="warning"
              title="Consideraciones del análisis"
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
