import { NavLink } from 'react-router-dom';

import { getNavigationForRole } from '../../app/navigation';
import type { AuthUser } from '../../types/auth';

interface SidebarProps {
  user: AuthUser;
}

export function Sidebar({ user }: SidebarProps) {
  const groups = getNavigationForRole(user.role);

  return (
    <aside className="sidebar">
      <div className="sidebar-brand">
        <div className="brand-mark">BI</div>

        <div>
          <strong>BINNOVA</strong>
          <span>Industrias ABC</span>
        </div>
      </div>

      <nav className="sidebar-navigation">
        {groups.map((group) => (
          <section className="nav-group" key={group.label}>
            <p className="nav-group-title">{group.label}</p>

            {group.items.map((item) => {
              const Icon = item.icon;

              return (
                <NavLink
                  key={item.path}
                  to={item.path}
                  className={({ isActive }) =>
                    isActive ? 'nav-item nav-item-active' : 'nav-item'
                  }
                >
                  <Icon size={18} strokeWidth={1.8} />
                  <span>{item.label}</span>
                </NavLink>
              );
            })}
          </section>
        ))}
      </nav>
    </aside>
  );
}
