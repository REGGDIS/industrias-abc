import {
  Navigate,
  createBrowserRouter,
} from 'react-router-dom';

import {
  RequireAuth,
} from '../auth/RequireAuth';

import {
  RoleRoute,
} from '../auth/RoleRoute';

import {
  AppLayout,
} from '../components/layout/AppLayout';

import {
  AnalisisPage,
} from '../pages/AnalisisPage';

import {
  AsistenciaPage,
} from '../pages/AsistenciaPage';

import {
  CalidadPage,
} from '../pages/CalidadPage';

import {
  ComprasPage,
} from '../pages/ComprasPage';

import {
  ContabilidadPage,
} from '../pages/ContabilidadPage';

import {
  ContratosPage,
} from '../pages/ContratosPage';

import {
  DashboardPage,
} from '../pages/DashboardPage';

import {
  EtlPage,
} from '../pages/EtlPage';

import {
  LoginPage,
} from '../pages/LoginPage';

import {
  ProduccionPage,
} from '../pages/ProduccionPage';

import {
  RemuneracionesPage,
} from '../pages/RemuneracionesPage';

import {
  RrhhPage,
} from '../pages/RrhhPage';

import {
  ROUTES,
} from './routes';


export const router =
  createBrowserRouter([
    {
      path: ROUTES.login,
      element: <LoginPage />,
    },

    {
      element: <RequireAuth />,
      children: [
        {
          element: <AppLayout />,
          children: [
            {
              path:
                ROUTES.dashboard,
              element: (
                <RoleRoute
                  roles={[
                    'ADMIN',
                    'GERENCIA',
                    'RRHH',
                    'COMPRAS',
                    'CONTABILIDAD',
                    'PRODUCCION',
                  ]}
                >
                  <DashboardPage />
                </RoleRoute>
              ),
            },

            {
              path:
                ROUTES.rrhh,
              element: (
                <RoleRoute
                  roles={[
                    'ADMIN',
                    'RRHH',
                  ]}
                >
                  <RrhhPage />
                </RoleRoute>
              ),
            },

            {
              path:
                ROUTES.asistencia,
              element: (
                <RoleRoute
                  roles={[
                    'ADMIN',
                    'RRHH',
                  ]}
                >
                  <AsistenciaPage />
                </RoleRoute>
              ),
            },

            {
              path:
                ROUTES.contratos,
              element: (
                <RoleRoute
                  roles={[
                    'ADMIN',
                    'RRHH',
                  ]}
                >
                  <ContratosPage />
                </RoleRoute>
              ),
            },

            {
              path:
                ROUTES.remuneraciones,
              element: (
                <RoleRoute
                  roles={[
                    'ADMIN',
                    'RRHH',
                  ]}
                >
                  <RemuneracionesPage />
                </RoleRoute>
              ),
            },

            {
              path:
                ROUTES.compras,
              element: (
                <RoleRoute
                  roles={[
                    'ADMIN',
                    'COMPRAS',
                  ]}
                >
                  <ComprasPage />
                </RoleRoute>
              ),
            },

            {
              path:
                ROUTES.contabilidad,
              element: (
                <RoleRoute
                  roles={[
                    'ADMIN',
                    'CONTABILIDAD',
                  ]}
                >
                  <ContabilidadPage />
                </RoleRoute>
              ),
            },

            {
              path:
                ROUTES.produccion,
              element: (
                <RoleRoute
                  roles={[
                    'ADMIN',
                    'PRODUCCION',
                  ]}
                >
                  <ProduccionPage />
                </RoleRoute>
              ),
            },

            {
              path:
                ROUTES.analisis,
              element: (
                <RoleRoute
                  roles={[
                    'ADMIN',
                    'GERENCIA',
                  ]}
                >
                  <AnalisisPage />
                </RoleRoute>
              ),
            },

            {
              path:
                ROUTES.calidad,
              element: (
                <RoleRoute
                  roles={[
                    'ADMIN',
                  ]}
                >
                  <CalidadPage />
                </RoleRoute>
              ),
            },

            {
              path:
                ROUTES.etl,
              element: (
                <RoleRoute
                  roles={[
                    'ADMIN',
                  ]}
                >
                  <EtlPage />
                </RoleRoute>
              ),
            },
          ],
        },
      ],
    },

    {
      path: '/',
      element: (
        <Navigate
          to={ROUTES.dashboard}
          replace
        />
      ),
    },

    {
      path: '*',
      element: (
        <Navigate
          to={ROUTES.dashboard}
          replace
        />
      ),
    },
  ]);
