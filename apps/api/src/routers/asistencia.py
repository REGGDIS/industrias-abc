from __future__ import annotations

from fastapi import APIRouter, HTTPException, Query

from src.repositories.asistencia_repository import (
    obtener_detalle_asistencia,
    obtener_resumen_asistencia,
    obtener_trabajadores_asistencia,
)


router = APIRouter(
    prefix="/api/bi/asistencia",
    tags=["Asistencia BI"],
)


@router.get("/resumen")
def obtener_resumen(
    anio: int = Query(..., ge=2000, le=2100),
    mes: int | None = Query(None, ge=1, le=12),
    areaId: int | None = Query(None, ge=1),
    trabajadorId: str | None = Query(None),
):
    try:
        return obtener_resumen_asistencia(
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
    anio: int = Query(..., ge=2000, le=2100),
    mes: int | None = Query(None, ge=1, le=12),
    areaId: int | None = Query(None, ge=1),
    trabajadorId: str | None = Query(None),
    page: int = Query(1, ge=1),
    pageSize: int = Query(20, ge=1, le=100),
):
    try:
        return obtener_detalle_asistencia(
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
def listar_trabajadores(
    anio: int = Query(..., ge=2000, le=2100),
    mes: int | None = Query(None, ge=1, le=12),
    areaId: int | None = Query(None, ge=1),
):
    try:
        return obtener_trabajadores_asistencia(
            anio=anio,
            mes=mes,
            area_id=areaId,
        )
    except ValueError as exc:
        raise HTTPException(
            status_code=400,
            detail=str(exc),
        ) from exc
