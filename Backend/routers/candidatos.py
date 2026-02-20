from fastapi import APIRouter, HTTPException
from typing import List
from services.candidato_service import CandidatoService
from schemas.candidato import CandidatoCreate, CandidatoUpdate

router = APIRouter(prefix="/candidatos", tags=["candidatos"])


# =========================
# CRUD Candidatos con Firestore
# =========================


@router.get("/")
async def obtener_candidatos():
    """Obtener todos los candidatos desde Firestore"""
    try:
        candidatos = CandidatoService.get_all()
        return candidatos
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{candidato_id}")
async def obtener_candidato(candidato_id: str):
    """Obtener un candidato por ID"""
    try:
        candidato = CandidatoService.get_by_id(candidato_id)
        if not candidato:
            raise HTTPException(status_code=404, detail="Candidato no encontrado")
        return candidato
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/", status_code=201)
async def crear_candidato(candidato: CandidatoCreate):
    """Crear un nuevo candidato"""
    try:
        success, message, candidato_id = CandidatoService.create(
            nombre=candidato.nombre,
            numero=candidato.numero,
            cargo=candidato.cargo,
            imagen=candidato.imagen,
            propuesta=candidato.propuesta,
            vision=candidato.vision,
            experiencia=candidato.experiencia,
            semestre=candidato.semestre
        )
        
        if not success:
            raise HTTPException(status_code=400, detail=message)
            
        return {
            "success": True,
            "mensaje": message,
            "candidato_id": candidato_id,
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.put("/{candidato_id}")
async def actualizar_candidato(candidato_id: str, candidato: CandidatoUpdate):
    """Actualizar un candidato"""
    try:
        success, message = CandidatoService.update(
            candidato_id=candidato_id,
            nombre=candidato.nombre,
            numero=candidato.numero,
            cargo=candidato.cargo,
            imagen=candidato.imagen,
            propuesta=candidato.propuesta,
            vision=candidato.vision,
            experiencia=candidato.experiencia,
            semestre=candidato.semestre
        )
        
        if not success:
            raise HTTPException(status_code=400, detail=message)
            
        return {
            "success": True,
            "mensaje": message,
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/{candidato_id}")
async def eliminar_candidato(candidato_id: str):
    """Eliminar un candidato"""
    try:
        success, message = CandidatoService.delete(candidato_id)

        if not success:
            raise HTTPException(status_code=400, detail=message)

        return {"success": True, "mensaje": message}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# =========================
# ENDPOINTS ESPECIALES
# =========================


@router.get("/resultados/conteo")
async def obtener_conteo_votos():
    """Obtener conteo de votos de todos los candidatos"""
    try:
        resultados = CandidatoService.get_conteo_votos()
        return {
            "success": True,
            "data": {
                "candidatos": resultados
            }
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/resultados/estadisticas")
async def obtener_estadisticas():
    """Obtener estadísticas generales"""
    try:
        estadisticas = CandidatoService.get_estadisticas()
        return {
            "success": True,
            "data": estadisticas
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
