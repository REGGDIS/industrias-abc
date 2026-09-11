import type { LucideIcon } from 'lucide-react';

import { VariationBadge } from './VariationBadge';

interface KpiCardProps {
  title: string;
  value: string | number;
  helper?: string;
  variation?: number;
  icon?: LucideIcon;
}

export function KpiCard({
  title,
  value,
  helper,
  variation,
  icon: Icon,
}: KpiCardProps) {
  return (
    <article className="kpi-card">
      <div className="kpi-card-header">
        <span className="kpi-title">{title}</span>

        {Icon && (
          <span className="kpi-icon" aria-hidden="true">
            <Icon size={18} strokeWidth={1.8} />
          </span>
        )}
      </div>

      <div className="kpi-value">{value}</div>

      {(helper || variation !== undefined) && (
        <div className="kpi-footer">
          {variation !== undefined && (
            <VariationBadge value={variation} />
          )}

          {helper && <span className="kpi-helper">{helper}</span>}
        </div>
      )}
    </article>
  );
}
