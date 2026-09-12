export interface RrhhMockEmpleado {
  empleadoId: number;
  nombre: string;
  rut: string;

  areaId: number;
  area: string;

  cargoId: number;
  cargo: string;

  fechaIngreso: string;
  fechaSalida?: string;

  estado: 'ACTIVO' | 'INACTIVO';

  tipoContrato: 'INDEFINIDO' | 'PLAZO_FIJO';
  fechaTerminoContrato?: string;
}

interface AreaDefinition {
  areaId: number;
  area: string;
  cantidad: number;
  cargos: Array<{
    cargoId: number;
    cargo: string;
  }>;
}

const areas: AreaDefinition[] = [
  {
    areaId: 1,
    area: 'Recursos Humanos',
    cantidad: 10,
    cargos: [
      { cargoId: 1, cargo: 'Analista de RRHH' },
      { cargoId: 2, cargo: 'Asistente Administrativo' },
      { cargoId: 10, cargo: 'Jefatura' },
    ],
  },
  {
    areaId: 2,
    area: 'Compras y Abastecimiento',
    cantidad: 14,
    cargos: [
      { cargoId: 3, cargo: 'Comprador' },
      { cargoId: 4, cargo: 'Analista de Abastecimiento' },
      { cargoId: 10, cargo: 'Jefatura' },
    ],
  },
  {
    areaId: 3,
    area: 'Contabilidad',
    cantidad: 12,
    cargos: [
      { cargoId: 5, cargo: 'Analista Contable' },
      { cargoId: 6, cargo: 'Contador' },
      { cargoId: 10, cargo: 'Jefatura' },
    ],
  },
  {
    areaId: 4,
    area: 'Producción',
    cantidad: 34,
    cargos: [
      { cargoId: 7, cargo: 'Operario de Producción' },
      { cargoId: 8, cargo: 'Supervisor de Producción' },
      { cargoId: 10, cargo: 'Jefatura' },
    ],
  },
  {
    areaId: 5,
    area: 'Administración',
    cantidad: 10,
    cargos: [
      { cargoId: 9, cargo: 'Administrativo' },
      { cargoId: 2, cargo: 'Asistente Administrativo' },
      { cargoId: 10, cargo: 'Jefatura' },
    ],
  },
];

function pad(value: number) {
  return String(value).padStart(3, '0');
}

function createRutMock(id: number) {
  return `00.000.${pad(id)}-${id % 10}`;
}

function createFechaIngreso(id: number) {
  if (id > 75) {
    return `2026-0${((id - 75) % 8) + 1}-01`;
  }

  if (id > 68) {
    return `2025-${String(((id - 68) % 12) + 1).padStart(2, '0')}-01`;
  }

  const year = 2021 + (id % 4);
  const month = (id % 12) + 1;

  return `${year}-${String(month).padStart(2, '0')}-01`;
}

function createFechaSalida(id: number) {
  if (id === 18) {
    return '2025-05-15';
  }

  if (id === 37) {
    return '2025-11-20';
  }

  if (id === 56) {
    return '2026-03-14';
  }

  if (id === 73) {
    return '2026-08-18';
  }

  return undefined;
}

function createFechaTerminoContrato(id: number) {
  const expirations: Record<number, string> = {
    7: '2026-09-30',
    14: '2026-10-15',
    21: '2026-10-31',
    28: '2026-11-15',
    35: '2026-11-30',
    42: '2026-12-15',
    49: '2027-01-31',
    63: '2027-03-31',
  };

  return expirations[id];
}

function buildEmployees(): RrhhMockEmpleado[] {
  const employees: RrhhMockEmpleado[] = [];

  let empleadoId = 1;

  for (const area of areas) {
    for (let index = 0; index < area.cantidad; index += 1) {
      const cargo = area.cargos[index % area.cargos.length];

      const fechaSalida = createFechaSalida(empleadoId);
      const fechaTerminoContrato =
        createFechaTerminoContrato(empleadoId);

      employees.push({
        empleadoId,
        nombre: `Trabajador Demo ${pad(empleadoId)}`,
        rut: createRutMock(empleadoId),

        areaId: area.areaId,
        area: area.area,

        cargoId: cargo.cargoId,
        cargo: cargo.cargo,

        fechaIngreso: createFechaIngreso(empleadoId),
        fechaSalida,

        estado:
          empleadoId % 17 === 0
            ? 'INACTIVO'
            : 'ACTIVO',

        tipoContrato: fechaTerminoContrato
          ? 'PLAZO_FIJO'
          : 'INDEFINIDO',

        fechaTerminoContrato,
      });

      empleadoId += 1;
    }
  }

  return employees;
}

export const rrhhMockEmpleados = buildEmployees();
