import type { LucideIcon } from 'lucide-react';
import type { UserRole } from '../types/auth';

export interface NavigationItem {
  label: string;
  path: string;
  icon: LucideIcon;
  roles?: UserRole[];
}

export interface NavigationGroup {
  label: string;
  items: NavigationItem[];
}
