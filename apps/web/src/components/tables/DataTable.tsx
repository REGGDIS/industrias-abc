import type { ReactNode } from 'react';

export interface DataTableColumn<T> {
  key: string;
  label: string;
  align?: 'left' | 'center' | 'right';
  render: (row: T) => ReactNode;
}

interface DataTableProps<T> {
  columns: DataTableColumn<T>[];
  rows: T[];
  getRowKey: (row: T) => string | number;
  emptyMessage?: string;
}

export function DataTable<T>({
  columns,
  rows,
  getRowKey,
  emptyMessage = 'No hay datos disponibles.',
}: DataTableProps<T>) {
  if (rows.length === 0) {
    return (
      <div className="data-table-empty">
        {emptyMessage}
      </div>
    );
  }

  return (
    <div className="data-table-wrapper">
      <table className="data-table">
        <thead>
          <tr>
            {columns.map((column) => (
              <th
                key={column.key}
                className={`align-${column.align ?? 'left'}`}
              >
                {column.label}
              </th>
            ))}
          </tr>
        </thead>

        <tbody>
          {rows.map((row) => (
            <tr key={getRowKey(row)}>
              {columns.map((column) => (
                <td
                  key={column.key}
                  className={`align-${column.align ?? 'left'}`}
                >
                  {column.render(row)}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
