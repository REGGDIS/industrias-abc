from __future__ import annotations

from fastapi import APIRouter, HTTPException, Query

from src.repositories.rrhh_repository import (
    obtener_resumen_rrhh,
    obtener_trabajadores_rrhh,
)


router = APIRouter(
    prefix="/api/bi/rrhh",
    tags=["RRHH BI"],
)


@router.get("/resumen")
def obtener_resumen(
    anio: int = Query(..., ge=2000, le=2100),
    mes: int | None = Query(None, ge=1, le=12),
    areaId: int | None = Query(None, ge=1),
    cargoId: int | None = Query(None, ge=1),
):
    try:
        return obtener_resumen_rrhh(
            anio=anio,
            mes=mes,
            area_id=areaId,
            cargo_id=cargoId,
        )
    except ValueError as exc:
        raise HTTPException(
            status_code=400,
            detail=str(exc),
        ) from exc


@router.get("/trabajadores")
def listar_trabajadores(
    anio: int = Query(..., ge=2000, le=2100),
    mes: int | None = Query(None, ge=1, le=12),
    areaId: int | None = Query(None, ge=1),
    cargoId: int | None = Query(None, ge=1),
    page: int = Query(1, ge=1),
    pageSize: int = Query(10, ge=1, le=100),
):
    try:
        return obtener_trabajadores_rrhh(
            anio=anio,
            mes=mes,
            area_id=areaId,
            cargo_id=cargoId,
            page=page,
            page_size=pageSize,
        )
    except ValueError as exc:
        raise HTTPException(
            status_code=400,
            detail=str(exc),
        ) from exc
