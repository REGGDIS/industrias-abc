import type { SelectOption } from '../../types/common';

interface FilterSelectProps {
  label: string;
  value?: number | string;
  options: SelectOption[];
  placeholder?: string;
  onChange: (value: string) => void;
}

export function FilterSelect({
  label,
  value,
  options,
  placeholder = 'Todos',
  onChange,
}: FilterSelectProps) {
  return (
    <label className="filter-field">
      <span>{label}</span>

      <select
        value={value ?? ''}
        onChange={(event) => onChange(event.target.value)}
      >
        <option value="">{placeholder}</option>

        {options.map((option) => (
          <option key={option.id} value={option.id}>
            {option.label}
          </option>
        ))}
      </select>
    </label>
  );
}
