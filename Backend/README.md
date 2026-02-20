# Backend FastAPI + Firestore + Flutter

Backend actualizado para usar **Firebase Firestore** en lugar de SQL Server, optimizado para integración con Flutter.

## 📦 Cambios Principales

- ✅ **Base de datos**: SQL Server → Firestore
- ✅ **Tiempo real**: WebSocket + Firestore SDK
- ✅ **Escalabilidad**: Automática con Firebase
- ✅ **Menos código**: Sin SQL ni migraciones

## 🚀 Inicio Rápido

### 1. Configurar Firebase

```bash
# Copiar credenciales de Firebase Console
cp tu-archivo-descargado.json firebase-credentials.json

# Crear archivo de entorno
cp .env.example .env
```

### 2. Instalar dependencias

```bash
venv\Scripts\activate
pip install -r requirements.txt
```

### 3. Iniciar servidor

```bash
python main.py
```

Listo! API en `http://localhost:8000`

## 📚 Documentación

- **Guía completa**: Ver `FIRESTORE_SETUP.md`
- **API Docs**: `http://localhost:8000/docs`
- **Configuración Flutter**: Incluida en `FIRESTORE_SETUP.md`

## 🔗 Endpoints

### Candidatos
- `GET /api/candidatos` - Listar todos
- `GET /api/candidatos/{id}` - Obtener uno
- `POST /api/candidatos` - Crear
- `PUT /api/candidatos/{id}` - Actualizar
- `DELETE /api/candidatos/{id}` - Eliminar

### Votos
- `POST /api/votos` - Registrar voto
- `GET /api/votos/tiempo-real` - Estadísticas
- `GET /api/votos/verificar-correo/{correo}` - Verificar voto
- `WS /api/votos/ws` - WebSocket tiempo real

## 🔥 Conexión Flutter

### URLs según dispositivo:

```dart
// Android Emulator
static const String baseUrl = 'http://10.0.2.2:8000/api';

// iOS Simulator  
static const String baseUrl = 'http://127.0.0.1:8000/api';

// Dispositivo físico
static const String baseUrl = 'http://192.168.1.X:8000/api';
```

### Dependencias Flutter:

```yaml
dependencies:
  http: ^1.1.0
  firebase_core: ^2.24.2
  cloud_firestore: ^4.14.0
```

## ⚠️ Importante

- **NO subas** `firebase-credentials.json` a GitHub (está en `.gitignore`)
- **Backend debe estar corriendo** antes de abrir Flutter
- **Misma red WiFi** si usas dispositivo físico

## 📖 Más Información

Ver `FIRESTORE_SETUP.md` para:
- Configuración detallada de Firebase
- Código Flutter completo
- Despliegue en la nube
- Solución de problemas
