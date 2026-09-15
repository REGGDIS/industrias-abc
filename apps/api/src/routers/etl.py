from fastapi import APIRouter

from src.repositories.etl_repository import (
    obtener_resumen_etl,
)


router = APIRouter(
    prefix="/api/bi/etl",
    tags=["BI - ETL"],
)


@router.get("/resumen")
def get_resumen_etl():
    return obtener_resumen_etl()
