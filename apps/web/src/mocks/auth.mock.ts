import type { AuthUser } from '../types/auth';

export const currentUserMock: AuthUser = {
  id: 1,
  username: 'admin.demo',
  displayName: 'Administrador Demo',
  role: 'ADMIN',
};
