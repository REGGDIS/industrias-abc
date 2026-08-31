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


def _get_required_env(name: str) -> str:
    value = os.getenv(name)

    if value is None or value.strip() == "":
        raise RuntimeError(
            f"La variable de entorno requerida '{name}' no está definida."
        )

    return value.strip()


def get_rrhh_db_config() -> DatabaseConfig:
    return DatabaseConfig(
        host=_get_required_env("RRHH_DB_HOST"),
        port=int(_get_required_env("RRHH_DB_PORT")),
        database=_get_required_env("RRHH_DB_NAME"),
        user=_get_required_env("RRHH_DB_USER"),
        password=_get_required_env("RRHH_DB_PASSWORD"),
    )
