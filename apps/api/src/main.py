from __future__ import annotations

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from src.core.database import get_connection
from src.routers.asistencia import router as asistencia_router
from src.routers.catalogos import router as catalogos_router
from src.routers.rrhh import router as rrhh_router


app = FastAPI(
    title="Industrias ABC - BI API",
    version="0.1.0",
)


app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:5173",
        "http://127.0.0.1:5173",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/api/health")
def health():
    with get_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                """
                SELECT
                    current_database() AS database,
                    current_user AS usuario;
                """
            )
            database = cursor.fetchone()

    return {
        "status": "ok",
        "dw": database,
    }


app.include_router(catalogos_router)
app.include_router(rrhh_router)
app.include_router(asistencia_router)
