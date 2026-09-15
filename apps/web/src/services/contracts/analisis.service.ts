import type {
  AnalisisResumen,
} from '../../types/analisis';

export interface AnalisisService {
  getResumen(): Promise<AnalisisResumen>;
}
