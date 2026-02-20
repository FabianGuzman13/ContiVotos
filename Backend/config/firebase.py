import firebase_admin
from firebase_admin import credentials, firestore
import os
from dotenv import load_dotenv

load_dotenv()


# Inicializar Firebase Admin SDK
def initialize_firebase():
    """Inicializa la conexión con Firebase"""
    try:
        # Intentar obtener la app existente
        firebase_admin.get_app()
        print("Firebase ya estaba inicializado")
    except ValueError:
        # Si no existe, inicializar
        print("Inicializando Firebase...")

        # Opción 1: Usar archivo de credenciales JSON
        cred_path = os.getenv(
            "FIREBASE_CREDENTIALS_PATH", "./firebase-credentials.json"
        )

        if os.path.exists(cred_path):
            print(f"Usando credenciales desde: {cred_path}")
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
            print("Firebase inicializado correctamente con archivo JSON")
        else:
            print(f"Archivo no encontrado: {cred_path}")
            # Opción 2: Usar variables de entorno
            cred_dict = {
                "type": "service_account",
                "project_id": os.getenv("FIREBASE_PROJECT_ID"),
                "private_key_id": os.getenv("FIREBASE_PRIVATE_KEY_ID"),
                "private_key": os.getenv("FIREBASE_PRIVATE_KEY", "").replace(
                    "\\n", "\n"
                ),
                "client_email": os.getenv("FIREBASE_CLIENT_EMAIL"),
                "client_id": os.getenv("FIREBASE_CLIENT_ID"),
                "auth_uri": "https://accounts.google.com/o/oauth2/auth",
                "token_uri": "https://oauth2.googleapis.com/token",
            }
            cred = credentials.Certificate(cred_dict)
            firebase_admin.initialize_app(cred)
            print("Firebase inicializado correctamente con variables de entorno")

    return firestore.client()


# Instancia global de Firestore
print("Configurando Firestore...")
db = initialize_firebase()
print("Firestore configurado exitosamente")

# Referencias a colecciones
candidatos_ref = db.collection("candidatos")
votos_ref = db.collection("votos")


def get_db():
    """Retorna la instancia de Firestore"""
    return db
