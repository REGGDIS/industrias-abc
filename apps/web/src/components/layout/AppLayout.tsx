import { Outlet } from 'react-router-dom';

import { currentUserMock } from '../../mocks/auth.mock';
import { Header } from './Header';
import { Sidebar } from './Sidebar';

export function AppLayout() {
  return (
    <div className="app-shell">
      <Sidebar user={currentUserMock} />

      <div className="app-main">
        <Header user={currentUserMock} />

        <main className="app-content">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
