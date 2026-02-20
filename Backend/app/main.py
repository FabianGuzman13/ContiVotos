from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routers import candidatos, votos

# =========================
# Crear aplicación FastAPI
# =========================
app = FastAPI(
    title="API Votación - Firestore",
    description="API para gestión de candidatos y votación en tiempo real con Firebase Firestore",
    version="2.0.0",
)

# =========================
# Configuración CORS
# =========================
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # En producción, especifica los dominios permitidos
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# =========================
# Incluir Routers
# =========================
app.include_router(candidatos.router, prefix="/api")
app.include_router(votos.router, prefix="/api")


# =========================
# Ruta raíz
# =========================
@app.get("/")
def home():
    return {
        "success": True,
        "message": "API de Votación con Firestore - En línea",
        "version": "2.0.0",
        "documentacion": "/docs",
        "endpoints": {
            "candidatos": {
                "listar": "GET /api/candidatos",
                "obtener": "GET /api/candidatos/{id}",
                "crear": "POST /api/candidatos",
                "actualizar": "PUT /api/candidatos/{id}",
                "eliminar": "DELETE /api/candidatos/{id}",
                "ganadores": "GET /api/candidatos/ganadores/top/{n}",
            },
            "votos": {
                "votar": "POST /api/votos",
                "tiempo_real": "GET /api/votos/tiempo-real",
                "verificar_correo": "GET /api/votos/verificar-correo/{correo}",
                "verificar_ubicacion": "GET /api/votos/verificar-ubicacion?lat={lat}&lng={lng}",
                "websocket": "WS /api/votos/ws",
            },
        },
    }


# =========================
# Endpoint de estado
# =========================
@app.get("/api/status")
def status():
    return {
        "success": True,
        "message": "API de Votación con Firestore - Operativa",
        "version": "2.0.0",
        "database": "Firebase Firestore",
    }
