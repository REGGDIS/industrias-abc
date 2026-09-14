import type { EtlExecution } from '../../types/etl';

export interface EtlService {
  getExecutions(): Promise<EtlExecution[]>;
  getLatestExecution(): Promise<EtlExecution | null>;
}
