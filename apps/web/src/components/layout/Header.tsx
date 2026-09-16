import { CircleUserRound, LogOut } from 'lucide-react';

import { useNavigate } from 'react-router-dom';

import { ROUTES } from '../../app/routes';
import { useAuth } from '../../auth/AuthContext';
import { runtimeConfig } from '../../config/runtime';
import type { AuthUser } from '../../types/auth';
import { NotificationsPanel } from './NotificationsPanel';

interface HeaderProps {
  user: AuthUser;
}

export function Header({ user }: HeaderProps) {
  const navigate = useNavigate();

  const {
    logout,
  } = useAuth();

  function handleLogout() {
    logout();

    navigate(
      ROUTES.login,
      {
        replace: true,
      },
    );
  }

  return (
    <header className="app-header">
      <div>
        <p className="header-context">Plataforma de Business Intelligence</p>
        <strong>Industrias ABC</strong>
      </div>

      <div className="header-actions">
        <span className="data-mode">
          Datos: {runtimeConfig.dataMode.toUpperCase()}
        </span>

        <NotificationsPanel user={user} />

        <button
          type="button"
          className="icon-button"
          aria-label="Cerrar sesión"
          title="Cerrar sesión"
          onClick={handleLogout}
        >
          <LogOut size={19} />
        </button>

        <div className="user-box">
          <CircleUserRound size={25} />

          <div>
            <strong>{user.displayName}</strong>
            <span>{user.role}</span>
          </div>
        </div>
      </div>
    </header>
  );
}
