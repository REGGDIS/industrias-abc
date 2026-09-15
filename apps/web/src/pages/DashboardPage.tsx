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

    setError(null);

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
              title="Trabajadores remunerados"
              value={
                numberFormatter.format(
                  data.kpis
                    .trabajadoresActivos,
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
          </div>


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
