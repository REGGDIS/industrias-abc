export interface CuentaContableMock {
  cuentaContableId: number;
  codigo: string;
  nombre: string;
  tipo: 'GASTO' | 'CONTRAPARTIDA';
}

export interface MovimientoContableMock {
  movimientoId: number;

  fecha: string;
  anio: number;
  mes: number;

  cuentaContableId: number;
  cuentaContable: string;

  centroCostoId: number;
  centroCosto: string;

  areaId: number;
  area: string;

  documento: string;

  debe: number;
  haber: number;
}

export const cuentasContablesMock: CuentaContableMock[] = [
  {
    cuentaContableId: 1,
    codigo: '5101',
    nombre: 'Materias primas e insumos',
    tipo: 'GASTO',
  },
  {
    cuentaContableId: 2,
    codigo: '5102',
    nombre: 'Mantención y reparaciones',
    tipo: 'GASTO',
  },
  {
    cuentaContableId: 3,
    codigo: '5103',
    nombre: 'Servicios básicos',
    tipo: 'GASTO',
  },
  {
    cuentaContableId: 4,
    codigo: '5104',
    nombre: 'Remuneraciones',
    tipo: 'GASTO',
  },
  {
    cuentaContableId: 5,
    codigo: '5105',
    nombre: 'Logística y transporte',
    tipo: 'GASTO',
  },
  {
    cuentaContableId: 6,
    codigo: '2101',
    nombre: 'Proveedores por pagar',
    tipo: 'CONTRAPARTIDA',
  },
  {
    cuentaContableId: 7,
    codigo: '1101',
    nombre: 'Banco',
    tipo: 'CONTRAPARTIDA',
  },
];

export const cuentasGastoMock =
  cuentasContablesMock.filter(
    (cuenta) => cuenta.tipo === 'GASTO',
  );

const centrosCosto = [
  {
    centroCostoId: 1,
    centroCosto: 'CC-RRHH',
    areaId: 1,
    area: 'Recursos Humanos',
  },
  {
    centroCostoId: 2,
    centroCosto: 'CC-COMPRAS',
    areaId: 2,
    area: 'Compras y Abastecimiento',
  },
  {
    centroCostoId: 3,
    centroCosto: 'CC-CONTABILIDAD',
    areaId: 3,
    area: 'Contabilidad',
  },
  {
    centroCostoId: 4,
    centroCosto: 'CC-PRODUCCION',
    areaId: 4,
    area: 'Producción',
  },
  {
    centroCostoId: 5,
    centroCosto: 'CC-ADMIN',
    areaId: 5,
    area: 'Administración',
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
  const records: MovimientoContableMock[] = [];

  const cantidadEventos =
    13 + ((anio + mes) % 6);

  let movimientoId = startId;

  for (
    let index = 0;
    index < cantidadEventos;
    index += 1
  ) {
    const seed =
      anio * 13 +
      mes * 29 +
      index * 17;

    const dia =
      2 + ((index * 3 + mes) % 25);

    if (
      anio === 2026 &&
      mes === 9 &&
      dia > 13
    ) {
      continue;
    }

    const cuentaGasto =
      cuentasGastoMock[
        seed % cuentasGastoMock.length
      ];

    const contrapartida =
      seed % 3 === 0
        ? cuentasContablesMock[6]
        : cuentasContablesMock[5];

    const centroCosto =
      centrosCosto[
        (seed + index) %
          centrosCosto.length
      ];

    const montoBase =
      180000 +
      (seed % 1600000);

    const monto =
      Math.round(
        montoBase *
          (1 + (mes % 4) * 0.03),
      );

    const documento =
      `DOC-${anio}-${String(mes).padStart(
        2,
        '0',
      )}-${String(index + 1).padStart(
        3,
        '0',
      )}`;

    const fecha = formatDate(
      anio,
      mes,
      dia,
    );

    records.push({
      movimientoId,
      fecha,
      anio,
      mes,

      cuentaContableId:
        cuentaGasto.cuentaContableId,
      cuentaContable:
        `${cuentaGasto.codigo} - ${cuentaGasto.nombre}`,

      centroCostoId:
        centroCosto.centroCostoId,
      centroCosto:
        centroCosto.centroCosto,

      areaId:
        centroCosto.areaId,
      area:
        centroCosto.area,

      documento,

      debe: monto,
      haber: 0,
    });

    movimientoId += 1;

    records.push({
      movimientoId,
      fecha,
      anio,
      mes,

      cuentaContableId:
        contrapartida.cuentaContableId,
      cuentaContable:
        `${contrapartida.codigo} - ${contrapartida.nombre}`,

      centroCostoId:
        centroCosto.centroCostoId,
      centroCosto:
        centroCosto.centroCosto,

      areaId:
        centroCosto.areaId,
      area:
        centroCosto.area,

      documento,

      debe: 0,
      haber: monto,
    });

    movimientoId += 1;
  }

  return records;
}

function buildContabilidad() {
  const records: MovimientoContableMock[] = [];

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

export const contabilidadMockRecords =
  buildContabilidad();
