import {
  useEffect,
  useMemo,
  useState,
} from 'react';
import {
  Banknote,
  Building2,
  Clock3,
  Factory,
} from 'lucide-react';
import {
  Bar,
  BarChart,
  CartesianGrid,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts';

import { ChartCard } from '../components/charts/ChartCard';
import { AlertCard } from '../components/feedback/AlertCard';
import { FilterBar } from '../components/filters/FilterBar';
import { KpiCard } from '../components/kpi/KpiCard';
import {
  DataTable,
  type DataTableColumn,
} from '../components/tables/DataTable';
import { analisisMockService } from '../services/mock/analisis.mock.service';
import type {
  CostoArea,
  CostoCentroCosto,
  HorasExtraDiferencia,
  HorasExtraProduccion,
} from '../types/analisis';
import type { BiFilters } from '../types/filters';

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
  if (
    Math.abs(value) >=
    1_000_000
  ) {
    return `${(
      value / 1_000_000
    ).toLocaleString('es-CL', {
      maximumFractionDigits: 1,
    })}M`;
  }

  if (Math.abs(value) >= 1_000) {
    return `${Math.round(
      value / 1_000,
    ).toLocaleString('es-CL')}K`;
  }

  return value.toLocaleString(
    'es-CL',
  );
}

const differenceColumns: DataTableColumn<HorasExtraDiferencia>[] =
  [
    {
      key: 'area',
      label: 'Área',
      render: (row) => row.area,
    },
    {
      key: 'registradas',
      label: 'Horas registradas',
      align: 'right',
      render: (row) =>
        formatNumber(
          row.horasRegistradas,
        ),
    },
    {
      key: 'pagadas',
      label: 'Horas pagadas',
      align: 'right',
      render: (row) =>
        formatNumber(
          row.horasPagadas,
        ),
    },
    {
      key: 'diferencia',
      label: 'Diferencia',
      align: 'right',
      render: (row) =>
        formatNumber(
          row.diferencia,
        ),
    },
  ];

