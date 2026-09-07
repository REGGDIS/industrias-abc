import os
from dataclasses import dataclass
from pathlib import Path

from dotenv import load_dotenv


ETL_DIR = Path(__file__).resolve().parents[1]
ENV_FILE = ETL_DIR / ".env"

load_dotenv(ENV_FILE)


@dataclass(frozen=True)
class DatabaseConfig:
    host: str
    port: int
    database: str
    user: str
    password: str


def _get_env(name: str, allow_empty: bool = False) -> str:
    value = os.getenv(name)

    if value is None:
        raise RuntimeError(
            f"La variable de entorno requerida '{name}' no está definida."
        )

    value = value.strip()

    if not allow_empty and value == "":
        raise RuntimeError(
            f"La variable de entorno requerida '{name}' está vacía."
        )

    return value


def _get_database_config(prefix: str) -> DatabaseConfig:
    return DatabaseConfig(
        host=_get_env(f"{prefix}_DB_HOST"),
        port=int(_get_env(f"{prefix}_DB_PORT")),
        database=_get_env(f"{prefix}_DB_NAME"),
        user=_get_env(f"{prefix}_DB_USER"),
        password=_get_env(f"{prefix}_DB_PASSWORD", allow_empty=True),
    )


def get_rrhh_db_config() -> DatabaseConfig:
    return _get_database_config("RRHH")


def get_compras_db_config() -> DatabaseConfig:
    return _get_database_config("COMPRAS")


def get_contabilidad_db_config() -> DatabaseConfig:
    return _get_database_config("CONTABILIDAD")


def get_produccion_db_config() -> DatabaseConfig:
    return _get_database_config("PRODUCCION")


def get_asistencia_db_config() -> DatabaseConfig:
    return _get_database_config("ASISTENCIA")


def get_contratos_rem_db_config() -> DatabaseConfig:
    return _get_database_config("CONTRATOS_REM")
