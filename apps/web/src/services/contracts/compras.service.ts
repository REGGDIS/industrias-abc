import type { BiFilters } from '../../types/filters';
import type {
  ComprasResumen,
  ComprasDetalleResponse,
} from '../../types/compras';

export interface ComprasService {
  getResumen(filters?: BiFilters): Promise<ComprasResumen>;
  getDetalle(filters?: BiFilters): Promise<ComprasDetalleResponse>;
}
