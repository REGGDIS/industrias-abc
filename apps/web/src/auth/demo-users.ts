import type {
  AuthUser,
  LoginRequest,
} from '../types/auth';

interface DemoCredential {
  username: string;
  password: string;
  user: AuthUser;
}

const DEMO_USERS:
  DemoCredential[] = [
    {
      username: 'admin.demo',
      password: 'Admin123!',
      user: {
        id: 1,
        username: 'admin.demo',
        displayName:
          'Administrador Demo',
        role: 'ADMIN',
      },
    },
    {
      username: 'gerencia.demo',
      password: 'Gerencia123!',
      user: {
        id: 2,
        username: 'gerencia.demo',
        displayName:
          'Gerencia Demo',
        role: 'GERENCIA',
      },
    },
    {
      username: 'rrhh.demo',
      password: 'Rrhh123!',
      user: {
        id: 3,
        username: 'rrhh.demo',
        displayName:
          'RRHH Demo',
        role: 'RRHH',
      },
    },
    {
      username: 'compras.demo',
      password: 'Compras123!',
      user: {
        id: 4,
        username: 'compras.demo',
        displayName:
          'Compras Demo',
        role: 'COMPRAS',
      },
    },
    {
      username:
        'contabilidad.demo',
      password:
        'Contabilidad123!',
      user: {
        id: 5,
        username:
          'contabilidad.demo',
        displayName:
          'Contabilidad Demo',
        role: 'CONTABILIDAD',
      },
    },
    {
      username:
        'produccion.demo',
      password:
        'Produccion123!',
      user: {
        id: 6,
        username:
          'produccion.demo',
        displayName:
          'Producción Demo',
        role: 'PRODUCCION',
      },
    },
  ];

export function authenticateDemo(
  request: LoginRequest,
): AuthUser | null {
  const match =
    DEMO_USERS.find(
      (credential) =>
        credential.username ===
          request.username.trim() &&
        credential.password ===
          request.password,
    );

  return match?.user ?? null;
}
