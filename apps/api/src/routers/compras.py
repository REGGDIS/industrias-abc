from __future__ import annotations

from fastapi import APIRouter, HTTPException, Query

from src.repositories.compras_repository import (
    obtener_detalle_compras,
    obtener_resumen_compras,
)


router = APIRouter(
    prefix="/api/bi/compras",
    tags=["Compras BI"],
)


@router.get("/resumen")
def obtener_resumen(
    anio: int = Query(...),
    mes: int | None = Query(None),
    proveedorId: int | None = Query(None),
    insumoId: int | None = Query(None),
):
    try:
        return obtener_resumen_compras(
            anio=anio,
            mes=mes,
            proveedor_id=proveedorId,
            insumo_id=insumoId,
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
    proveedorId: int | None = Query(None),
    insumoId: int | None = Query(None),
    page: int = Query(1, ge=1),
    pageSize: int = Query(
        20,
        ge=1,
        le=100,
    ),
):
    try:
        return obtener_detalle_compras(
            anio=anio,
            mes=mes,
            proveedor_id=proveedorId,
            insumo_id=insumoId,
            page=page,
            page_size=pageSize,
        )
    except ValueError as exc:
        raise HTTPException(
            status_code=400,
            detail=str(exc),
        ) from exc
