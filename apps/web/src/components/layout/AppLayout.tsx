import {
  Outlet,
} from 'react-router-dom';

import {
  useAuth,
} from '../../auth/AuthContext';

import {
  Header,
} from './Header';

import {
  Sidebar,
} from './Sidebar';


export function AppLayout() {
  const {
    user,
  } = useAuth();

  if (!user) {
    return null;
  }

  return (
    <div className="app-shell">
      <Sidebar user={user} />

      <div className="app-main">
        <Header user={user} />

        <main className="app-content">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
