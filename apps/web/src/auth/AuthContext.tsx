import {
  createContext,
  useContext,
  useMemo,
  useState,
  type ReactNode,
} from 'react';

import type {
  AuthUser,
  LoginRequest,
} from '../types/auth';

import {
  authenticateDemo,
} from './demo-users';

import {
  clearSession,
  getSession,
  saveSession,
} from './session';


interface AuthContextValue {
  user: AuthUser | null;
  login: (
    request: LoginRequest,
  ) => boolean;
  logout: () => void;
}


const AuthContext =
  createContext<AuthContextValue | null>(
    null,
  );


export function AuthProvider({
  children,
}: {
  children: ReactNode;
}) {
  const initialSession =
    getSession();

  const [
    user,
    setUser,
  ] = useState<AuthUser | null>(
    initialSession?.user ?? null,
  );


  const value = useMemo(
    () => ({
      user,

      login(
        request: LoginRequest,
      ) {
        const authenticatedUser =
          authenticateDemo(request);

        if (!authenticatedUser) {
          return false;
        }

        saveSession({
          user: authenticatedUser,
        });

        setUser(
          authenticatedUser,
        );

        return true;
      },

      logout() {
        clearSession();
        setUser(null);
      },
    }),
    [user],
  );


  return (
    <AuthContext.Provider
      value={value}
    >
      {children}
    </AuthContext.Provider>
  );
}


export function useAuth():
  AuthContextValue {
  const context =
    useContext(AuthContext);

  if (!context) {
    throw new Error(
      'useAuth debe utilizarse dentro de AuthProvider.',
    );
  }

  return context;
}
