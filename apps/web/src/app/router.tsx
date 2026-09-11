import {
  Navigate,
  createBrowserRouter,
} from 'react-router-dom';

import { AppLayout } from '../components/layout/AppLayout';
import { AnalisisPage } from '../pages/AnalisisPage';
import { AsistenciaPage } from '../pages/AsistenciaPage';
import { CalidadPage } from '../pages/CalidadPage';
import { ComprasPage } from '../pages/ComprasPage';
import { ContabilidadPage } from '../pages/ContabilidadPage';
import { ContratosPage } from '../pages/ContratosPage';
import { DashboardPage } from '../pages/DashboardPage';
import { EtlPage } from '../pages/EtlPage';
import { LoginPage } from '../pages/LoginPage';
import { ProduccionPage } from '../pages/ProduccionPage';
import { RemuneracionesPage } from '../pages/RemuneracionesPage';
import { RrhhPage } from '../pages/RrhhPage';
import { ROUTES } from './routes';

export const router = createBrowserRouter([
  {
    path: ROUTES.login,
    element: <LoginPage />,
  },
  {
    element: <AppLayout />,
    children: [
      {
        path: ROUTES.dashboard,
        element: <DashboardPage />,
      },
      {
        path: ROUTES.rrhh,
        element: <RrhhPage />,
      },
      {
        path: ROUTES.asistencia,
        element: <AsistenciaPage />,
      },
      {
        path: ROUTES.contratos,
        element: <ContratosPage />,
      },
      {
        path: ROUTES.remuneraciones,
        element: <RemuneracionesPage />,
      },
      {
        path: ROUTES.compras,
        element: <ComprasPage />,
      },
      {
        path: ROUTES.contabilidad,
        element: <ContabilidadPage />,
      },
      {
        path: ROUTES.produccion,
        element: <ProduccionPage />,
      },
      {
        path: ROUTES.analisis,
        element: <AnalisisPage />,
      },
      {
        path: ROUTES.calidad,
        element: <CalidadPage />,
      },
      {
        path: ROUTES.etl,
        element: <EtlPage />,
      },
    ],
  },
  {
    path: '/',
    element: <Navigate to={ROUTES.dashboard} replace />,
  },
  {
    path: '*',
    element: <Navigate to={ROUTES.dashboard} replace />,
  },
]);
