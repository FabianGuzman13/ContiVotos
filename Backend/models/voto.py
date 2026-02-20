from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class Voto(BaseModel):
    """Modelo de Voto para PostgreSQL"""

    id: Optional[int] = None  # PostgreSQL usa SERIAL
    user_id: str
    candidato_id: int
    correo: str
    fecha: Optional[datetime] = None
    ip_address: Optional[str] = None
    ubicacion_lat: Optional[float] = None
    ubicacion_lng: Optional[float] = None

    class Config:
        from_attributes = True
