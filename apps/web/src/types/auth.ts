export type UserRole =
  | 'ADMIN'
  | 'GERENCIA'
  | 'RRHH'
  | 'COMPRAS'
  | 'CONTABILIDAD'
  | 'PRODUCCION';

export interface AuthUser {
  id: number | string;
  username: string;
  displayName: string;
  role: UserRole;
}

export interface LoginRequest {
  username: string;
  password: string;
}

export interface LoginResponse {
  user: AuthUser;
  token?: string;
}
