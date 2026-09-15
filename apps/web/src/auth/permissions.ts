import type {
  UserRole,
} from '../types/auth';

import { ROUTES } from '../app/routes';

export const ROUTE_ROLES:
  Record<string, UserRole[]> = {
    [ROUTES.dashboard]: [
      'ADMIN',
      'GERENCIA',
      'RRHH',
      'COMPRAS',
      'CONTABILIDAD',
      'PRODUCCION',
    ],
    [ROUTES.rrhh]: [
      'ADMIN',
      'RRHH',
    ],
    [ROUTES.asistencia]: [
      'ADMIN',
      'RRHH',
    ],
    [ROUTES.contratos]: [
      'ADMIN',
      'RRHH',
    ],
    [ROUTES.remuneraciones]: [
      'ADMIN',
      'RRHH',
    ],
    [ROUTES.compras]: [
      'ADMIN',
      'COMPRAS',
    ],
    [ROUTES.contabilidad]: [
      'ADMIN',
      'CONTABILIDAD',
    ],
    [ROUTES.produccion]: [
      'ADMIN',
      'PRODUCCION',
    ],
    [ROUTES.analisis]: [
      'ADMIN',
      'GERENCIA',
    ],
    [ROUTES.calidad]: [
      'ADMIN',
    ],
    [ROUTES.etl]: [
      'ADMIN',
    ],
  };

export function canAccessRoute(
  role: UserRole,
  path: string,
): boolean {
  const roles =
    ROUTE_ROLES[path];

  if (!roles) {
    return false;
  }

  return roles.includes(role);
}
