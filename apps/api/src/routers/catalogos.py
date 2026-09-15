from __future__ import annotations

from fastapi import APIRouter, HTTPException, Query

from src.repositories.catalogos_repository import (
    obtener_areas,
    obtener_cargos,
    obtener_periodos_rrhh,
    obtener_periodos_asistencia,
)


router = APIRouter(
    prefix="/api/bi/catalogos",
    tags=["Catálogos BI"],
)


@router.get("/areas")
def listar_areas():
    return {
        "items": obtener_areas()
    }


@router.get("/cargos")
def listar_cargos():
    return {
        "items": obtener_cargos()
    }


@router.get("/periodos")
def listar_periodos(
    dominio: str = Query(...),
):
    dominio_normalizado = dominio.lower()

    if dominio_normalizado == "rrhh":
        return obtener_periodos_rrhh()

    if dominio_normalizado == "asistencia":
        return obtener_periodos_asistencia()

    raise HTTPException(
        status_code=400,
        detail=(
            "Dominio no soportado. "
            "Use rrhh o asistencia."
        ),
    )
