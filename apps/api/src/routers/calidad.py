from fastapi import APIRouter

from src.repositories.calidad_repository import (
    obtener_resumen_calidad,
)


router = APIRouter(
    prefix="/api/bi/calidad",
    tags=["BI - Calidad"],
)


@router.get("/resumen")
def get_resumen_calidad():
    return obtener_resumen_calidad()
