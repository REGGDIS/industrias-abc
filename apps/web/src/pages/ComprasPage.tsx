import {
  useEffect,
  useState,
} from 'react';
import {
  BadgeCheck,
  Boxes,
  Building2,
  ClipboardList,
  DollarSign,
  ShoppingCart,
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
import { ComprasFilterBar } from '../components/filters/ComprasFilterBar';
import { KpiCard } from '../components/kpi/KpiCard';
import {
  DataTable,
  type DataTableColumn,
} from '../components/tables/DataTable';
import { comprasService } from '../services/compras.service';
import type {
  CompraDetalle,
  ComprasDetalleResponse,
  ComprasResumen,
} from '../types/compras';
import type { BiFilters } from '../types/filters';

const currencyFormatter =
  new Intl.NumberFormat('es-CL', {
    style: 'currency',
    currency: 'CLP',
    maximumFractionDigits: 0,
  });

const numberFormatter =
  new Intl.NumberFormat('es-CL');

function formatCurrency(
  value: number,
) {
  return currencyFormatter.format(value);
}

function formatAxisAmount(
  rawValue: number | string,
) {
  const value = Number(rawValue);
  const absoluteValue = Math.abs(value);

  if (absoluteValue >= 1000000) {
    return `${(
      value / 1000000
    ).toLocaleString('es-CL', {
      maximumFractionDigits: 1,
    })}M`;
  }

  if (absoluteValue >= 1000) {
    return `${(
      value / 1000
    ).toLocaleString('es-CL', {
      maximumFractionDigits: 1,
    })} mil`;
  }

  return value.toLocaleString('es-CL', {
    maximumFractionDigits: 0,
  });
}

function formatDate(value: string) {
  return new Intl.DateTimeFormat(
    'es-CL',
  ).format(
    new Date(`${value}T00:00:00`),
  );
}

const columns: DataTableColumn<CompraDetalle>[] = [
  {
    key: 'orden',
    label: 'Orden',
    render: (row) =>
      row.numeroOc,
  },
  {
    key: 'fecha',
    label: 'Fecha',
    render: (row) =>
      formatDate(row.fecha),
  },
  {
    key: 'proveedor',
    label: 'Proveedor',
    render: (row) =>
      row.proveedor,
  },
  {
    key: 'insumo',
    label: 'Insumo',
    render: (row) => row.insumo,
  },
  {
    key: 'centroCosto',
    label: 'Centro costo',
    render: (row) =>
      row.centroCosto,
  },
  {
    key: 'cantidad',
    label: 'Cantidad',
    align: 'right',
    render: (row) =>
      numberFormatter.format(
        row.cantidad,
      ),
  },
  {
    key: 'total',
    label: 'Total',
    align: 'right',
    render: (row) =>
      formatCurrency(row.total),
  },
];

export function ComprasPage() {
  const [filters, setFilters] =
    useState<BiFilters>({});

  const [summary, setSummary] =
    useState<ComprasResumen | null>(
      null,
    );

  const [detail, setDetail] =
    useState<ComprasDetalleResponse | null>(
      null,
    );

  useEffect(() => {
    let active = true;

    Promise.all([
      comprasService.getResumen(
        filters,
      ),
      comprasService.getDetalle(
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

          <h1>
            Compras y Abastecimiento
          </h1>

          <p>
            Órdenes de compra,
            proveedores, insumos y
            cumplimiento.
          </p>
        </div>
      </div>

      <ComprasFilterBar
        filters={filters}
        onChange={setFilters}
      />

      {summary &&
      detail &&
      !hasData ? (
        <AlertCard
          tone="info"
          title="Sin registros de compras"
          description="No existen órdenes de compra para la combinación de período, proveedor e insumo seleccionada."
        />
      ) : null}

      {summary &&
      detail &&
      hasData ? (
        <>
          <div className="kpi-grid compras-kpi-grid">
            <KpiCard
              title="Total comprado"
              value={formatCurrency(
                summary.kpis
                  .totalComprado,
              )}
              helper="período seleccionado"
              icon={DollarSign}
            />

            <KpiCard
              title="Órdenes de compra"
              value={
                summary.kpis
                  .totalOrdenes
              }
              helper="órdenes registradas"
              icon={ClipboardList}
            />

            <KpiCard
              title="Compra promedio"
              value={formatCurrency(
                summary.kpis
                  .compraPromedio,
              )}
              helper="promedio por orden"
              icon={ShoppingCart}
            />

            <KpiCard
              title="Proveedores activos"
              value={
                summary.kpis
                  .proveedoresActivos
              }
              helper="con compras registradas"
              icon={Building2}
            />

            <KpiCard
              title="Cumplimiento"
              value={`${summary.kpis.cumplimientoProveedores.toLocaleString(
                'es-CL',
                {
                  maximumFractionDigits: 1,
                },
              )} %`}
              helper="órdenes cumplidas"
              icon={BadgeCheck}
            />

            <KpiCard
              title="Unidades recibidas"
              value={numberFormatter.format(
                summary.kpis
                  .insumosAdquiridos,
              )}
              helper="cantidad efectivamente recibida"
              icon={Boxes}
            />
          </div>

          <div className="dashboard-two-columns">
            <ChartCard
              title="Top proveedores"
              description="Monto comprado por proveedor."
            >
              {summary.topProveedores.length > 0 ? (
                <div className="chart-demo">
                <ResponsiveContainer
                  width="100%"
                  height={300}
                >
                  <BarChart
                    data={
                      summary.topProveedores
                    }
                    layout="vertical"
                    margin={{
                      top: 10,
                      right: 35,
                      bottom: 30,
                      left: 40,
                    }}
                  >
                    <CartesianGrid
                      strokeDasharray="3 3"
                      horizontal={false}
                    />

                    <XAxis
                      type="number"
                      tickFormatter={formatAxisAmount}
                      height={45}
                      tickMargin={10}
                    />

                    <YAxis
                      type="category"
                      dataKey="label"
                      width={180}
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
              ) : (
                <div
                  className="chart-demo"
                  style={{
                    minHeight: 220,
                    display: 'grid',
                    placeItems: 'center',
                    padding: 24,
                    textAlign: 'center',
                    color: 'var(--text-muted)',
                  }}
                >
                  Sin compras efectivas para el período seleccionado.
                </div>
              )}
            </ChartCard>

            <ChartCard
              title="Top insumos"
              description="Monto comprado por insumo."
            >
              {summary.topInsumos.length > 0 ? (
                <div className="chart-demo">
                <ResponsiveContainer
                  width="100%"
                  height={300}
                >
                  <BarChart
                    data={
                      summary.topInsumos
                    }
                    layout="vertical"
                    margin={{
                      top: 10,
                      right: 35,
                      bottom: 30,
                      left: 40,
                    }}
                  >
                    <CartesianGrid
                      strokeDasharray="3 3"
                      horizontal={false}
                    />

                    <XAxis
                      type="number"
                      tickFormatter={formatAxisAmount}
                      height={45}
                      tickMargin={10}
                    />

                    <YAxis
                      type="category"
                      dataKey="label"
                      width={180}
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
              ) : (
                <div
                  className="chart-demo"
                  style={{
                    minHeight: 220,
                    display: 'grid',
                    placeItems: 'center',
                    padding: 24,
                    textAlign: 'center',
                    color: 'var(--text-muted)',
                  }}
                >
                  Sin compras efectivas para el período seleccionado.
                </div>
              )}
            </ChartCard>
          </div>

          <ChartCard
            title="Evolución mensual de compras"
            description="Monto total comprado por mes."
          >
            <div className="chart-demo">
              <ResponsiveContainer
                width="100%"
                height={340}
              >
                <LineChart
                  data={
                    summary.evolucionMensual
                  }
                  margin={{
                    top: 10,
                    right: 35,
                    bottom: 55,
                    left: 15,
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
                    height={60}
                    tickMargin={14}
                  />

                  <YAxis
                    tickFormatter={formatAxisAmount}
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
            title="Compras por centro de costo"
            description="Distribución del gasto entre centros de costo."
          >
            {summary.comprasPorCentroCosto.length > 0 ? (
                <div className="chart-demo">
              <ResponsiveContainer
                width="100%"
                height={280}
              >
                <BarChart
                  data={
                    summary
                      .comprasPorCentroCosto
                  }
                  margin={{
                    top: 10,
                    right: 35,
                    bottom: 45,
                    left: 15,
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
                    height={45}
                    tickMargin={12}
                  />

                  <YAxis
                    tickFormatter={formatAxisAmount}
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
                    radius={[5, 5, 0, 0]}
                  />
                </BarChart>
              </ResponsiveContainer>
            </div>
              ) : (
                <div
                  className="chart-demo"
                  style={{
                    minHeight: 220,
                    display: 'grid',
                    placeItems: 'center',
                    padding: 24,
                    textAlign: 'center',
                    color: 'var(--text-muted)',
                  }}
                >
                  Sin compras efectivas para el período seleccionado.
                </div>
              )}
            </ChartCard>

          <ChartCard
            title="Detalle de órdenes de compra"
            description={`Primeros ${detail.items.length} registros de ${detail.pagination.total} registros filtrados.`}
          >
            <DataTable
              columns={columns}
              rows={detail.items}
              getRowKey={(row) =>
                row.ordenCompraId
              }
            />
          </ChartCard>
        </>
      ) : null}
    </section>
  );
}
