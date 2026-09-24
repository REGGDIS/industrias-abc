import {
  useEffect,
  useState,
} from 'react';
import { RotateCcw } from 'lucide-react';

import {
  getComprasCatalogos,
  type ComprasCatalogos,
} from '../../services/compras-catalogos.service';
import type { BiFilters } from '../../types/filters';
import { FilterSelect } from './FilterSelect';

interface ComprasFilterBarProps {
  filters: BiFilters;
  onChange: (filters: BiFilters) => void;
}

const emptyCatalogos: ComprasCatalogos = {
  anios: [],
  meses: [],
  proveedores: [],
  insumos: [],
  ultimoPeriodoDisponible: null,
  fechaMaximaDisponible: null,
};

export function ComprasFilterBar({
  filters,
  onChange,
}: ComprasFilterBarProps) {
  const [catalogos, setCatalogos] =
    useState<ComprasCatalogos>(
      emptyCatalogos,
    );

  useEffect(() => {
    let active = true;

    getComprasCatalogos(filters).then(
      (result) => {
        if (!active) {
          return;
        }

        setCatalogos(result);
      },
    );

    return () => {
      active = false;
    };
  }, [filters]);

  function updateFilter(
    key: keyof BiFilters,
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

  function clearFilters() {
    onChange({});
  }

  return (
    <section className="filter-bar">
      <div className="filter-grid">
        <FilterSelect
          label="Año"
          value={filters.anio}
          options={catalogos.anios}
          onChange={(value) =>
            updateFilter('anio', value)
          }
        />

        <FilterSelect
          label="Mes"
          value={filters.mes}
          options={catalogos.meses}
          onChange={(value) =>
            updateFilter('mes', value)
          }
        />

        <FilterSelect
          label="Proveedor"
          value={filters.proveedorId}
          options={catalogos.proveedores}
          placeholder="Todos"
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
          options={catalogos.insumos}
          placeholder="Todos"
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
        onClick={clearFilters}
      >
        <RotateCcw size={16} />
        Limpiar
      </button>
    </section>
  );
}
