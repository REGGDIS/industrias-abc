import { RotateCcw } from 'lucide-react';

import {
  aniosMock,
  insumosMock,
  mesesMock,
  productosMock,
} from '../../mocks/catalogs.mock';
import type { BiFilters } from '../../types/filters';
import { FilterSelect } from './FilterSelect';

interface ProduccionFilterBarProps {
  filters: BiFilters;
  onChange: (filters: BiFilters) => void;
}

export function ProduccionFilterBar({
  filters,
  onChange,
}: ProduccionFilterBarProps) {
  function updateFilter(
    key: keyof BiFilters,
    rawValue: string,
  ) {
    onChange({
      ...filters,
      [key]:
        rawValue === ''
          ? undefined
          : Number(rawValue),
    });
  }

  return (
    <section className="filter-bar">
      <div className="filter-grid">
        <FilterSelect
          label="Año"
          value={filters.anio}
          options={aniosMock}
          onChange={(value) =>
            updateFilter('anio', value)
          }
        />

        <FilterSelect
          label="Mes"
          value={filters.mes}
          options={mesesMock}
          onChange={(value) =>
            updateFilter('mes', value)
          }
        />

        <FilterSelect
          label="Producto"
          value={filters.productoId}
          options={productosMock}
          onChange={(value) =>
            updateFilter(
              'productoId',
              value,
            )
          }
        />

        <FilterSelect
          label="Insumo"
          value={filters.insumoId}
          options={insumosMock}
          onChange={(value) =>
            updateFilter(
              'insumoId',
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
