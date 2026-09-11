export type EtlExecutionStatus =
  | 'RUNNING'
  | 'SUCCESS'
  | 'FAILED'
  | 'PARTIAL';

export interface EtlExecutionMetrics {
  extracted?: number;

  inserted: number;
  updated: number;
  unchanged: number;
  review: number;

  rejected?: number;
  errors?: number;
}

export interface EtlExecution {
  executionId: number | string;

  processName: string;
  sourceName: string;

  startedAt: string;
  finishedAt?: string;

  durationMs?: number;
  status: EtlExecutionStatus;

  metrics: EtlExecutionMetrics;
}
