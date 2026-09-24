import {
  useEffect,
  useState,
} from 'react';
import { RotateCcw } from 'lucide-react';

import { getContabilidadCatalogos } from '../../services/contabilidad-catalogos.service';
import type { SelectOption } from '../../types/common';
import type { BiFilters } from '../../types/filters';
import { FilterSelect } from './FilterSelect';

interface ContabilidadFilterBarProps {
  filters: BiFilters;
  onChange: (filters: BiFilters) => void;
}

export function ContabilidadFilterBar({
  filters,
  onChange,
}: ContabilidadFilterBarProps) {
  const [anios, setAnios] =
    useState<SelectOption[]>([]);

  const [meses, setMeses] =
    useState<SelectOption[]>([]);

  const [centrosCosto, setCentrosCosto] =
    useState<SelectOption[]>([]);

  const [cuentasContables, setCuentasContables] =
    useState<SelectOption[]>([]);

  useEffect(() => {
    let active = true;

    getContabilidadCatalogos(filters).then(
      (catalogos) => {
        if (!active) {
          return;
        }

        setAnios(catalogos.anios);
        setMeses(catalogos.meses);
        setCentrosCosto(
          catalogos.centrosCosto,
        );
        setCuentasContables(
          catalogos.cuentasContables,
        );
      },
    );

    return () => {
      active = false;
    };
  }, [filters]);

  function updateFilter(
    key:
      | 'anio'
      | 'mes'
      | 'centroCostoId'
      | 'cuentaContableId',
    rawValue: string,
  ) {
    const value =
      rawValue === ''
        ? undefined
        : Number(rawValue);

    if (key === 'anio') {
      onChange({
        ...filters,
        anio: value,
        mes: undefined,
      });

      return;
    }

    onChange({
      ...filters,
      [key]: value,
    });
  }

  return (
    <section className="filter-bar">
      <div className="filter-grid">
        <FilterSelect
          label="Año"
          value={filters.anio}
          options={anios}
          placeholder="Todos"
          onChange={(value) =>
            updateFilter(
              'anio',
              value,
            )
          }
        />

        <FilterSelect
          label="Mes"
          value={filters.mes}
          options={meses}
          placeholder="Todos"
          onChange={(value) =>
            updateFilter(
              'mes',
              value,
            )
          }
        />

        <FilterSelect
          label="Centro de costo"
          value={filters.centroCostoId}
          options={centrosCosto}
          placeholder="Todos"
          onChange={(value) =>
            updateFilter(
              'centroCostoId',
              value,
            )
          }
        />

        <FilterSelect
          label="Cuenta contable"
          value={filters.cuentaContableId}
          options={cuentasContables}
          placeholder="Todas"
          onChange={(value) =>
            updateFilter(
              'cuentaContableId',
              value,
            )
          }
        />
      </div>

      <button
        type="button"
        className="filter-clear-button"
        onClick={() => onChange({})}
      >
        <RotateCcw size={16} />
        Limpiar
      </button>
    </section>
  );
}