export function AnalisisPage() {
  const [filters, setFilters] =
    useState<BiFilters>({
      anio: 2026,
    });

  const [costosArea, setCostosArea] =
    useState<CostoArea[]>([]);

  const [
    horasExtraProduccion,
    setHorasExtraProduccion,
  ] = useState<
    HorasExtraProduccion[]
  >([]);

  const [
    diferencias,
    setDiferencias,
  ] = useState<
    HorasExtraDiferencia[]
  >([]);

  const [
    costosCentro,
    setCostosCentro,
  ] = useState<
    CostoCentroCosto[]
  >([]);

  useEffect(() => {
    let active = true;

    Promise.all([
      analisisMockService.getCostoPorArea(
        filters,
      ),
      analisisMockService.getHorasExtraProduccion(
        filters,
      ),
      analisisMockService.getHorasExtraDiferencias(
        filters,
      ),
      analisisMockService.getCostoCentroCosto(
        filters,
      ),
    ]).then(
      ([
        areaResult,
        produccionResult,
        diferenciasResult,
        centroResult,
      ]) => {
        if (!active) {
          return;
        }

        setCostosArea(areaResult);
        setHorasExtraProduccion(
          produccionResult,
        );
        setDiferencias(
          diferenciasResult,
        );
        setCostosCentro(
          centroResult,
        );
      },
    );

    return () => {
      active = false;
    };
  }, [filters]);

  const costoIntegrado =
    useMemo(
      () =>
        costosArea.reduce(
          (total, item) =>
            total +
            item.costoTotal,
          0,
        ),
      [costosArea],
    );

  const mayorArea =
    costosArea[0];

  const totalHorasExtra =
    useMemo(
      () =>
        diferencias.reduce(
          (total, item) =>
            total +
            item.horasRegistradas,
          0,
        ),
      [diferencias],
    );

  const produccionReal =
    horasExtraProduccion[0]
      ?.produccion ?? 0;

  const hasData =
    costosArea.some(
      (item) =>
        item.costoTotal > 0,
    );

  const costoAreaChart =
    costosArea.map((item) => ({
      label: item.area,
      remuneraciones:
        item.remuneraciones,
      compras: item.compras,
      contabilidad:
        item.gastosContables,
    }));

  const costoCentroChart =
    costosCentro.map((item) => ({
      label: item.centroCosto,
      value: item.costoTotal,
    }));

  const diferenciaChart =
    diferencias.map((item) => ({
      label: item.area,
      registradas:
        item.horasRegistradas,
      pagadas: item.horasPagadas,
    }));

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
            Cruce analítico de costos,
            horas extra y producción a
            partir de los módulos mock
            disponibles.
          </p>
        </div>
      </div>

      <FilterBar
        filters={filters}
        onChange={setFilters}
      />

      {!hasData ? (
        <AlertCard
          tone="info"
          title="Sin datos integrados"
          description="No existen datos mock suficientes para la combinación de filtros seleccionada."
        />
      ) : null}

      {hasData ? (
        <>
          <div className="kpi-grid analisis-kpi-grid">
            <KpiCard
              title="Costo integrado"
              value={formatCurrency(
                costoIntegrado,
              )}
              helper="remuneraciones + compras + gastos"
              icon={Banknote}
            />

            <KpiCard
              title="Área de mayor costo"
              value={
                mayorArea?.area ?? '—'
              }
              helper={
                mayorArea
                  ? formatCurrency(
                      mayorArea.costoTotal,
                    )
                  : 'sin datos'
              }
              icon={Building2}
            />

            <KpiCard
              title="Horas extra registradas"
              value={formatNumber(
                totalHorasExtra,
              )}
              helper="todas las áreas filtradas"
              icon={Clock3}
            />

            <KpiCard
              title="Producción real"
              value={formatNumber(
                produccionReal,
              )}
              helper="unidades producidas"
              icon={Factory}
            />
          </div>

          <ChartCard
            title="Composición de costos por área"
            description="Comparación integrada de remuneraciones, compras y gastos contables."
          >
            <div className="chart-demo analisis-cost-chart">
              <ResponsiveContainer
                width="100%"
                height="100%"
              >
                <BarChart
                  data={costoAreaChart}
                  margin={{
                    top: 16,
                    right: 24,
                    left: 12,
                    bottom: 20,
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
                    interval={0}
                    height={42}
                    tickMargin={10}
                  />

                  <YAxis
                    tickFormatter={(value) =>
                      formatCompactCurrency(
                        Number(value),
                      )
                    }
                  />

                  <Tooltip
                    formatter={(
                      value,
                      name,
                    ) => [
                      formatCurrency(
                        Number(value),
                      ),
                      name,
                    ]}
                  />

                  <Bar
                    dataKey="remuneraciones"
                    name="Remuneraciones"
                    stackId="costos"
                    fill="var(--primary)"
                  />

                  <Bar
                    dataKey="compras"
                    name="Compras"
                    stackId="costos"
                    fill="var(--accent)"
                  />

                  <Bar
                    dataKey="contabilidad"
                    name="Gastos contables"
                    stackId="costos"
                    fill="var(--success)"
                    radius={[5, 5, 0, 0]}
                  />
                </BarChart>
              </ResponsiveContainer>
            </div>
          </ChartCard>

          <div className="dashboard-two-columns">
            <ChartCard
              title="Costo por centro de costo"
              description="Costo integrado acumulado por centro de costo."
            >
              <div className="chart-demo analisis-secondary-chart">
                <ResponsiveContainer
                  width="100%"
                  height="100%"
                >
                  <BarChart
                    data={
                      costoCentroChart
                    }
                    layout="vertical"
                    margin={{
                      top: 12,
                      right: 25,
                      left: 35,
                      bottom: 30,
                    }}
                  >
                    <CartesianGrid
                      strokeDasharray="3 3"
                      horizontal={false}
                    />

                    <XAxis
                      type="number"
                      height={42}
                      tickMargin={10}
                      tickFormatter={(
                        value,
                      ) =>
                        formatCompactCurrency(
                          Number(value),
                        )
                      }
                    />

                    <YAxis
                      type="category"
                      dataKey="label"
                      width={155}
                      tickLine={false}
                      axisLine={false}
                    />

                    <Tooltip
                      formatter={(
                        value,
                      ) => [
                        formatCurrency(
                          Number(value),
                        ),
                        'Costo total',
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
              title="Horas extra registradas vs pagadas"
              description="Control cruzado entre Asistencia y Remuneraciones."
            >
              <div className="chart-demo analisis-secondary-chart">
                <ResponsiveContainer
                  width="100%"
                  height="100%"
                >
                  <BarChart
                    data={diferenciaChart}
                    margin={{
                      top: 12,
                      right: 20,
                      left: 70,
                      bottom: 70,
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
                      interval={0}
                      height={90}
                      tickMargin={12}
                      angle={-25}
                      textAnchor="end"
                    />

                    <YAxis
                      width={50}
                    />

                    <Tooltip
                      formatter={(
                        value,
                        name,
                      ) => [
                        formatNumber(
                          Number(value),
                        ),
                        name,
                      ]}
                    />

                    <Bar
                      dataKey="registradas"
                      name="Registradas"
                      fill="var(--primary)"
                      radius={[
                        5,
                        5,
                        0,
                        0,
                      ]}
                    />

                    <Bar
                      dataKey="pagadas"
                      name="Pagadas"
                      fill="var(--accent)"
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

          {horasExtraProduccion.length >
          0 ? (
            <ChartCard
              title="Horas extra y producción"
              description="Referencia conjunta del área de Producción para el período seleccionado."
            >
              <div className="analisis-production-summary">
                <div>
                  <span>
                    Horas extra
                  </span>
                  <strong>
                    {formatNumber(
                      horasExtraProduccion[0]
                        .horasExtras,
                    )}
                  </strong>
                </div>

                <div>
                  <span>
                    Producción real
                  </span>
                  <strong>
                    {formatNumber(
                      horasExtraProduccion[0]
                        .produccion,
                    )}
                  </strong>
                </div>
              </div>
            </ChartCard>
          ) : null}

          <ChartCard
            title="Control de horas extra"
            description="Diferencia entre horas registradas en Asistencia y horas consideradas en Remuneraciones."
          >
            <DataTable
              columns={
                differenceColumns
              }
              rows={diferencias}
              getRowKey={(row) =>
                row.areaId
              }
            />
          </ChartCard>
        </>
      ) : null}
    </section>
  );
}