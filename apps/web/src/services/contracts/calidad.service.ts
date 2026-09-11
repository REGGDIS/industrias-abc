import type { QualityIssue, QualitySummary } from '../../types/quality';

export interface CalidadService {
  getResumen(): Promise<QualitySummary>;
  getIssues(): Promise<QualityIssue[]>;
}
