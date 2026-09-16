export type QualityIssueStatus =
  | 'CORRECTED'
  | 'REVIEW'
  | 'REJECTED';

export type QualityIssueType =
  | 'RUT_FORMAT'
  | 'DUPLICATE'
  | 'NULL_VALUE'
  | 'INVALID_DATE'
  | 'AREA_NOT_MAPPED'
  | 'COST_CENTER_NOT_MAPPED'
  | 'INVALID_VALUE'
  | 'OTHER';

export interface QualityIssue {
  id: number | string;

  source: string;
  table?: string;
  recordKey?: string;

  type: QualityIssueType;
  description: string;

  action?: string;
  status: QualityIssueStatus;
}

export interface QualitySummary {
  processed: number;
  valid: number;

  inserted?: number;
  updated?: number;
  unchanged?: number;

  corrected: number;
  review: number;
  rejected: number;

  qualityRate: number;
}
