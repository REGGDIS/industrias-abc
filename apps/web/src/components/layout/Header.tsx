import { Bell, CircleUserRound } from 'lucide-react';

import { runtimeConfig } from '../../config/runtime';
import type { AuthUser } from '../../types/auth';

interface HeaderProps {
  user: AuthUser;
}

export function Header({ user }: HeaderProps) {
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

        <button
          type="button"
          className="icon-button"
          aria-label="Notificaciones"
        >
          <Bell size={19} />
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
