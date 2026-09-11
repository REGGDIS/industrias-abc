import type { BiFilters } from '../../types/filters';
import type {
  ContabilidadResumen,
  MovimientosContablesResponse,
} from '../../types/contabilidad';

export interface ContabilidadService {
  getResumen(filters?: BiFilters): Promise<ContabilidadResumen>;
  getMovimientos(
    filters?: BiFilters,
  ): Promise<MovimientosContablesResponse>;
}
