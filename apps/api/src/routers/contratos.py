from __future__ import annotations

from fastapi import APIRouter, HTTPException, Query

from src.repositories.contratos_repository import (
    obtener_detalle_contratos,
    obtener_resumen_contratos,
    obtener_trabajadores_contratos,
)


router = APIRouter(
    prefix="/api/bi/contratos",
    tags=["Contratos BI"],
)


@router.get("/resumen")
def obtener_resumen(
    anio: int = Query(...),
    mes: int | None = Query(None),
    areaId: int | None = Query(None),
    trabajadorId: str | None = Query(None),
):
    try:
        return obtener_resumen_contratos(
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
        return obtener_detalle_contratos(
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
        return obtener_trabajadores_contratos(
            anio=anio,
            mes=mes,
            area_id=areaId,
        )
    except ValueError as exc:
        raise HTTPException(
            status_code=400,
            detail=str(exc),
        ) from exc
