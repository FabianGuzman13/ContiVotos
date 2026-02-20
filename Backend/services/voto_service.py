from typing import Optional
from config.firebase import get_db, votos_ref, candidatos_ref
from models.voto import Voto
from datetime import datetime
import math


class VotoService:
    """Servicio para operaciones de votos usando Firestore"""

    @staticmethod
    def verificar_correo(correo: str) -> bool:
        """Verificar si un correo ya votó"""
        docs = votos_ref.where('correo', '==', correo).stream()
        for _ in docs:
            return True
        return False

    @staticmethod
    def verificar_user_id(user_id: str) -> bool:
        """Verificar si un usuario ya votó"""
        docs = votos_ref.where('user_id', '==', user_id).stream()
        for _ in docs:
            return True
        return False

    @staticmethod
    def registrar_voto(
        user_id: str,
        candidato_id: str,
        correo: str,
        ip_address: str = None,
        ubicacion_lat: float = None,
        ubicacion_lng: float = None
    ) -> tuple:
        """Registrar un nuevo voto"""
        try:
            # Verificar si el usuario ya votó
            if VotoService.verificar_user_id(user_id):
                return (False, 'El usuario ya ha votado')
            
            # Verificar si el correo ya fue usado
            if VotoService.verificar_correo(correo):
                return (False, 'Este correo ya ha sido usado para votar')
            
            # Verificar que el candidato existe
            candidato_doc = candidatos_ref.document(candidato_id).get()
            if not candidato_doc.exists:
                return (False, 'Candidato no encontrado')
            
            # Crear el voto
            now = datetime.utcnow()
            voto_data = {
                'user_id': user_id,
                'candidato_id': candidato_id,
                'correo': correo,
                'fecha': now,
                'ip_address': ip_address or '',
                'ubicacion_lat': ubicacion_lat,
                'ubicacion_lng': ubicacion_lng
            }
            
            votos_ref.document().set(voto_data)
            
            # Incrementar el contador de votos del candidato
            from config.firebase import get_db
            db = get_db()
            candidato_ref = candidatos_ref.document(candidato_id)
            candidato_ref.update({
                'votos': db.FieldValue.increment(1),
                'updated_at': now
            })
            
            return (True, 'Voto registrado exitosamente')
        except Exception as e:
            return (False, str(e))

    @staticmethod
    def get_votos_por_candidato(candidato_id: str) -> int:
        """Obtener cantidad de votos de un candidato"""
        doc = candidatos_ref.document(candidato_id).get()
        if doc.exists:
            return doc.to_dict().get('votos', 0)
        return 0

    @staticmethod
    def get_estadisticas() -> dict:
        """Obtener estadísticas generales"""
        from services.candidato_service import CandidatoService
        return CandidatoService.get_estadisticas()

    @staticmethod
    def verificar_puede_votar(
        correo: str,
        lat: float,
        lng: float,
        lat_campus: float = -12.0753,
        lng_campus: float = -77.0821,
        radio_campus: float = 0.5
    ) -> tuple:
        """Verificar si el usuario puede votar (verificado y dentro del campus)"""
        # Verificar si ya votó
        if VotoService.verificar_correo(correo):
            return (False, 'Ya has votado anteriormente')
        
        # Calcular distancia al campus (fórmula de Haversine)
        if lat and lng:
            R = 6371  # Radio de la Tierra en km
            dlat = math.radians(lat - lat_campus)
            dlng = math.radians(lng - lng_campus)
            a = math.sin(dlat/2)**2 + math.cos(math.radians(lat_campus)) * \
                math.cos(math.radians(lat)) * math.sin(dlng/2)**2
            c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
            distancia = R * c
            
            if distancia > radio_campus:
                return (False, f'Estas fuera del campus (distancia: {distancia:.2f} km)')
        
        return (True, 'Puedes votar')

    @staticmethod
    def reiniciar_eleccion() -> tuple:
        """Reiniciar la elección (borrar todos los votos)"""
        try:
            # Contar votos antes de eliminar
            total_votos = 0
            docs = votos_ref.stream()
            for doc in docs:
                total_votos += 1
            
            # Eliminar todos los votos
            batch = get_db().batch()
            docs = votos_ref.stream()
            for doc in docs:
                batch.delete(doc.reference)
            batch.commit()
            
            # Resetear contadores de candidatos
            batch = get_db().batch()
            docs = candidatos_ref.stream()
            for doc in docs:
                batch.update(doc.reference, {'votos': 0, 'updated_at': datetime.utcnow()})
            batch.commit()
            
            return (True, f'Eleccion reiniciada. Votos eliminados: {total_votos}', total_votos)
        except Exception as e:
            return (False, str(e), 0)
