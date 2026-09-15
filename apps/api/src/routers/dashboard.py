from __future__ import annotations

from fastapi import APIRouter

from src.repositories.dashboard_repository import (
    obtener_resumen_dashboard,
)


router = APIRouter(
    prefix="/api/bi/dashboard",
    tags=["Dashboard BI"],
)


@router.get("/resumen")
def obtener_resumen():
    return obtener_resumen_dashboard()
