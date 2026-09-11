import type { BiFilters } from '../../types/filters';
import type {
  CostoArea,
  HorasExtraProduccion,
  HorasExtraDiferencia,
  CostoCentroCosto,
} from '../../types/analisis';

export interface AnalisisService {
  getCostoPorArea(filters?: BiFilters): Promise<CostoArea[]>;

  getHorasExtraProduccion(
    filters?: BiFilters,
  ): Promise<HorasExtraProduccion[]>;

  getHorasExtraDiferencias(
    filters?: BiFilters,
  ): Promise<HorasExtraDiferencia[]>;

  getCostoCentroCosto(
    filters?: BiFilters,
  ): Promise<CostoCentroCosto[]>;
}
