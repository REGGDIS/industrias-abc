interface ModulePlaceholderProps {
  title: string;
  description: string;
}

export function ModulePlaceholder({
  title,
  description,
}: ModulePlaceholderProps) {
  return (
    <section className="module-page">
      <div className="page-heading">
        <div>
          <p className="page-eyebrow">Industrias ABC</p>
          <h1>{title}</h1>
          <p>{description}</p>
        </div>

        <span className="status-chip">Modo mock</span>
      </div>

      <div className="placeholder-card">
        <h2>Módulo preparado</h2>
        <p>
          La infraestructura de esta pantalla ya está disponible. Los KPI,
          filtros, gráficos, tablas y mocks funcionales se incorporarán en los
          siguientes hitos.
        </p>
      </div>
    </section>
  );
}
