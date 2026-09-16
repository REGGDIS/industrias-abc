import type { BiFilters } from '../../types/filters';
import type {
  ProduccionResumen,
  ProduccionDetalleResponse,
} from '../../types/produccion';

export interface ProduccionService {
  getResumen(filters?: BiFilters): Promise<ProduccionResumen>;
  getDetalle(filters?: BiFilters): Promise<ProduccionDetalleResponse>;
}
