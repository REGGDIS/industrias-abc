from __future__ import annotations

from fastapi import APIRouter, HTTPException, Query

from src.repositories.contabilidad_repository import (
    obtener_movimientos_contabilidad,
    obtener_resumen_contabilidad,
)


router = APIRouter(
    prefix="/api/bi/contabilidad",
    tags=["Contabilidad BI"],
)


@router.get("/resumen")
def obtener_resumen(
    anio: int = Query(...),
    mes: int | None = Query(None),
    centroCostoId: int | None = Query(None),
    cuentaContableId: int | None = Query(None),
):
    try:
        return obtener_resumen_contabilidad(
            anio=anio,
            mes=mes,
            centro_costo_id=centroCostoId,
            cuenta_contable_id=cuentaContableId,
        )
    except ValueError as exc:
        raise HTTPException(
            status_code=400,
            detail=str(exc),
        ) from exc


@router.get("/movimientos")
def obtener_movimientos(
    anio: int = Query(...),
    mes: int | None = Query(None),
    centroCostoId: int | None = Query(None),
    cuentaContableId: int | None = Query(None),
    page: int = Query(1, ge=1),
    pageSize: int = Query(
        20,
        ge=1,
        le=100,
    ),
):
    try:
        return obtener_movimientos_contabilidad(
            anio=anio,
            mes=mes,
            centro_costo_id=centroCostoId,
            cuenta_contable_id=cuentaContableId,
            page=page,
            page_size=pageSize,
        )
    except ValueError as exc:
        raise HTTPException(
            status_code=400,
            detail=str(exc),
        ) from exc
