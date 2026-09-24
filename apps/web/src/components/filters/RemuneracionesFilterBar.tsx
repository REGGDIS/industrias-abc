import {
  useEffect,
  useState,
} from 'react';
import { RotateCcw } from 'lucide-react';

import { getRemuneracionesCatalogos } from '../../services/remuneraciones-catalogos.service';
import type { SelectOption } from '../../types/common';
import type { BiFilters } from '../../types/filters';
import { FilterSelect } from './FilterSelect';

interface RemuneracionesFilterBarProps {
  filters: BiFilters;
  onChange: (filters: BiFilters) => void;
}

export function RemuneracionesFilterBar({
  filters,
  onChange,
}: RemuneracionesFilterBarProps) {
  const [anios, setAnios] =
    useState<SelectOption[]>([]);

  const [meses, setMeses] =
    useState<SelectOption[]>([]);

  const [areas, setAreas] =
    useState<SelectOption[]>([]);

  const [trabajadores, setTrabajadores] =
    useState<SelectOption[]>([]);

  useEffect(() => {
    let active = true;

    getRemuneracionesCatalogos(filters).then(
      (catalogos) => {
        if (!active) {
          return;
        }

        setAnios(catalogos.anios);
        setMeses(catalogos.meses);
        setAreas(catalogos.areas);
        setTrabajadores(
          catalogos.trabajadores,
        );
      },
    );

    return () => {
      active = false;
    };
  }, [filters]);

  function updateNumberFilter(
    key: 'anio' | 'mes' | 'areaId',
    rawValue: string,
  ) {
    onChange({
      ...filters,
      [key]:
        rawValue === ''
          ? undefined
          : Number(rawValue),
      trabajadorId:
        key === 'areaId'
          ? undefined
          : filters.trabajadorId,
    });
  }

  function updateTrabajador(
    rawValue: string,
  ) {
    onChange({
      ...filters,
      trabajadorId:
        rawValue === ''
          ? undefined
          : rawValue,
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
            updateNumberFilter(
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
            updateNumberFilter(
              'mes',
              value,
            )
          }
        />

        <FilterSelect
          label="Área"
          value={filters.areaId}
          options={areas}
          placeholder="Todas"
          onChange={(value) =>
            updateNumberFilter(
              'areaId',
              value,
            )
          }
        />

        <FilterSelect
          label="Trabajador"
          value={filters.trabajadorId}
          options={trabajadores}
          placeholder="Todos"
          onChange={updateTrabajador}
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
