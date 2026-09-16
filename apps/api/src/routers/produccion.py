from __future__ import annotations

from fastapi import APIRouter, HTTPException, Query

from src.repositories.produccion_repository import (
    obtener_detalle_produccion,
    obtener_resumen_produccion,
)


router = APIRouter(
    prefix="/api/bi/produccion",
    tags=["Producción BI"],
)


@router.get("/resumen")
def obtener_resumen(
    anio: int = Query(...),
    mes: int | None = Query(None),
    productoId: int | None = Query(None),
    insumoRef: str | None = Query(None),
):
    try:
        return obtener_resumen_produccion(
            anio=anio,
            mes=mes,
            producto_id=productoId,
            insumo_ref=insumoRef,
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
    productoId: int | None = Query(None),
    insumoRef: str | None = Query(None),
    page: int = Query(1, ge=1),
    pageSize: int = Query(20, ge=1, le=100),
):
    try:
        return obtener_detalle_produccion(
            anio=anio,
            mes=mes,
            producto_id=productoId,
            insumo_ref=insumoRef,
            page=page,
            page_size=pageSize,
        )
    except ValueError as exc:
        raise HTTPException(
            status_code=400,
            detail=str(exc),
        ) from exc
