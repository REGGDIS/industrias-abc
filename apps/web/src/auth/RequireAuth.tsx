import {
  Navigate,
  Outlet,
  useLocation,
} from 'react-router-dom';

import {
  ROUTES,
} from '../app/routes';

import {
  useAuth,
} from './AuthContext';


export function RequireAuth() {
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

  return <Outlet />;
}
