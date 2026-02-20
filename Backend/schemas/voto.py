from pydantic import BaseModel
from typing import Optional


# =========================
# Schemas Voto
# =========================


class VotoBase(BaseModel):
    userId: str
    candidatoId: str  # Firestore document ID es string
    correo: str


class VotoCreate(VotoBase):
    """Schema para crear un nuevo voto"""
    pass


class Voto(VotoBase):
    """Schema para respuesta con voto completo"""
    id: str

    class Config:
        from_attributes = True
