import type {
  ReactNode,
} from 'react';

import type {
  UserRole,
} from '../types/auth';

import {
  RequireRole,
} from './RequireRole';


interface RoleRouteProps {
  roles: UserRole[];
  children: ReactNode;
}


export function RoleRoute({
  roles,
  children,
}: RoleRouteProps) {
  return (
    <RequireRole
      roles={roles}
    >
      {children}
    </RequireRole>
  );
}
