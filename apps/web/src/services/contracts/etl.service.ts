import type {
  EtlResumen,
} from '../../types/etl';

export interface EtlService {
  getResumen(): Promise<EtlResumen>;
}
