import { ArrowDownRight, ArrowRight, ArrowUpRight } from 'lucide-react';

interface VariationBadgeProps {
  value: number;
  suffix?: string;
}

export function VariationBadge({
  value,
  suffix = '%',
}: VariationBadgeProps) {
  const isPositive = value > 0;
  const isNegative = value < 0;

  const className = isPositive
    ? 'variation-badge variation-positive'
    : isNegative
      ? 'variation-badge variation-negative'
      : 'variation-badge variation-neutral';

  const Icon = isPositive
    ? ArrowUpRight
    : isNegative
      ? ArrowDownRight
      : ArrowRight;

  return (
    <span className={className}>
      <Icon size={14} strokeWidth={2} />
      {Math.abs(value).toLocaleString('es-CL')}
      {suffix}
    </span>
  );
}
