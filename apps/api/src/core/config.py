from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path

from dotenv import load_dotenv


ENV_FILE = Path(__file__).resolve().parents[2] / ".env"
load_dotenv(ENV_FILE)


@dataclass(frozen=True)
class Settings:
    dw_host: str = os.getenv("DW_DB_HOST", "localhost")
    dw_port: int = int(os.getenv("DW_DB_PORT", "5437"))
    dw_name: str = os.getenv("DW_DB_NAME", "industrias_abc_dw")
    dw_user: str = os.getenv("DW_DB_USER", "dw_user")
    dw_password: str = os.getenv("DW_DB_PASSWORD", "")

    audit_host: str = os.getenv("AUDIT_DB_HOST", "localhost")
    audit_port: int = int(os.getenv("AUDIT_DB_PORT", "5434"))
    audit_name: str = os.getenv("AUDIT_DB_NAME", "rrhh")
    audit_user: str = os.getenv("AUDIT_DB_USER", "postgres")
    audit_password: str = os.getenv("AUDIT_DB_PASSWORD", "")

    cors_origins: tuple[str, ...] = tuple(
        origin.strip()
        for origin in os.getenv(
            "CORS_ORIGINS",
            "http://localhost:5173,http://127.0.0.1:5173",
        ).split(",")
        if origin.strip()
    )


settings = Settings()
