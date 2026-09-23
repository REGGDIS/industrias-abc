import {
  useEffect,
  useState,
} from 'react';

import {
  Activity,
  Banknote,
  Boxes,
  Clock3,
  Factory,
  ReceiptText,
  ShoppingCart,
  Users,
} from 'lucide-react';

import { ChartCard } from '../components/charts/ChartCard';
import { AlertCard } from '../components/feedback/AlertCard';
import { KpiCard } from '../components/kpi/KpiCard';
import {
  DataTable,
  type DataTableColumn,
} from '../components/tables/DataTable';

import { dashboardService } from '../services/dashboard.service';

import type {
  DashboardCobertura,
  DashboardPeriodoMes,
  DashboardResumen,
} from '../types/dashboard';

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

const numberFormatter =
  new Intl.NumberFormat('es-CL');

const decimalFormatter =
  new Intl.NumberFormat(
    'es-CL',
    {
      maximumFractionDigits: 2,
    },
  );

const moneyFormatter =
  new Intl.NumberFormat(
    'es-CL',
    {
      style: 'currency',
      currency: 'CLP',
      maximumFractionDigits: 0,
    },
  );


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


function formatMoney(
  value: number,
) {
  return moneyFormatter.format(value);
}


function formatDate(
  value: string | null,
) {
  if (!value) {
    return 'Sin dato';
  }

  const parts = value
    .split('-')
    .map(Number);

  if (parts.length !== 3) {
    return value;
  }

  const [year, month, day] = parts;

  return `${day} ${
    monthNames[month - 1] ?? month
  } ${year}`;
}


function formatMonth(
  period: DashboardPeriodoMes | null,
) {
  if (!period) {
    return 'Sin dato';
  }

  return `${
    monthNames[period.mes - 1]
      ?? period.mes
  } ${period.anio}`;
}


function domainLabel(
  domain: string,
) {
  const labels:
    Record<string, string> = {
      ASISTENCIA: 'Asistencia',
      COMPRAS: 'Compras',
      CONSUMO_INSUMO:
        'Consumo de insumos',
      CONTABILIDAD:
        'Contabilidad',
      PRODUCCION:
        'Producción',
      REMUNERACIONES:
        'Remuneraciones',
    };

  return labels[domain] ?? domain;
}


