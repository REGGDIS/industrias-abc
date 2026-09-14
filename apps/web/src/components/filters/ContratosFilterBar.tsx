import { RotateCcw } from 'lucide-react';

import {
  aniosMock,
  areasMock,
  mesesMock,
} from '../../mocks/catalogs.mock';
import { rrhhMockEmpleados } from '../../mocks/rrhh.mock';
import type { SelectOption } from '../../types/common';
import type { BiFilters } from '../../types/filters';
import { FilterSelect } from './FilterSelect';

interface ContratosFilterBarProps {
  filters: BiFilters;
  onChange: (filters: BiFilters) => void;
}

const trabajadoresMock: SelectOption[] = rrhhMockEmpleados.map(
  (employee) => ({
    id: employee.empleadoId,
    label: employee.nombre,
  }),
);

export function ContratosFilterBar({
  filters,
  onChange,
}: ContratosFilterBarProps) {
  function updateFilter(
    key: keyof BiFilters,
    rawValue: string,
  ) {
    onChange({
      ...filters,
      [key]: rawValue === '' ? undefined : Number(rawValue),
    });
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
          label="Trabajador"
          value={filters.empleadoId}
          options={trabajadoresMock}
          onChange={(value) =>
            updateFilter('empleadoId', value)
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
