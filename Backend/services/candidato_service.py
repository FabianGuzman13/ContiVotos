from typing import List, Optional
from config.firebase import get_db, candidatos_ref
from models.candidato import Candidato
from datetime import datetime
from google.cloud.firestore import Increment


class CandidatoService:
    """Servicio para operaciones CRUD de candidatos usando Firestore"""

    @staticmethod
    def get_all() -> List[Candidato]:
        """Obtener todos los candidatos"""
        candidatos = []
        docs = candidatos_ref.order_by('numero').stream()
        
        for doc in docs:
            data = doc.to_dict()
            candidatos.append(Candidato(
                id=doc.id,
                nombre=data.get('nombre'),
                numero=data.get('numero'),
                cargo=data.get('cargo'),
                imagen=data.get('imagen'),
                propuesta=data.get('propuesta'),
                vision=data.get('vision'),
                experiencia=data.get('experiencia'),
                semestre=data.get('semestre'),
                votos=data.get('votos', 0),
                created_at=data.get('created_at'),
                updated_at=data.get('updated_at')
            ))
        return candidatos

    @staticmethod
    def get_by_id(candidato_id: str) -> Optional[Candidato]:
        """Obtener un candidato por ID"""
        doc = candidatos_ref.document(candidato_id).get()
        
        if doc.exists:
            data = doc.to_dict()
            return Candidato(
                id=doc.id,
                nombre=data.get('nombre'),
                numero=data.get('numero'),
                cargo=data.get('cargo'),
                imagen=data.get('imagen'),
                propuesta=data.get('propuesta'),
                vision=data.get('vision'),
                experiencia=data.get('experiencia'),
                semestre=data.get('semestre'),
                votos=data.get('votos', 0),
                created_at=data.get('created_at'),
                updated_at=data.get('updated_at')
            )
        return None

    @staticmethod
    def create(
        nombre: str, 
        numero: int, 
        cargo: str = None, 
        imagen: str = None, 
        propuesta: str = None, 
        vision: str = None, 
        experiencia: str = None, 
        semestre: str = None
    ) -> tuple:
        """Crear un nuevo candidato"""
        try:
            # Verificar si ya existe un candidato con ese número
            existing = candidatos_ref.where('numero', '==', numero).stream()
            for _ in existing:
                return (False, 'Ya existe un candidato con ese numero', None)
            
            now = datetime.utcnow()
            doc_ref = candidatos_ref.document()
            doc_ref.set({
                'nombre': nombre,
                'numero': numero,
                'cargo': cargo or '',
                'imagen': imagen or '',
                'propuesta': propuesta or '',
                'vision': vision or '',
                'experiencia': experiencia or '',
                'semestre': semestre or '',
                'votos': 0,
                'created_at': now,
                'updated_at': now
            })
            return (True, 'Candidato creado exitosamente', doc_ref.id)
        except Exception as e:
            return (False, str(e), None)

    @staticmethod
    def update(
        candidato_id: str,
        nombre: str = None,
        numero: int = None,
        cargo: str = None,
        imagen: str = None,
        propuesta: str = None,
        vision: str = None,
        experiencia: str = None,
        semestre: str = None
    ) -> tuple:
        """Actualizar un candidato"""
        try:
            doc_ref = candidatos_ref.document(candidato_id)
            if not doc_ref.get().exists:
                return (False, 'Candidato no encontrado')
            
            update_data = {'updated_at': datetime.utcnow()}
            if nombre is not None:
                update_data['nombre'] = nombre
            if numero is not None:
                update_data['numero'] = numero
            if cargo is not None:
                update_data['cargo'] = cargo
            if imagen is not None:
                update_data['imagen'] = imagen
            if propuesta is not None:
                update_data['propuesta'] = propuesta
            if vision is not None:
                update_data['vision'] = vision
            if experiencia is not None:
                update_data['experiencia'] = experiencia
            if semestre is not None:
                update_data['semestre'] = semestre
            
            doc_ref.update(update_data)
            return (True, 'Candidato actualizado exitosamente')
        except Exception as e:
            return (False, str(e))

    @staticmethod
    def delete(candidato_id: str) -> tuple:
        """Eliminar un candidato"""
        try:
            doc = candidatos_ref.document(candidato_id)
            if not doc.get().exists:
                return (False, 'Candidato no encontrado')
            
            doc.delete()
            return (True, 'Candidato eliminado exitosamente')
        except Exception as e:
            return (False, str(e))

    @staticmethod
    def get_conteo_votos() -> List[dict]:
        """Obtener conteo de votos de todos los candidatos"""
        resultados = []
        total_votos = 0
        
        # Contar total de votos
        docs = candidatos_ref.stream()
        for doc in docs:
            data = doc.to_dict()
            total_votos += data.get('votos', 0)
        
        # Calcular porcentajes
        docs = candidatos_ref.order_by('numero').stream()
        for doc in docs:
            data = doc.to_dict()
            votos = data.get('votos', 0)
            porcentaje = (votos / total_votos * 100) if total_votos > 0 else 0
            
            resultados.append({
                'candidato_id': doc.id,
                'nombre': data.get('nombre'),
                'numero': data.get('numero'),
                'cargo': data.get('cargo'),
                'imagen': data.get('imagen'),
                'votos': votos,
                'porcentaje': round(porcentaje, 2)
            })
        return resultados

    @staticmethod
    def get_estadisticas() -> dict:
        """Obtener estadísticas generales"""
        total_votos = 0
        total_candidatos = 0
        candidato_ganador = None
        votos_ganador = 0
        
        docs = candidatos_ref.stream()
        for doc in docs:
            data = doc.to_dict()
            total_candidatos += 1
            votos = data.get('votos', 0)
            total_votos += votos
            
            if votos > votos_ganador:
                candidato_ganador = data.get('nombre')
                votos_ganador = votos
        
        return {
            'total_votos': total_votos,
            'total_candidatos': total_candidatos,
            'candidato_ganador': candidato_ganador,
            'votos_ganador': votos_ganador
        }
    
    @staticmethod
    def increment_vote(candidato_id: str) -> bool:
        """Incrementar el contador de votos de un candidato"""
        try:
            doc_ref = candidatos_ref.document(candidato_id)
            doc_ref.update({'votos': Increment(1), 'updated_at': datetime.utcnow()})
            return True
        except Exception:
            return False
