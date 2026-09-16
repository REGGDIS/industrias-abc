import {
  useEffect,
  useState,
} from 'react';
import {
  Factory,
  Gauge,
  PackageCheck,
  TriangleAlert,
  ListChecks,
  Boxes,
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
import {
  produccionService,
} from '../services/produccion.service';
import type { BiFilters } from '../types/filters';
import type {
  ProduccionDetalle,
  ProduccionDetalleResponse,
  ProduccionResumen,
} from '../types/produccion';

const numberFormatter =
  new Intl.NumberFormat(
    'es-CL',
    {
      maximumFractionDigits: 1,
    },
  );

function formatNumber(
  value: number,
) {
  return numberFormatter.format(
    value,
  );
}

function formatPercent(
  value: number,
) {
  return `${value.toLocaleString(
    'es-CL',
    {
      maximumFractionDigits: 2,
    },
  )} %`;
}

function cumplimientoOrden(
  row: ProduccionDetalle,
) {
  if (
    row.cantidadPlanificada <= 0
  ) {
    return 0;
  }

  return (
    row.cantidadProducida /
    row.cantidadPlanificada *
    100
  );
}

const columns:
  DataTableColumn<ProduccionDetalle>[] = [
    {
      key: 'orden',
      label: 'Orden',
      render: (row) =>
        row.numeroOrden,
    },
    {
      key: 'fecha',
      label: 'Inicio',
      render: (row) =>
        row.fechaInicio,
    },
    {
      key: 'producto',
      label: 'Producto',
      render: (row) =>
        `${row.productoCodigo} - ${row.producto}`,
    },
    {
      key: 'estado',
      label: 'Estado',
      render: (row) =>
        row.estado.replace(
          '_',
          ' ',
        ),
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
        formatPercent(
          cumplimientoOrden(
            row,
          ),
        ),
    },
  ];

export function ProduccionPage() {
  const [
    filters,
    setFilters,
  ] = useState<BiFilters>({
    anio: 2026,
  });

  const [
    summary,
    setSummary,
  ] = useState<
    ProduccionResumen | null
  >(null);

  const [
    detail,
    setDetail,
  ] = useState<
    ProduccionDetalleResponse | null
  >(null);

  const [
    error,
    setError,
  ] = useState<string | null>(
    null,
  );

  useEffect(() => {
    let active = true;

    setError(null);

    Promise.all([
      produccionService.getResumen(
        filters,
      ),
      produccionService.getDetalle(
        filters,
      ),
    ])
      .then(
        ([
          summaryResult,
          detailResult,
        ]) => {
          if (!active) {
            return;
          }

          setSummary(
            summaryResult,
          );
          setDetail(
            detailResult,
          );
        },
      )
      .catch((reason) => {
        if (!active) {
          return;
        }

        setSummary(null);
        setDetail(null);

        setError(
          reason instanceof Error
            ? reason.message
            : 'No fue posible cargar Producción.',
        );
      });

    return () => {
      active = false;
    };
  }, [filters]);

  const hasData =
    Boolean(
      detail &&
        detail.pagination
          .total > 0,
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
            consumo de insumos desde el
            Data Warehouse.
          </p>
        </div>
      </div>

      <ProduccionFilterBar
        filters={filters}
        onChange={setFilters}
      />

      {error ? (
        <AlertCard
          tone="danger"
          title="Error al cargar Producción"
          description={error}
        />
      ) : null}

      {summary &&
      detail &&
      !hasData ? (
        <AlertCard
          tone="info"
          title="Sin registros de producción"
          description="No existen órdenes de producción para la combinación de período, producto y referencia de insumo seleccionada."
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
                  .cantidadPlanificada,
              )}
              helper="unidades planificadas"
              icon={Factory}
            />

            <KpiCard
              title="Producción real"
              value={formatNumber(
                summary.kpis
                  .cantidadProducida,
              )}
              helper="unidades producidas"
              icon={PackageCheck}
            />

            <KpiCard
              title="Cumplimiento"
              value={formatPercent(
                summary.kpis
                  .cumplimientoProduccion,
              )}
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
              value={formatPercent(
                summary.kpis
                  .tasaRechazo,
              )}
              helper="sobre producción real"
              icon={Boxes}
            />

            <KpiCard
              title="Órdenes de producción"
              value={String(
                summary.kpis
                  .totalOrdenes,
              )}
              helper={`${summary.kpis.productosActivos} productos activos`}
              icon={ListChecks}
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
                        .rechazoPorProducto
                    }
                    layout="vertical"
                    margin={{
                      top: 10,
                      right: 25,
                      bottom: 30,
                      left: 30,
                    }}
                  >
                    <CartesianGrid
                      strokeDasharray="3 3"
                      horizontal={false}
                    />

                    <XAxis
                      type="number"
                      allowDecimals={false}
                      tickMargin={10}
                      height={35}
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
                        formatNumber(
                          Number(
                            value,
                          ),
                        ),
                        'Unidades rechazadas',
                      ]}
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
              title="Desviación de consumo por referencia"
              description="Diferencia porcentual entre consumo real y planificado por referencia de origen. Las referencias aún no están homologadas a insumos empresariales."
            >
              <div className="chart-demo">
                <ResponsiveContainer
                  width="100%"
                  height={300}
                >
                  <BarChart
                    data={
                      summary.consumoPorInsumo.map(
                        (item) => ({
                          label:
                            item.label,
                          value:
                            item.planificado > 0
                              ? (
                                  item.desviacion /
                                  item.planificado
                                ) * 100
                              : 0,
                        }),
                      )
                    }
                    layout="vertical"
                    margin={{
                      top: 5,
                      right: 35,
                      bottom: 10,
                      left: 30,
                    }}
                  >
                    <CartesianGrid
                      strokeDasharray="3 3"
                      horizontal={false}
                    />

                    <XAxis
                      type="number"
                      tickFormatter={(value) =>
                        `${Number(
                          value,
                        ).toLocaleString(
                          'es-CL',
                          {
                            maximumFractionDigits: 1,
                          },
                        )} %`
                      }
                    />

                    <YAxis
                      type="category"
                      dataKey="label"
                      width={150}
                      tickLine={false}
                      axisLine={false}
                    />

                    <Tooltip
                      formatter={(value) => [
                        `${Number(
                          value,
                        ).toLocaleString(
                          'es-CL',
                          {
                            maximumFractionDigits: 2,
                          },
                        )} %`,
                        'Desviación',
                      ]}
                    />

                    <Bar
                      dataKey="value"
                      fill="var(--primary)"
                      radius={[
                        5,
                        5,
                        5,
                        5,
                      ]}
                    />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </ChartCard>
          </div>

          <div className="dashboard-two-columns">
            <ChartCard
              title="Evolución mensual de producción"
              description="Producción planificada y real para el año seleccionado."
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
                    margin={{
                      top: 10,
                      right: 20,
                      bottom: 30,
                      left: 5,
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
                      tickMargin={12}
                      height={40}
                    />

                    <YAxis
                      tickFormatter={(value) =>
                        formatNumber(
                          Number(
                            value,
                          ),
                        )
                      }
                    />

                    <Tooltip
                      formatter={(
                        value,
                        name,
                      ) => [
                        formatNumber(
                          Number(
                            value,
                          ),
                        ),
                        name ===
                        'producida'
                          ? 'Producción real'
                          : 'Planificada',
                      ]}
                    />

                    <Line
                      type="monotone"
                      dataKey="planificada"
                      stroke="var(--border-strong)"
                      strokeWidth={2}
                      dot={{ r: 3 }}
                    />

                    <Line
                      type="monotone"
                      dataKey="producida"
                      stroke="var(--primary)"
                      strokeWidth={3}
                      dot={{ r: 3 }}
                      activeDot={{
                        r: 5,
                      }}
                    />
                  </LineChart>
                </ResponsiveContainer>
              </div>
            </ChartCard>

            <ChartCard
              title="Órdenes por estado"
              description="Distribución de las órdenes del período seleccionado."
            >
              <div className="chart-demo">
                <ResponsiveContainer
                  width="100%"
                  height={300}
                >
                  <BarChart
                    data={
                      summary
                        .ordenesPorEstado
                    }
                    margin={{
                      top: 10,
                      right: 15,
                      bottom: 35,
                      left: 5,
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
                      tickMargin={12}
                      height={45}
                      tickFormatter={(value) =>
                        String(value).replace(
                          '_',
                          ' ',
                        )
                      }
                    />

                    <YAxis
                      allowDecimals={false}
                    />

                    <Tooltip />

                    <Bar
                      dataKey="value"
                      fill="var(--primary)"
                      radius={[
                        5,
                        5,
                        0,
                        0,
                      ]}
                    />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </ChartCard>
          </div>

          <ChartCard
            title="Detalle de órdenes de producción"
            description={`${detail.items.length} registros mostrados de ${detail.pagination.total} órdenes filtradas.`}
          >
            <DataTable
              columns={columns}
              rows={detail.items}
              getRowKey={(row) =>
                row.produccionId
              }
            />
          </ChartCard>
        </>
      ) : null}
    </section>
  );
}
