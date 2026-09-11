export interface SelectOption {
  id: number | string;
  label: string;
}

export interface KpiValue {
  value: number;
  variation?: number;
  unit?: string;
}

export interface MonthlyValue {
  anio: number;
  mes: number;
  label: string;
  value: number;
}

export interface CategoryValue {
  id?: number | string;
  label: string;
  value: number;
}

export interface Pagination {
  page: number;
  pageSize: number;
  total: number;
}

export interface PaginatedResponse<T> {
  items: T[];
  pagination: Pagination;
}
