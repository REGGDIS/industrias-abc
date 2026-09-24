import {
  useEffect,
  useState,
} from 'react';
import { RotateCcw } from 'lucide-react';

import {
  getProduccionCatalogos,
  type ProduccionCatalogos,
} from '../../services/produccion-catalogos.service';
import type { BiFilters } from '../../types/filters';
import { FilterSelect } from './FilterSelect';

interface ProduccionFilterBarProps {
  filters: BiFilters;
  onChange: (
    filters: BiFilters,
  ) => void;
}

const emptyCatalogos:
  ProduccionCatalogos = {
    anios: [],
    meses: [],
    productos: [],
    insumos: [],
    ultimoPeriodoDisponible:
      null,
    fechaMaximaDisponible:
      null,
  };

export function ProduccionFilterBar({
  filters,
  onChange,
}: ProduccionFilterBarProps) {
  const [
    catalogos,
    setCatalogos,
  ] = useState<ProduccionCatalogos>(
    emptyCatalogos,
  );

  useEffect(() => {
    let active = true;

    getProduccionCatalogos(
      filters,
    ).then((result) => {
      if (!active) {
        return;
      }

      setCatalogos(result);
    });

    return () => {
      active = false;
    };
  }, [filters]);

  function updateNumericFilter(
    key:
      | 'anio'
      | 'mes'
      | 'productoId',
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

  function updateInsumo(
    rawValue: string,
  ) {
    onChange({
      ...filters,
      insumoRef:
        rawValue === ''
          ? undefined
          : rawValue,
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
          options={
            catalogos.anios
          }
          onChange={(value) =>
            updateNumericFilter(
              'anio',
              value,
            )
          }
        />

        <FilterSelect
          label="Mes"
          value={filters.mes}
          options={
            catalogos.meses
          }
          onChange={(value) =>
            updateNumericFilter(
              'mes',
              value,
            )
          }
        />

        <FilterSelect
          label="Producto"
          value={
            filters.productoId
          }
          options={
            catalogos.productos
          }
          placeholder="Todos"
          onChange={(value) =>
            updateNumericFilter(
              'productoId',
              value,
            )
          }
        />

        <FilterSelect
          label="Referencia de insumo"
          value={
            filters.insumoRef
          }
          options={
            catalogos.insumos
          }
          placeholder="Todas"
          onChange={
            updateInsumo
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
