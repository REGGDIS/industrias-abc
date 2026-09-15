import {
  Navigate,
  useLocation,
} from 'react-router-dom';

import type {
  ReactNode,
} from 'react';

import type {
  UserRole,
} from '../types/auth';

import {
  ROUTES,
} from '../app/routes';

import {
  useAuth,
} from './AuthContext';


interface RequireRoleProps {
  roles: UserRole[];
  children: ReactNode;
}


export function RequireRole({
  roles,
  children,
}: RequireRoleProps) {
  const {
    user,
  } = useAuth();

  const location =
    useLocation();


  if (!user) {
    return (
      <Navigate
        to={ROUTES.login}
        replace
        state={{
          from:
            location.pathname,
        }}
      />
    );
  }


  if (
    !roles.includes(
      user.role,
    )
  ) {
    return (
      <Navigate
        to={ROUTES.dashboard}
        replace
      />
    );
  }


  return children;
}
