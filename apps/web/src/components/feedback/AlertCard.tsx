import {
  AlertCircle,
  CheckCircle2,
  Info,
  TriangleAlert,
} from 'lucide-react';

export type AlertTone =
  | 'info'
  | 'success'
  | 'warning'
  | 'danger';

interface AlertCardProps {
  title: string;
  description: string;
  tone?: AlertTone;
}

const icons = {
  info: Info,
  success: CheckCircle2,
  warning: TriangleAlert,
  danger: AlertCircle,
};

export function AlertCard({
  title,
  description,
  tone = 'info',
}: AlertCardProps) {
  const Icon = icons[tone];

  return (
    <article className={`alert-card alert-${tone}`}>
      <Icon size={20} strokeWidth={1.8} />

      <div>
        <strong>{title}</strong>
        <p>{description}</p>
      </div>
    </article>
  );
}
