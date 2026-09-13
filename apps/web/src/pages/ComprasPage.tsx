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
import { comprasMockService } from '../services/mock/compras.mock.service';
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
      `OC-${String(
        row.ordenCompraId,
      ).padStart(4, '0')}`,
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
    useState<BiFilters>({
      anio: 2026,
    });

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
      comprasMockService.getResumen(
        filters,
      ),
      comprasMockService.getDetalle(
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
          description="No existen órdenes de compra mock para la combinación de período, proveedor e insumo seleccionada."
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
              title="Unidades adquiridas"
              value={numberFormatter.format(
                summary.kpis
                  .insumosAdquiridos,
              )}
              helper="unidades de insumos"
              icon={Boxes}
            />
          </div>

          <div className="dashboard-two-columns">
            <ChartCard
              title="Top proveedores"
              description="Monto comprado por proveedor."
            >
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
                      left: 40,
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
                        `${Math.round(
                          Number(value) /
                            1000000,
                        )}M`
                      }
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
            </ChartCard>

            <ChartCard
              title="Top insumos"
              description="Monto comprado por insumo."
            >
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
                      left: 40,
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
                        `${Math.round(
                          Number(value) /
                            1000000,
                        )}M`
                      }
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
            </ChartCard>
          </div>

          <ChartCard
            title="Evolución mensual de compras"
            description="Monto total comprado por mes."
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
            title="Compras por centro de costo"
            description="Distribución del gasto entre centros de costo."
          >
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
            title="Detalle de órdenes de compra"
            description={`Primeros ${detail.items.length} registros de ${detail.pagination.total} órdenes mock filtradas.`}
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
