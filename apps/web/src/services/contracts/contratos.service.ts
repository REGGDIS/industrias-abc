import type { BiFilters } from '../../types/filters';
import type {
  ContratosResumen,
  ContratosDetalleResponse,
} from '../../types/contratos';

export interface ContratosService {
  getResumen(filters?: BiFilters): Promise<ContratosResumen>;
  getDetalle(filters?: BiFilters): Promise<ContratosDetalleResponse>;
}
