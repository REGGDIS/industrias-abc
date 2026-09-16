import type {
  CalidadResumen,
} from '../../types/calidad';

export interface CalidadService {
  getResumen(): Promise<CalidadResumen>;
}
