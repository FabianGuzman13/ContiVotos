from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class Candidato(BaseModel):
    """Modelo de Candidato para Firestore"""

    id: Optional[str] = None
    nombre: str
    numero: int
    cargo: Optional[str] = None
    imagen: Optional[str] = None
    propuesta: Optional[str] = None
    vision: Optional[str] = None
    experiencia: Optional[str] = None
    semestre: Optional[str] = None
    votos: int = 0
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True
