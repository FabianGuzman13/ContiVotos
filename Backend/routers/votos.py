from fastapi import APIRouter, HTTPException, WebSocket, WebSocketDisconnect
from typing import List
import math
from datetime import datetime

from services.candidato_service import CandidatoService
from services.voto_service import VotoService
from schemas.voto import VotoCreate

router = APIRouter(prefix="/votos", tags=["votos"])


# =========================
# WebSocket Connections Manager
# =========================
class ConnectionManager:
    def __init__(self):
        self.active_connections: List[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)

    def disconnect(self, websocket: WebSocket):
        if websocket in self.active_connections:
            self.active_connections.remove(websocket)

    async def broadcast(self, message: dict):
        for connection in self.active_connections:
            try:
                await connection.send_json(message)
            except:
                pass


manager = ConnectionManager()


# =========================
# Endpoints de Votación
# =========================


@router.post("/")
async def votar(voto: VotoCreate):
    """Registrar un voto y notificar en tiempo real"""
    try:
        # Verificar si el correo ya votó
        if VotoService.verificar_correo(voto.correo):
            raise HTTPException(status_code=400, detail="Este correo ya votó")

        # Registrar el voto usando stored procedure
        success, message = VotoService.registrar_voto(
            user_id=voto.userId,
            candidato_id=voto.candidatoId,
            correo=voto.correo
        )

        if not success:
            raise HTTPException(status_code=400, detail=message)

        # Obtener estadísticas actualizadas
        estadisticas = CandidatoService.get_estadisticas()
        conteo = CandidatoService.get_conteo_votos()

        await manager.broadcast(
            {
                "tipo": "voto_registrado",
                "candidatoId": voto.candidatoId,
                "total_votos": estadisticas.get("total_votos", 0),
                "candidatos": conteo,
            }
        )

        return {
            "success": True,
            "mensaje": message,
            "candidatoId": voto.candidatoId,
        }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/verificar/{user_id}")
async def verificar_ya_voto(user_id: str):
    """Verificar si un usuario ya ha votado"""
    try:
        ya_voto = VotoService.verificar_user_id(user_id)
        return {"success": True, "yaVoto": ya_voto, "userId": user_id}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/verificar-correo/{correo}")
async def verificar_correo_existe(correo: str):
    """Verificar si un correo ya ha votado"""
    try:
        ya_voto = VotoService.verificar_correo(correo)
        return {"success": True, "yaVoto": ya_voto, "correo": correo}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/verificar-ubicacion")
async def verificar_ubicacion(lat: float, lng: float):
    """Verificar si las coordenadas están dentro del campus"""
    try:
        # Coordenadas del campus (Universidad Continental - Campus Huancayo)
        campus_lat = -12.047505186140151
        campus_lng = -75.19906082214352
        radio_permitido = 1000  # metros

        # Calcular distancia usando fórmula de Haversine
        R = 6371000  # Radio de la Tierra en metros

        lat1 = math.radians(campus_lat)
        lat2 = math.radians(lat)
        delta_lat = math.radians(lat - campus_lat)
        delta_lng = math.radians(lng - campus_lng)

        a = (
            math.sin(delta_lat / 2) ** 2
            + math.cos(lat1) * math.cos(lat2) * math.sin(delta_lng / 2) ** 2
        )
        c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
        distancia = R * c

        dentro_campus = distancia <= radio_permitido

        return {
            "success": True,
            "data": {
                "dentroCampus": dentro_campus,
                "distancia": round(distancia, 2),
            },
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/validar-correo/{correo}")
async def validar_correo_institucional(correo: str):
    """Verificar si el correo es institucional"""
    try:
        dominios_institucionales = ["continental.edu.pe", "uc.edu.pe"]
        dominio = correo.split("@")[-1].lower() if "@" in correo else ""

        es_institucional = dominio in dominios_institucionales

        return {
            "success": True,
            "data": {
                "esInstitucional": es_institucional,
                "correo": correo,
            },
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# =========================
# WebSocket para votos en tiempo real
# =========================


@router.websocket("/ws")
async def websocket_votos(websocket: WebSocket):
    """WebSocket para recibir actualizaciones de votos en tiempo real"""
    await manager.connect(websocket)

    try:
        # Enviar estado inicial
        estadisticas = CandidatoService.get_estadisticas()
        conteo = CandidatoService.get_conteo_votos()

        await websocket.send_json(
            {
                "tipo": "inicial",
                "total_votos": estadisticas.get("total_votos", 0),
                "candidatos": conteo,
            }
        )

        while True:
            # Mantener la conexión abierta
            data = await websocket.receive_text()
            if data == "ping":
                await websocket.send_json({"tipo": "pong"})

    except WebSocketDisconnect:
        manager.disconnect(websocket)


# =========================
# Endpoint para reiniciar elección
# =========================

@router.post("/reiniciar")
async def reiniciar_eleccion():
    """Reiniciar la elección (borrar todos los votos)"""
    try:
        success, message, votos_eliminados = VotoService.reiniciar_eleccion()
        
        if not success:
            raise HTTPException(status_code=400, detail=message)
            
        return {
            "success": True,
            "mensaje": message,
            "votos_eliminados": votos_eliminados
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
