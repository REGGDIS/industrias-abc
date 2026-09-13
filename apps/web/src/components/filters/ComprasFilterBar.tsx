import { RotateCcw } from 'lucide-react';

import {
  proveedoresComprasMock,
  insumosComprasMock,
} from '../../mocks/compras.mock';
import {
  aniosMock,
  mesesMock,
} from '../../mocks/catalogs.mock';
import type { SelectOption } from '../../types/common';
import type { BiFilters } from '../../types/filters';
import { FilterSelect } from './FilterSelect';

interface ComprasFilterBarProps {
  filters: BiFilters;
  onChange: (filters: BiFilters) => void;
}

const proveedoresOptions: SelectOption[] =
  proveedoresComprasMock.map(
    (proveedor) => ({
      id: proveedor.proveedorId,
      label: proveedor.nombre,
    }),
  );

const insumosOptions: SelectOption[] =
  insumosComprasMock.map(
    (insumo) => ({
      id: insumo.insumoId,
      label: insumo.nombre,
    }),
  );

export function ComprasFilterBar({
  filters,
  onChange,
}: ComprasFilterBarProps) {
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
          label="Proveedor"
          value={filters.proveedorId}
          options={proveedoresOptions}
          onChange={(value) =>
            updateFilter(
              'proveedorId',
              value,
            )
          }
        />

        <FilterSelect
          label="Insumo"
          value={filters.insumoId}
          options={insumosOptions}
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
