import type {
  AuthUser,
} from '../types/auth';

const SESSION_KEY =
  'industrias-abc-bi-session';

export interface AuthSession {
  user: AuthUser;
}

export function getSession():
  AuthSession | null {
  const raw =
    localStorage.getItem(
      SESSION_KEY,
    );

  if (!raw) {
    return null;
  }

  try {
    return JSON.parse(
      raw,
    ) as AuthSession;
  } catch {
    localStorage.removeItem(
      SESSION_KEY,
    );

    return null;
  }
}

export function saveSession(
  session: AuthSession,
): void {
  localStorage.setItem(
    SESSION_KEY,
    JSON.stringify(session),
  );
}

export function clearSession(): void {
  localStorage.removeItem(
    SESSION_KEY,
  );
}
