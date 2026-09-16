import { useEffect, useMemo, useState } from 'react';
import {
  AlertTriangle,
  Bell,
  CircleAlert,
  Info,
} from 'lucide-react';
import { useNavigate } from 'react-router-dom';

import { ROUTES } from '../../app/routes';
import { canAccessRoute } from '../../auth/permissions';
import { calidadService } from '../../services/calidad.service';
import { etlService } from '../../services/etl.service';
import type { AuthUser } from '../../types/auth';
import type { CalidadResumen } from '../../types/calidad';
import type { EtlResumen } from '../../types/etl';

type NotificationTone = 'danger' | 'warning' | 'info';

interface NotificationItem {
  id: string;
  title: string;
  message: string;
  tone: NotificationTone;
  path: string;
}

interface NotificationsPanelProps {
  user: AuthUser;
}

function buildNotifications(
  etl: EtlResumen | null,
  calidad: CalidadResumen | null,
): NotificationItem[] {
  const items: NotificationItem[] = [];

  if (etl) {
    etl.ultimasEjecuciones
      .filter((execution) => execution.status !== 'SUCCESS')
      .slice(0, 3)
      .forEach((execution) => {
        const isError = execution.status === 'ERROR';

        items.push({
          id: `etl-${execution.executionId}`,
          title: `ETL ${execution.source}`,
          message:
            execution.message ??
            `${execution.status}: ${execution.recordsReview} en revisión y ${execution.recordsRejected} rechazados.`,
          tone: isError ? 'danger' : 'warning',
          path: ROUTES.etl,
        });
      });
  }

  if (calidad) {
    calidad.dominios
      .filter(
        (domain) =>
          domain.estado === 'INCIDENCIA' ||
          domain.estado === 'ADVERTENCIA',
      )
      .slice(0, 3)
      .forEach((domain) => {
        const details = [
          domain.areaDesconocida > 0
            ? `${domain.areaDesconocida} área(s) sin homologar`
            : null,
          domain.centroCostoDesconocido > 0
            ? `${domain.centroCostoDesconocido} centro(s) de costo sin homologar`
            : null,
        ]
          .filter(Boolean)
          .join(' · ');

        items.push({
          id: `calidad-${domain.dominio}`,
          title: `Calidad ${domain.dominio}`,
          message:
            details ||
            `${domain.registrosConIncidencia} registro(s) con incidencia.`,
          tone:
            domain.estado === 'INCIDENCIA'
              ? 'danger'
              : 'warning',
          path: ROUTES.calidad,
        });
      });
  }

  return items.slice(0, 6);
}

export function NotificationsPanel({
  user,
}: NotificationsPanelProps) {
  const navigate = useNavigate();
  const [isOpen, setIsOpen] = useState(false);
  const [items, setItems] = useState<NotificationItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const canViewEtl = useMemo(
    () => canAccessRoute(user.role, ROUTES.etl),
    [user.role],
  );

  const canViewCalidad = useMemo(
    () => canAccessRoute(user.role, ROUTES.calidad),
    [user.role],
  );

  useEffect(() => {
    let cancelled = false;

    async function loadNotifications() {
      setLoading(true);
      setError(null);

      try {
        const [etl, calidad] = await Promise.all([
          canViewEtl
            ? etlService.getResumen()
            : Promise.resolve(null),
          canViewCalidad
            ? calidadService.getResumen()
            : Promise.resolve(null),
        ]);

        if (!cancelled) {
          setItems(
            buildNotifications(
              etl,
              calidad,
            ),
          );
        }
      } catch {
        if (!cancelled) {
          setError(
            'No fue posible actualizar las notificaciones.',
          );
        }
      } finally {
        if (!cancelled) {
          setLoading(false);
        }
      }
    }

    void loadNotifications();

    return () => {
      cancelled = true;
    };
  }, [canViewCalidad, canViewEtl]);

  function openNotification(item: NotificationItem) {
    setIsOpen(false);
    navigate(item.path);
  }

  return (
    <div className="notification-center">
      <button
        type="button"
        className="icon-button notification-button"
        aria-label="Notificaciones"
        title="Notificaciones"
        aria-expanded={isOpen}
        onClick={() => setIsOpen((value) => !value)}
      >
        <Bell size={19} />

        {items.length > 0 && (
          <span className="notification-badge">
            {items.length}
          </span>
        )}
      </button>

      {isOpen && (
        <div
          className="notification-panel"
          role="dialog"
          aria-label="Centro de notificaciones"
        >
          <div className="notification-panel-header">
            <div>
              <strong>Notificaciones</strong>
              <span>
                Alertas operacionales de la plataforma BI
              </span>
            </div>

            {items.length > 0 && (
              <span className="notification-summary">
                {items.length} activa{items.length === 1 ? '' : 's'}
              </span>
            )}
          </div>

          <div className="notification-list">
            {loading && (
              <p className="notification-empty">
                Actualizando alertas...
              </p>
            )}

            {!loading && error && (
              <div className="notification-system-message">
                <CircleAlert size={17} />
                <span>{error}</span>
              </div>
            )}

            {!loading &&
              !error &&
              !canViewEtl &&
              !canViewCalidad && (
                <div className="notification-system-message">
                  <Info size={17} />
                  <span>
                    No hay alertas operacionales disponibles para este rol.
                  </span>
                </div>
              )}

            {!loading &&
              !error &&
              (canViewEtl || canViewCalidad) &&
              items.length === 0 && (
                <div className="notification-system-message">
                  <Info size={17} />
                  <span>
                    Sin alertas operacionales activas.
                  </span>
                </div>
              )}

            {!loading &&
              !error &&
              items.map((item) => (
                <button
                  key={item.id}
                  type="button"
                  className={`notification-item notification-item--${item.tone}`}
                  onClick={() => openNotification(item)}
                >
                  <span className="notification-item-icon">
                    {item.tone === 'danger' ? (
                      <CircleAlert size={17} />
                    ) : (
                      <AlertTriangle size={17} />
                    )}
                  </span>

                  <span className="notification-item-content">
                    <strong>{item.title}</strong>
                    <span>{item.message}</span>
                  </span>
                </button>
              ))}
          </div>

          {(canViewEtl || canViewCalidad) && (
            <div className="notification-panel-footer">
              {canViewEtl && (
                <button
                  type="button"
                  onClick={() => {
                    setIsOpen(false);
                    navigate(ROUTES.etl);
                  }}
                >
                  Ver ETL
                </button>
              )}

              {canViewCalidad && (
                <button
                  type="button"
                  onClick={() => {
                    setIsOpen(false);
                    navigate(ROUTES.calidad);
                  }}
                >
                  Ver Calidad
                </button>
              )}
            </div>
          )}
        </div>
      )}
    </div>
  );
}
