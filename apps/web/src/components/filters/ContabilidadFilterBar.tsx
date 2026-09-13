import { RotateCcw } from 'lucide-react';

import {
  aniosMock,
  centrosCostoMock,
  mesesMock,
} from '../../mocks/catalogs.mock';
import { cuentasGastoMock } from '../../mocks/contabilidad.mock';
import type { SelectOption } from '../../types/common';
import type { BiFilters } from '../../types/filters';
import { FilterSelect } from './FilterSelect';

interface ContabilidadFilterBarProps {
  filters: BiFilters;
  onChange: (filters: BiFilters) => void;
}

const cuentasOptions: SelectOption[] =
  cuentasGastoMock.map((cuenta) => ({
    id: cuenta.cuentaContableId,
    label: `${cuenta.codigo} - ${cuenta.nombre}`,
  }));

export function ContabilidadFilterBar({
  filters,
  onChange,
}: ContabilidadFilterBarProps) {
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
          label="Centro de costo"
          value={filters.centroCostoId}
          options={centrosCostoMock}
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
          options={cuentasOptions}
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
