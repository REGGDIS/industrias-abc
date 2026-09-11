import { RotateCcw } from 'lucide-react';

import {
  aniosMock,
  areasMock,
  centrosCostoMock,
  mesesMock,
} from '../../mocks/catalogs.mock';
import type { BiFilters } from '../../types/filters';
import { FilterSelect } from './FilterSelect';

interface FilterBarProps {
  filters: BiFilters;
  onChange: (filters: BiFilters) => void;
}

export function FilterBar({
  filters,
  onChange,
}: FilterBarProps) {
  function updateFilter(
    key: keyof BiFilters,
    rawValue: string,
  ) {
    onChange({
      ...filters,
      [key]: rawValue === '' ? undefined : Number(rawValue),
    });
  }

  function clearFilters() {
    onChange({});
  }

  return (
    <section className="filter-bar">
      <div className="filter-grid">
        <FilterSelect
          label="Año"
          value={filters.anio}
          options={aniosMock}
          onChange={(value) => updateFilter('anio', value)}
        />

        <FilterSelect
          label="Mes"
          value={filters.mes}
          options={mesesMock}
          onChange={(value) => updateFilter('mes', value)}
        />

        <FilterSelect
          label="Área"
          value={filters.areaId}
          options={areasMock}
          onChange={(value) => updateFilter('areaId', value)}
        />

        <FilterSelect
          label="Centro de costo"
          value={filters.centroCostoId}
          options={centrosCostoMock}
          onChange={(value) =>
            updateFilter('centroCostoId', value)
          }
        />
      </div>

      <button
        type="button"
        className="filter-clear-button"
        onClick={clearFilters}
      >
        <RotateCcw size={16} />
        Limpiar
      </button>
    </section>
  );
}
