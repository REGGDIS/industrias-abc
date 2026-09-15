from __future__ import annotations

from fastapi import APIRouter, HTTPException, Query

from src.repositories.remuneraciones_repository import (
    obtener_detalle_remuneraciones,
    obtener_resumen_remuneraciones,
    obtener_trabajadores_remuneraciones,
)


router = APIRouter(
    prefix="/api/bi/remuneraciones",
    tags=["Remuneraciones BI"],
)


@router.get("/resumen")
def obtener_resumen(
    anio: int = Query(...),
    mes: int | None = Query(None),
    areaId: int | None = Query(None),
    trabajadorId: str | None = Query(None),
):
    try:
        return obtener_resumen_remuneraciones(
            anio=anio,
            mes=mes,
            area_id=areaId,
            trabajador_id=trabajadorId,
        )
    except ValueError as exc:
        raise HTTPException(
            status_code=400,
            detail=str(exc),
        ) from exc


@router.get("/detalle")
def obtener_detalle(
    anio: int = Query(...),
    mes: int | None = Query(None),
    areaId: int | None = Query(None),
    trabajadorId: str | None = Query(None),
    page: int = Query(1, ge=1),
    pageSize: int = Query(
        20,
        ge=1,
        le=100,
    ),
):
    try:
        return obtener_detalle_remuneraciones(
            anio=anio,
            mes=mes,
            area_id=areaId,
            trabajador_id=trabajadorId,
            page=page,
            page_size=pageSize,
        )
    except ValueError as exc:
        raise HTTPException(
            status_code=400,
            detail=str(exc),
        ) from exc


@router.get("/trabajadores")
def obtener_trabajadores(
    anio: int = Query(...),
    mes: int | None = Query(None),
    areaId: int | None = Query(None),
):
    try:
        return obtener_trabajadores_remuneraciones(
            anio=anio,
            mes=mes,
            area_id=areaId,
        )
    except ValueError as exc:
        raise HTTPException(
            status_code=400,
            detail=str(exc),
        ) from exc
