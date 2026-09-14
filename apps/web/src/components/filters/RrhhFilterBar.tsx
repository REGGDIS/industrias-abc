import { RotateCcw } from 'lucide-react';

import {
  aniosMock,
  areasMock,
  cargosMock,
  mesesMock,
} from '../../mocks/catalogs.mock';
import type { SelectOption } from '../../types/common';
import type { BiFilters } from '../../types/filters';
import { FilterSelect } from './FilterSelect';

interface RrhhFilterBarProps {
  filters: BiFilters;
  onChange: (filters: BiFilters) => void;
  anios?: SelectOption[];
  meses?: SelectOption[];
  areas?: SelectOption[];
  cargos?: SelectOption[];
}

export function RrhhFilterBar({
  filters,
  onChange,
  anios = aniosMock,
  meses = mesesMock,
  areas = areasMock,
  cargos = cargosMock,
}: RrhhFilterBarProps) {
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
          options={anios}
          onChange={(value) =>
            updateFilter('anio', value)
          }
        />

        <FilterSelect
          label="Mes"
          value={filters.mes}
          options={meses}
          onChange={(value) =>
            updateFilter('mes', value)
          }
        />

        <FilterSelect
          label="Área"
          value={filters.areaId}
          options={areas}
          onChange={(value) =>
            updateFilter('areaId', value)
          }
        />

        <FilterSelect
          label="Cargo"
          value={filters.cargoId}
          options={cargos}
          onChange={(value) =>
            updateFilter('cargoId', value)
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
