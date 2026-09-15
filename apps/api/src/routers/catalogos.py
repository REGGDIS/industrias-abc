from __future__ import annotations

from fastapi import APIRouter, HTTPException, Query

from src.repositories.catalogos_repository import (
    obtener_areas,
    obtener_cargos,
    obtener_periodos_rrhh,
    obtener_periodos_asistencia,
    obtener_periodos_contratos,
    obtener_periodos_remuneraciones,
    obtener_periodos_contabilidad,
    obtener_centros_costo,
    obtener_cuentas_contables,
    obtener_periodos_compras,
    obtener_proveedores_compras,
    obtener_insumos_compras,
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


@router.get("/centros-costo")
def listar_centros_costo():
    return {
        "items": obtener_centros_costo()
    }


@router.get("/cuentas-contables")
def listar_cuentas_contables():
    return {
        "items": obtener_cuentas_contables()
    }


@router.get("/proveedores-compras")
def listar_proveedores_compras():
    return {
        "items": obtener_proveedores_compras()
    }


@router.get("/insumos-compras")
def listar_insumos_compras():
    return {
        "items": obtener_insumos_compras()
    }


@router.get("/periodos")
def listar_periodos(
    dominio: str = Query(...),
    anio: int | None = Query(None),
):
    dominio_normalizado = dominio.lower()

    if dominio_normalizado == "rrhh":
        return obtener_periodos_rrhh()

    if dominio_normalizado == "asistencia":
        return obtener_periodos_asistencia()

    if dominio_normalizado == "contratos":
        return obtener_periodos_contratos()

    if dominio_normalizado == "remuneraciones":
        return obtener_periodos_remuneraciones()

    if dominio_normalizado == "contabilidad":
        return obtener_periodos_contabilidad(
            anio=anio,
        )

    if dominio_normalizado == "compras":
        return obtener_periodos_compras(
            anio=anio,
        )

    raise HTTPException(
        status_code=400,
        detail=(
            "Dominio no soportado. "
            "Use rrhh, asistencia, contratos, remuneraciones, contabilidad o compras."
        ),
    )
