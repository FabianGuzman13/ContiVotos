# Schemas package
from .candidato import CandidatoBase, CandidatoCreate, CandidatoUpdate, Candidato
from .voto import VotoBase, VotoCreate, Voto

__all__ = [
    "CandidatoBase",
    "CandidatoCreate",
    "CandidatoUpdate",
    "Candidato",
    "VotoBase",
    "VotoCreate",
    "Voto",
]
