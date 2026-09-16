import type { BiFilters } from '../../types/filters';
import type {
  RrhhResumen,
  TrabajadoresResponse,
} from '../../types/rrhh';

export interface RrhhService {
  getResumen(filters?: BiFilters): Promise<RrhhResumen>;
  getTrabajadores(filters?: BiFilters): Promise<TrabajadoresResponse>;
}