const coverageColumns:
  DataTableColumn<DashboardCobertura>[] = [
    {
      key: 'dominio',
      label: 'Dominio',
      render: (row) =>
        domainLabel(row.dominio),
    },
    {
      key: 'fechaDesde',
      label: 'Desde',
      render: (row) => {
        if (
          row.dominio === 'REMUNERACIONES'
          && row.fechaDesde
        ) {
          const [
            year,
            month,
          ] = row.fechaDesde
            .split('-')
            .map(Number);

          return `${
            monthNames[month - 1]
              ?? month
          } ${year}`;
        }

        return formatDate(
          row.fechaDesde,
        );
      },
    },
    {
      key: 'fechaHasta',
      label: 'Hasta',
      render: (row) => {
        if (
          row.dominio === 'REMUNERACIONES'
          && row.fechaHasta
        ) {
          const [
            year,
            month,
          ] = row.fechaHasta
            .split('-')
            .map(Number);

          return `${
            monthNames[month - 1]
              ?? month
          } ${year}`;
        }

        return formatDate(
          row.fechaHasta,
        );
      },
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
  ];


export function DashboardPage() {
  const [
    data,
    setData,
  ] = useState<
    DashboardResumen | null
  >(null);

  const [
    error,
    setError,
  ] = useState<string | null>(
    null,
  );

  useEffect(() => {
    let active = true;

    dashboardService
      .getResumen()
      .then((result) => {
        if (active) {
          setData(result);
        }
      })
      .catch((caughtError) => {
        if (!active) {
          return;
        }

        setError(
          caughtError instanceof Error
            ? caughtError.message
            : (
                'No fue posible cargar '
                + 'el Dashboard.'
              ),
        );
      });

    return () => {
      active = false;
    };
  }, []);


  return (
    <section className="module-page">
      <div className="page-heading">
        <div>
          <p className="page-eyebrow">
            Industrias ABC
          </p>

          <h1>
            Dashboard Ejecutivo
          </h1>

          <p>
            Visión ejecutiva de los
            principales indicadores
            disponibles en el Data
            Warehouse.
          </p>
        </div>
      </div>


      {error ? (
        <AlertCard
          tone="danger"
          title="No fue posible cargar el Dashboard"
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
              title="Períodos de información"
              description={
                'Cada indicador utiliza '
                + 'el último período real '
                + 'disponible de su dominio. '
                + 'Los KPI no representan '
                + 'un único corte temporal.'
              }
            />
          </div>


          <div className="kpi-grid">
            <KpiCard
              title="Total de trabajadores"
              value={
                numberFormatter.format(
                  data.kpis.totalTrabajadores,
                )
              }
              helper={
                'RRHH · '
                + formatDate(
                  data.periodos.rrhh,
                )
              }
              icon={Users}
            />

            <KpiCard
              title="Horas extra"
              value={
                `${decimalFormatter.format(
                  data.kpis
                    .horasExtrasAsistencia,
                )} h`
              }
              helper={
                'Asistencia · '
                + formatDate(
                  data.periodos
                    .asistencia,
                )
              }
              icon={Clock3}
            />


            <KpiCard
              title="Costo remuneraciones"
              value={
                formatMoney(
                  data.kpis
                    .costoRemuneraciones,
                )
              }
              helper={
                'Último período · '
                + (
                  data.periodos.remuneraciones
                    ? `${
                        monthNames[
                          Number(
                            data.periodos.remuneraciones
                              .split('-')[1],
                          ) - 1
                        ]
                      } ${
                        data.periodos.remuneraciones
                          .split('-')[0]
                      }`
                    : 'Sin dato'
                )
              }
              icon={Banknote}
            />

            <KpiCard
              title="Costo horas extra"
              value={
                formatMoney(
                  data.kpis.costoHorasExtra,
                )
              }
              helper={
                'Remuneraciones · '
                + (
                  data.periodos.remuneraciones
                    ? `${
                        monthNames[
                          Number(
                            data.periodos.remuneraciones
                              .split('-')[1],
                          ) - 1
                        ]
                      } ${
                        data.periodos.remuneraciones
                          .split('-')[0]
                      }`
                    : 'Sin dato'
                )
              }
              icon={Banknote}
            />

            <KpiCard
              title="Compras"
              value={
                formatMoney(
                  data.kpis
                    .totalCompras,
                )
              }
              helper={
                'Último mes · '
                + formatMonth(
                  data.periodos.compras,
                )
              }
              icon={ShoppingCart}
            />


            <KpiCard
              title="Movimientos contables"
              value={
                numberFormatter.format(
                  data.kpis
                    .movimientosContables,
                )
              }
              helper={
                'Último mes · '
                + formatMonth(
                  data.periodos
                    .contabilidad,
                )
              }
              icon={ReceiptText}
            />


            <KpiCard
              title="Producción real"
              value={
                numberFormatter.format(
                  data.kpis
                    .produccionReal,
                )
              }
              helper={
                'Último mes · '
                + formatMonth(
                  data.periodos
                    .produccion,
                )
              }
              icon={Factory}
            />


            <KpiCard
              title="Cumplimiento producción"
              value={
                `${decimalFormatter.format(
                  data.kpis
                    .cumplimientoProduccion,
                )} %`
              }
              helper="Producido versus planificado"
              icon={Activity}
            />

            <KpiCard
              title="Órdenes de producción"
              value={
                numberFormatter.format(
                  data.kpis
                    .ordenesProduccion,
                )
              }
              helper={
                'Último mes · '
                + formatMonth(
                  data.periodos
                    .produccion,
                )
              }
              icon={Boxes}
            />

            <KpiCard
              title="Tasa de rechazo"
              value={
                `${data.kpis.tasaRechazoProduccion.toLocaleString(
                  'es-CL',
                  {
                    minimumFractionDigits: 2,
                    maximumFractionDigits: 2,
                  },
                )} %`
              }
              helper={
                'Último mes · '
                + formatMonth(
                  data.periodos
                    .produccion,
                )
              }
              icon={Activity}
            />
          </div>

          <ChartCard
            title="Principales centros de costo"
            description={
              `Gastos contables acumulados · ${
                data.periodoCentrosCosto
                  ?? 'Sin período'
              }`
            }
          >
            <div className="chart-demo">
              <ResponsiveContainer
                width="100%"
                height={280}
              >
                <BarChart
                  data={
                    data.principalesCentrosCosto
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
                      formatMoney(
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
                      formatMoney(
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
            title="Evolución mensual de gastos"
            description={
              `Gastos contables por mes · ${
                data.evolucionMensual[0]?.anio
                  ?? 'Sin período'
              }`
            }
          >
            <div className="chart-demo">
              <ResponsiveContainer
                width="100%"
                height={280}
              >
                <LineChart
                  data={data.evolucionMensual}
                  margin={{
                    left: 45,
                    right: 25,
                    top: 10,
                  }}
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
                    width={95}
                    tickFormatter={(value) =>
                      formatMoney(
                        Number(value),
                      )
                    }
                  />

                  <Tooltip
                    formatter={(value) =>
                      formatMoney(
                        Number(value),
                      )
                    }
                  />

                  <Line
                    type="monotone"
                    dataKey="value"
                    stroke="var(--primary)"
                    strokeWidth={3}
                    dot={{ r: 4 }}
                    activeDot={{ r: 6 }}
                  />
                </LineChart>
              </ResponsiveContainer>
            </div>
          </ChartCard>

          <ChartCard
            title="Cobertura de datos por dominio"
            description={
              'Rango temporal y cantidad '
              + 'de registros actualmente '
              + 'disponibles en el DW.'
            }
          >
            <DataTable
              columns={coverageColumns}
              rows={data.cobertura}
              getRowKey={(row) =>
                row.dominio
              }
            />
          </ChartCard>


          {data.advertencias.length > 0 ? (
            <AlertCard
              tone="warning"
              title="Consideraciones del Dashboard"
              description={
                data.advertencias.join(
                  ' · ',
                )
              }
            />
          ) : null}
        </>
      ) : null}
    </section>
  );
}
