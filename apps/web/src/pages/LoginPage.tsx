import {
  useState,
  type FormEvent,
} from 'react';

import {
  Eye,
  EyeOff,
  LockKeyhole,
  ShieldCheck,
  UserRound,
} from 'lucide-react';

import {
  Navigate,
  useLocation,
  useNavigate,
} from 'react-router-dom';

import {
  ROUTES,
} from '../app/routes';

import {
  useAuth,
} from '../auth/AuthContext';


interface LocationState {
  from?: string;
}


const demoUsers = [
  {
    role: 'ADMIN',
    username: 'admin.demo',
    password: 'Admin123!',
  },
  {
    role: 'GERENCIA',
    username: 'gerencia.demo',
    password: 'Gerencia123!',
  },
  {
    role: 'RRHH',
    username: 'rrhh.demo',
    password: 'Rrhh123!',
  },
  {
    role: 'COMPRAS',
    username: 'compras.demo',
    password: 'Compras123!',
  },
  {
    role: 'CONTABILIDAD',
    username: 'contabilidad.demo',
    password: 'Contabilidad123!',
  },
  {
    role: 'PRODUCCIÓN',
    username: 'produccion.demo',
    password: 'Produccion123!',
  },
];


export function LoginPage() {
  const {
    user,
    login,
  } = useAuth();

  const navigate =
    useNavigate();

  const location =
    useLocation();

  const [
    username,
    setUsername,
  ] = useState(
    'admin.demo',
  );

  const [
    password,
    setPassword,
  ] = useState(
    'Admin123!',
  );

  const [
    error,
    setError,
  ] = useState<string | null>(
    null,
  );

  const [
    showPassword,
    setShowPassword,
  ] = useState(false);


  if (user) {
    return (
      <Navigate
        to={ROUTES.dashboard}
        replace
      />
    );
  }


  function handleSubmit(
    event: FormEvent<HTMLFormElement>,
  ) {
    event.preventDefault();

    const ok =
      login({
        username,
        password,
      });

    if (!ok) {
      setError(
        'Usuario o contraseña incorrectos.',
      );

      return;
    }

    const state =
      location.state as
        | LocationState
        | null;

    navigate(
      state?.from
        ?? ROUTES.dashboard,
      {
        replace: true,
      },
    );
  }


  return (
    <main className="login-page">
      <div className="login-shell">
        <section className="login-visual">
          <div className="login-visual-content">
            <div className="login-visual-badge">
              <ShieldCheck size={18} />
              Plataforma segura por roles
            </div>

            <div>
              <p className="login-visual-kicker">
                Business Intelligence
              </p>

              <h2>
                Información integrada para
                mejores decisiones.
              </h2>

              <p>
                Accede a indicadores,
                análisis y procesos
                operacionales de Industrias
                ABC según tu perfil
                funcional.
              </p>
            </div>

            <div className="login-visual-footer">
              <span>
                BINNOVA
              </span>

              <small>
                Plataforma BI · Industrias ABC
              </small>
            </div>
          </div>
        </section>

        <section className="login-card">
          <div className="login-brand">
            <div className="login-brand-mark">
              BI
            </div>

            <div>
              <strong>
                BINNOVA
              </strong>

              <span>
                Industrias ABC
              </span>
            </div>
          </div>

          <div className="login-heading">
            <p className="page-eyebrow">
              ACCESO AL SISTEMA
            </p>

            <h1>
              Iniciar sesión
            </h1>

            <p>
              Ingresa tus credenciales
              para acceder a los módulos
              habilitados para tu rol.
            </p>
          </div>

          <form
            className="login-form"
            onSubmit={
              handleSubmit
            }
          >
            <label>
              Usuario

              <div className="login-input-wrap">
                <UserRound
                  size={18}
                  className="login-input-icon"
                />

                <input
                  type="text"
                  value={username}
                  onChange={(event) =>
                    setUsername(
                      event.target.value,
                    )
                  }
                  autoComplete="username"
                />
              </div>
            </label>

            <label>
              Contraseña

              <div className="login-input-wrap">
                <LockKeyhole
                  size={18}
                  className="login-input-icon"
                />

                <input
                  type={
                    showPassword
                      ? 'text'
                      : 'password'
                  }
                  value={password}
                  onChange={(event) =>
                    setPassword(
                      event.target.value,
                    )
                  }
                  autoComplete="current-password"
                />

                <button
                  type="button"
                  className="login-password-toggle"
                  aria-label={
                    showPassword
                      ? 'Ocultar contraseña'
                      : 'Mostrar contraseña'
                  }
                  title={
                    showPassword
                      ? 'Ocultar contraseña'
                      : 'Mostrar contraseña'
                  }
                  onClick={() =>
                    setShowPassword(
                      (current) => !current,
                    )
                  }
                >
                  {showPassword ? (
                    <EyeOff size={18} />
                  ) : (
                    <Eye size={18} />
                  )}
                </button>
              </div>
            </label>

            {error ? (
              <div className="login-error">
                {error}
              </div>
            ) : null}

            <button
              type="submit"
              className="login-button"
            >
              Ingresar a BINNOVA
            </button>
          </form>

          <div className="login-demo">
            <div className="login-demo-header">
              <div>
                <strong>
                  Usuarios de demostración
                </strong>

                <span>
                  Selecciona un perfil para
                  validar permisos por rol.
                </span>
              </div>
            </div>

            <div className="login-demo-grid">
              {demoUsers.map(
                (item) => (
                  <button
                    key={item.username}
                    type="button"
                    className="login-demo-user"
                    onClick={() => {
                      setUsername(
                        item.username,
                      );

                      setPassword(
                        item.password,
                      );

                      setError(null);
                    }}
                  >
                    <span>
                      {item.role}
                    </span>

                    <strong>
                      {item.username}
                    </strong>

                    <small>
                      Clave: {item.password}
                    </small>
                  </button>
                ),
              )}
            </div>
          </div>
        </section>
      </div>
    </main>
  );
}
