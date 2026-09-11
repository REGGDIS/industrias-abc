import type { UserRole } from '../types/auth';

export interface NavigationItem {
  label: string;
  path: string;
  roles?: UserRole[];
}

export interface NavigationGroup {
  label: string;
  items: NavigationItem[];
}
