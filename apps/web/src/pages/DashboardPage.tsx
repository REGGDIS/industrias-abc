import { useState } from 'react';
import {
  BarChart3,
  Clock3,
  ShoppingCart,
  Users,
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
import { StatusBadge } from '../components/feedback/StatusBadge';
import { FilterBar } from '../components/filters/FilterBar';
import { KpiCard } from '../components/kpi/KpiCard';
import {
  DataTable,
  type DataTableColumn,
} from '../components/tables/DataTable';
import {
  componentDemoChart,
  componentDemoRows,
} from '../mocks/components-demo.mock';
import type { BiFilters } from '../types/filters';

type DemoRow = (typeof componentDemoRows)[number];

const columns: DataTableColumn<DemoRow>[] = [
  {
    key: 'area',
    label: 'Área',
    render: (row) => row.area,
  },
  {
    key: 'trabajadores',
    label: 'Trabajadores',
    align: 'right',
    render: (row) => row.trabajadores.toLocaleString('es-CL'),
  },
  {
    key: 'estado',
    label: 'Estado',
    align: 'center',
    render: (row) => (
      <StatusBadge
        label={row.estado}
        tone={row.estado === 'Activo' ? 'success' : 'warning'}
      />
    ),
  },
];

export function DashboardPage() {
  const [filters, setFilters] = useState<BiFilters>({
    anio: 2026,
  });

  return (
    <section className="module-page">
      <div className="page-heading">
        <div>
          <p className="page-eyebrow">Industrias ABC</p>
          <h1>Dashboard Ejecutivo</h1>
          <p>
            Validación de componentes reutilizables para los futuros módulos
            de Business Intelligence.
          </p>
        </div>
      </div>

      <FilterBar
        filters={filters}
        onChange={setFilters}
      />

      <div className="kpi-grid">
        <KpiCard
          title="Trabajadores activos"
          value={80}
          variation={4.2}
          helper="versus período anterior"
          icon={Users}
        />

        <KpiCard
          title="Horas extra"
          value="1.248 h"
          variation={-3.6}
          helper="versus período anterior"
          icon={Clock3}
        />

        <KpiCard
          title="Compras acumuladas"
          value="$48,6 MM"
          variation={7.8}
          helper="versus período anterior"
          icon={ShoppingCart}
        />

        <KpiCard
          title="Cumplimiento"
          value="86 %"
          variation={0}
          helper="producción planificada"
          icon={BarChart3}
        />
      </div>

      <div className="dashboard-chart-section">
        <ChartCard
          title="Evolución mensual"
          description="Serie mock para validar la visualización temporal."
        >
          <div className="chart-demo">
            <ResponsiveContainer width="100%" height={280}>
              <BarChart data={componentDemoChart}>
                <CartesianGrid
                  strokeDasharray="3 3"
                  vertical={false}
                />
                <XAxis
                  dataKey="mes"
                  tickLine={false}
                  axisLine={false}
                />
                <YAxis
                  tickLine={false}
                  axisLine={false}
                />
                <Tooltip />
                <Bar
                  dataKey="valor"
                  fill="var(--primary)"
                  radius={[5, 5, 0, 0]}
                />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </ChartCard>

        <AlertCard
          tone="warning"
          title="Registros pendientes de revisión"
          description="Existen registros marcados como REVIEW en el flujo de calidad de datos. Esta alerta utiliza información mock para validar el componente."
        />
      </div>

      <ChartCard
        title="Dotación por área"
        description="Ejemplo de tabla reutilizable con estados."
      >
        <DataTable
          columns={columns}
          rows={componentDemoRows}
          getRowKey={(row) => row.id}
        />
      </ChartCard>
    </section>
  );
}
