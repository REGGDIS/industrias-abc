import {
  BarChart3,
  Boxes,
  BriefcaseBusiness,
  Building2,
  ClipboardList,
  Factory,
  FileCheck2,
  Landmark,
  ShieldCheck,
  ShoppingCart,
  Users,
} from 'lucide-react';

import type { UserRole } from '../types/auth';
import type { NavigationGroup } from './navigation.types';
import { ROUTES } from './routes';

const ALL_ROLES: UserRole[] = [
  'ADMIN',
  'GERENCIA',
  'RRHH',
  'COMPRAS',
  'CONTABILIDAD',
  'PRODUCCION',
];

export const navigation: NavigationGroup[] = [
  {
    label: 'General',
    items: [
      {
        label: 'Dashboard Ejecutivo',
        path: ROUTES.dashboard,
        icon: BarChart3,
        roles: ALL_ROLES,
      },
    ],
  },
  {
    label: 'Personas',
    items: [
      {
        label: 'Recursos Humanos',
        path: ROUTES.rrhh,
        icon: Users,
        roles: ['ADMIN', 'RRHH'],
      },
      {
        label: 'Asistencia',
        path: ROUTES.asistencia,
        icon: ClipboardList,
        roles: ['ADMIN', 'RRHH'],
      },
      {
        label: 'Contratos',
        path: ROUTES.contratos,
        icon: FileCheck2,
        roles: ['ADMIN', 'RRHH'],
      },
      {
        label: 'Remuneraciones',
        path: ROUTES.remuneraciones,
        icon: BriefcaseBusiness,
        roles: ['ADMIN', 'RRHH'],
      },
    ],
  },
  {
    label: 'Operaciones',
    items: [
      {
        label: 'Compras',
        path: ROUTES.compras,
        icon: ShoppingCart,
        roles: ['ADMIN', 'COMPRAS'],
      },
      {
        label: 'Contabilidad',
        path: ROUTES.contabilidad,
        icon: Landmark,
        roles: ['ADMIN', 'CONTABILIDAD'],
      },
      {
        label: 'Producción',
        path: ROUTES.produccion,
        icon: Factory,
        roles: ['ADMIN', 'PRODUCCION'],
      },
    ],
  },
  {
    label: 'Inteligencia',
    items: [
      {
        label: 'Análisis Integrado',
        path: ROUTES.analisis,
        icon: Boxes,
        roles: ['ADMIN', 'GERENCIA'],
      },
      {
        label: 'Calidad de Datos',
        path: ROUTES.calidad,
        icon: ShieldCheck,
        roles: ['ADMIN'],
      },
    ],
  },
  {
    label: 'Sistema',
    items: [
      {
        label: 'Procesos ETL',
        path: ROUTES.etl,
        icon: Building2,
        roles: ['ADMIN'],
      },
    ],
  },
];

export function getNavigationForRole(role: UserRole): NavigationGroup[] {
  return navigation
    .map((group) => ({
      ...group,
      items: group.items.filter(
        (item) => !item.roles || item.roles.includes(role),
      ),
    }))
    .filter((group) => group.items.length > 0);
}
