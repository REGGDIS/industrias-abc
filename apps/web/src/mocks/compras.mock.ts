export interface ProveedorMock {
  proveedorId: number;
  nombre: string;
}

export interface InsumoMock {
  insumoId: number;
  nombre: string;
  precioBase: number;
}

export interface CompraMockRecord {
  ordenCompraId: number;

  fecha: string;
  anio: number;
  mes: number;

  proveedorId: number;
  proveedor: string;

  insumoId: number;
  insumo: string;

  centroCostoId: number;
  centroCosto: string;

  cantidad: number;
  precioUnitario: number;
  total: number;

  cumplida: boolean;
}

export const proveedoresComprasMock: ProveedorMock[] = [
  {
    proveedorId: 1,
    nombre: 'Suministros Industriales Sur',
  },
  {
    proveedorId: 2,
    nombre: 'Comercial Andes',
  },
  {
    proveedorId: 3,
    nombre: 'TecnoEquipos Chile',
  },
  {
    proveedorId: 4,
    nombre: 'Distribuidora Central',
  },
  {
    proveedorId: 5,
    nombre: 'Insumos del Biobío',
  },
  {
    proveedorId: 6,
    nombre: 'Proveedora Pacífico',
  },
];

export const insumosComprasMock: InsumoMock[] = [
  {
    insumoId: 1,
    nombre: 'Acero industrial',
    precioBase: 18500,
  },
  {
    insumoId: 2,
    nombre: 'Lubricante industrial',
    precioBase: 12500,
  },
  {
    insumoId: 3,
    nombre: 'Rodamientos',
    precioBase: 32000,
  },
  {
    insumoId: 4,
    nombre: 'Elementos de protección',
    precioBase: 9500,
  },
  {
    insumoId: 5,
    nombre: 'Material de embalaje',
    precioBase: 4800,
  },
  {
    insumoId: 6,
    nombre: 'Componentes eléctricos',
    precioBase: 28500,
  },
  {
    insumoId: 7,
    nombre: 'Herramientas menores',
    precioBase: 22000,
  },
  {
    insumoId: 8,
    nombre: 'Repuestos de maquinaria',
    precioBase: 45000,
  },
];

const centrosCosto = [
  {
    centroCostoId: 1,
    centroCosto: 'CC-RRHH',
  },
  {
    centroCostoId: 2,
    centroCosto: 'CC-COMPRAS',
  },
  {
    centroCostoId: 3,
    centroCosto: 'CC-CONTABILIDAD',
  },
  {
    centroCostoId: 4,
    centroCosto: 'CC-PRODUCCION',
  },
  {
    centroCostoId: 5,
    centroCosto: 'CC-ADMIN',
  },
];

function formatDate(
  anio: number,
  mes: number,
  dia: number,
) {
  return `${anio}-${String(mes).padStart(
    2,
    '0',
  )}-${String(dia).padStart(2, '0')}`;
}

function buildMonth(
  anio: number,
  mes: number,
  startId: number,
) {
  const records: CompraMockRecord[] = [];

  const totalOrdenes =
    15 + ((anio + mes) % 6);

  for (
    let index = 0;
    index < totalOrdenes;
    index += 1
  ) {
    const seed =
      anio * 7 +
      mes * 31 +
      index * 17;

    const proveedor =
      proveedoresComprasMock[
        seed %
          proveedoresComprasMock.length
      ];

    const insumo =
      insumosComprasMock[
        (seed + index * 3) %
          insumosComprasMock.length
      ];

    const centroCosto =
      centrosCosto[
        (seed + index) %
          centrosCosto.length
      ];

    const cantidad =
      10 + (seed % 91);

    const variacionPrecio =
      0.92 +
      (seed % 17) / 100;

    const precioUnitario =
      Math.round(
        insumo.precioBase *
          variacionPrecio,
      );

    const total =
      cantidad * precioUnitario;

    const dia =
      2 + ((index * 3 + mes) % 25);

    const isFutureMockDate =
      anio === 2026 &&
      mes === 9 &&
      dia > 13;

    if (isFutureMockDate) {
      continue;
    }

    const cumplida =
      seed % 13 !== 0;

    records.push({
      ordenCompraId:
        startId + index,

      fecha: formatDate(
        anio,
        mes,
        dia,
      ),

      anio,
      mes,

      proveedorId:
        proveedor.proveedorId,
      proveedor: proveedor.nombre,

      insumoId: insumo.insumoId,
      insumo: insumo.nombre,

      centroCostoId:
        centroCosto.centroCostoId,
      centroCosto:
        centroCosto.centroCosto,

      cantidad,
      precioUnitario,
      total,

      cumplida,
    });
  }

  return records;
}

function buildCompras() {
  const records: CompraMockRecord[] = [];

  let nextId = 1;

  for (
    let mes = 1;
    mes <= 12;
    mes += 1
  ) {
    const monthRecords =
      buildMonth(
        2025,
        mes,
        nextId,
      );

    records.push(...monthRecords);

    nextId += monthRecords.length;
  }

  for (
    let mes = 1;
    mes <= 9;
    mes += 1
  ) {
    const monthRecords =
      buildMonth(
        2026,
        mes,
        nextId,
      );

    records.push(...monthRecords);

    nextId += monthRecords.length;
  }

  return records;
}

export const comprasMockRecords =
  buildCompras();
