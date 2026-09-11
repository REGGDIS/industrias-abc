import { Navigate } from 'react-router-dom';
import { ROUTES } from '../app/routes';

export function LoginPage() {
  return <Navigate to={ROUTES.dashboard} replace />;
}
