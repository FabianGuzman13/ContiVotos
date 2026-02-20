from pydantic import BaseModel, Field
from typing import Optional


# =========================
# Schemas Candidato
# =========================


class CandidatoBase(BaseModel):
    nombre: str
    numero: int
    cargo: Optional[str] = None
    imagen: Optional[str] = None
    propuesta: Optional[str] = None
    vision: Optional[str] = None
    experiencia: Optional[str] = None
    semestre: Optional[str] = None


class CandidatoCreate(CandidatoBase):
    """Schema para crear un nuevo candidato"""
    pass


class CandidatoUpdate(BaseModel):
    """Schema para actualizar un candidato (todos los campos opcionales)"""
    nombre: Optional[str] = None
    numero: Optional[int] = None
    cargo: Optional[str] = None
    imagen: Optional[str] = None
    propuesta: Optional[str] = None
    vision: Optional[str] = None
    experiencia: Optional[str] = None
    semestre: Optional[str] = None
    votos: Optional[int] = None


class Candidato(CandidatoBase):
    """Schema para respuesta con candidato completo"""
    id: str
    votos: int

    class Config:
        from_attributes = True
