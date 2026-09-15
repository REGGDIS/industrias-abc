from fastapi import APIRouter

from src.repositories.analisis_repository import (
    obtener_resumen_analisis,
)


router = APIRouter(
    prefix="/api/bi/analisis",
    tags=["BI - Análisis"],
)


@router.get("/resumen")
def get_resumen_analisis():
    return obtener_resumen_analisis()
