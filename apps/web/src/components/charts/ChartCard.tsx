import type { ReactNode } from 'react';

interface ChartCardProps {
  title: string;
  description?: string;
  children: ReactNode;
}

export function ChartCard({
  title,
  description,
  children,
}: ChartCardProps) {
  return (
    <article className="chart-card">
      <div className="chart-card-header">
        <div>
          <h2>{title}</h2>
          {description && <p>{description}</p>}
        </div>
      </div>

      <div className="chart-card-body">
        {children}
      </div>
    </article>
  );
}
