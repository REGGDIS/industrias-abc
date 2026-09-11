import type { BiFilters } from '../../types/filters';
import type {
  RemuneracionesResumen,
  RemuneracionesDetalleResponse,
} from '../../types/remuneraciones';

export interface RemuneracionesService {
  getResumen(filters?: BiFilters): Promise<RemuneracionesResumen>;
  getDetalle(filters?: BiFilters): Promise<RemuneracionesDetalleResponse>;
}
