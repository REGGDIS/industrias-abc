import type { BiFilters } from '../../types/filters';
import type {
  AsistenciaResumen,
  AsistenciaDetalleResponse,
} from '../../types/asistencia';

export interface AsistenciaService {
  getResumen(filters?: BiFilters): Promise<AsistenciaResumen>;
  getDetalle(filters?: BiFilters): Promise<AsistenciaDetalleResponse>;
}
