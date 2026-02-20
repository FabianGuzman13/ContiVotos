# Guía: Backend FastAPI + Firestore + Flutter

Esta guía te explica cómo configurar el backend para usar Firebase Firestore en lugar de SQL Server, y cómo conectarlo con tu proyecto Flutter.

## 📋 Cambios Realizados

El backend ha sido actualizado para usar **Firebase Firestore** como base de datos:

### ✅ Ventajas de usar Firestore:
- **Tiempo real nativo**: Sin necesidad de WebSocket complejo
- **Escalabilidad automática**: Firestore escala automáticamente
- **Sincronización con Flutter**: Firebase SDK para Flutter incluido
- **Menos código**: No necesitas SQL ni migraciones

---

## 🚀 Paso 1: Configurar Firebase

### 1.1 Crear proyecto en Firebase Console

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Crea un nuevo proyecto
3. Agrega una aplicación web (para el backend)
4. Ve a **Configuración del proyecto > Cuentas de servicio**
5. Genera una nueva clave privada (archivo JSON)
6. Guarda el archivo como `firebase-credentials.json` en la raíz del backend

### 1.2 Instalar dependencias del backend

```bash
# Activar entorno virtual
venv\Scripts\activate

# Instalar nuevas dependencias
pip install -r requirements.txt
```

### 1.3 Configurar variables de entorno

Copia el archivo de ejemplo:

```bash
cp .env.example .env
```

Edita `.env` y configura la ruta a tus credenciales:

```env
FIREBASE_CREDENTIALS_PATH=./firebase-credentials.json
```

O si prefieres usar variables de entorno (más seguro para producción):

```env
FIREBASE_PROJECT_ID=tu-proyecto-id
FIREBASE_PRIVATE_KEY_ID=tu-private-key-id
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=tu-cuenta@tu-proyecto.iam.gserviceaccount.com
FIREBASE_CLIENT_ID=tu-client-id
```

---

## 🗄️ Paso 2: Estructura de Firestore

Las colecciones se crearán automáticamente al insertar datos, pero aquí está la estructura esperada:

### Colección: `candidatos`

```json
{
  "candidatoId": "auto-generado-por-firestore",
  "nombre": "Juan Pérez",
  "cargo": "Delegado",
  "imagen": "https://url-de-la-imagen.com/foto.jpg",
  "semestre": "VIII",
  "experiencia": "5 años de experiencia...",
  "propuesta": "Mejorar la biblioteca...",
  "vision": "Un campus más inclusivo...",
  "numero": 1,
  "votos": 150,
  "created_at": "2024-01-15T10:30:00Z",
  "updated_at": "2024-01-15T10:30:00Z"
}
```

### Colección: `votos`

```json
{
  "votoId": "auto-generado-por-firestore",
  "candidatoId": "id-del-candidato",
  "correo": "estudiante@continental.edu.pe",
  "fecha": "2024-01-15T14:20:00Z"
}
```

---

## 🧪 Paso 3: Probar el Backend

### Iniciar el servidor

```bash
python main.py
```

O si prefieres recarga automática:

```bash
uvicorn app.main:app --reload
```

### Endpoints disponibles

#### Candidatos
- `GET /api/candidatos` - Listar todos
- `GET /api/candidatos/{id}` - Obtener uno
- `POST /api/candidatos` - Crear
- `PUT /api/candidatos/{id}` - Actualizar
- `DELETE /api/candidatos/{id}` - Eliminar
- `GET /api/candidatos/ganadores/top/{n}` - Top N candidatos

#### Votos
- `POST /api/votos` - Registrar voto
- `GET /api/votos/tiempo-real` - Estadísticas
- `GET /api/votos/verificar-correo/{correo}` - Verificar si ya votó
- `GET /api/votos/verificar-ubicacion?lat={lat}&lng={lng}` - Verificar ubicación
- `WS /api/votos/ws` - WebSocket para tiempo real

### Documentación automática

Visita:
- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

---

## 📱 Paso 4: Conectar con Flutter

### 4.1 Agregar dependencias en `pubspec.yaml`

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # HTTP para API REST
  http: ^1.1.0
  
  # Firebase
  firebase_core: ^2.24.2
  firebase_auth: ^4.16.0
  cloud_firestore: ^4.14.0
  
  # WebSocket (opcional, para tiempo real)
  web_socket_channel: ^2.4.0
```

### 4.2 Configurar Firebase en Flutter

#### Android (`android/app/build.gradle`)

```gradle
defaultConfig {
    minSdkVersion 21  // Importante: Firestore requiere 21+
    // ... resto de configuración
}
```

#### iOS (`ios/Podfile`)

```ruby
platform :ios, '12.0'  # Firestore requiere iOS 12+
```

### 4.3 Inicializar Firebase

```dart
// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Este archivo se genera automáticamente

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(MyApp());
}
```

### 4.4 Configuración de URLs

```dart
// lib/config/api_config.dart
class ApiConfig {
  // Backend FastAPI
  static const String baseUrl = 'http://10.0.2.2:8000/api'; // Android Emulator
  // static const String baseUrl = 'http://127.0.0.1:8000/api'; // iOS Simulator
  // static const String baseUrl = 'https://tu-api.com/api'; // Producción
  
  static const String wsUrl = 'ws://10.0.2.2:8000/api/votos/ws';
}
```

### 4.5 Servicio API

```dart
// lib/services/api_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';

class ApiService {
  
  // GET - Candidatos
  static Future<List<dynamic>> getCandidatos() async {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/candidatos'));
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data; // Lista de candidatos
    } else {
      throw Exception('Error al cargar candidatos');
    }
  }
  
  // POST - Votar
  static Future<Map<String, dynamic>> votar(int candidatoId, String correo) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/votos'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'candidatoId': candidatoId,
        'correo': correo,
      }),
    );
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['detail'] ?? 'Error al votar');
    }
  }
  
  // GET - Resultados
  static Future<Map<String, dynamic>> getResultados() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/votos/tiempo-real'),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data']; // {total_votos, candidatos}
    } else {
      throw Exception('Error al cargar resultados');
    }
  }
}
```

### 4.6 Usar Firestore Directamente (Tiempo Real)

Si quieres tiempo real sin WebSocket, usa Firestore SDK directamente:

```dart
// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Escuchar candidatos en tiempo real
  Stream<List<Map<String, dynamic>>> getCandidatosStream() {
    return _firestore
        .collection('candidatos')
        .orderBy('votos', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['candidatoId'] = doc.id;
        return data;
      }).toList();
    });
  }
  
  // Escuchar votos en tiempo real
  Stream<int> getTotalVotosStream() {
    return _firestore
        .collection('candidatos')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.fold<int>(
        0, 
        (sum, doc) => sum + (doc.data()['votos'] as int? ?? 0)
      );
    });
  }
}
```

### 4.7 Widget con tiempo real

```dart
// lib/screens/resultados_screen.dart
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class ResultadosScreen extends StatelessWidget {
  final FirestoreService _firestoreService = FirestoreService();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Resultados en Tiempo Real')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firestoreService.getCandidatosStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          
          final candidatos = snapshot.data!;
          
          return ListView.builder(
            itemCount: candidatos.length,
            itemBuilder: (context, index) {
              final c = candidatos[index];
              return ListTile(
                leading: CircleAvatar(child: Text('${index + 1}')),
                title: Text(c['nombre']),
                subtitle: Text('${c['votos']} votos'),
              );
            },
          );
        },
      ),
    );
  }
}
```

---

## 🔥 Paso 5: Configuración de Seguridad (Firestore Rules)

En Firebase Console, ve a **Firestore Database > Reglas** y configura:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Permitir lectura pública
    match /candidatos/{candidatoId} {
      allow read: if true;
      allow write: if false; // Solo el backend puede escribir
    }
    
    // Votos - solo lectura pública, escritura controlada
    match /votos/{votoId} {
      allow read: if true;
      allow create: if request.auth != null; // O tu lógica de autenticación
    }
  }
}
```

---

## 🚀 Opciones de Despliegue

### Opción A: Backend local + Firestore (Desarrollo)

```bash
# En tu PC
python main.py

# En Flutter, usar IP de tu PC
static const String baseUrl = 'http://192.168.1.X:8000/api';
```

### Opción B: Backend en la nube (Producción)

#### Opción 1: Google Cloud Run (Recomendado)

```bash
# Crear Dockerfile
cat > Dockerfile << 'EOF'
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
EOF

# Deploy a Cloud Run
gcloud run deploy tu-api-votacion \
  --source . \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated
```

#### Opción 2: Railway / Render / Heroku

1. Subir código a GitHub
2. Conectar con Railway/Render/Heroku
3. Configurar variables de entorno
4. Deploy automático

### Opción C: Solo Firestore + Firebase Functions (Sin FastAPI)

Si prefieres no mantener un backend:

```dart
// Votar directamente desde Flutter
Future<void> votar(String candidatoId, String correo) async {
  // Verificar si ya votó
  final query = await FirebaseFirestore.instance
      .collection('votos')
      .where('correo', isEqualTo: correo)
      .get();
  
  if (query.docs.isNotEmpty) {
    throw Exception('Este correo ya votó');
  }
  
  // Registrar voto
  await FirebaseFirestore.instance.collection('votos').add({
    'candidatoId': candidatoId,
    'correo': correo,
    'fecha': FieldValue.serverTimestamp(),
  });
  
  // Incrementar contador (transacción)
  await FirebaseFirestore.instance
      .collection('candidatos')
      .doc(candidatoId)
      .update({
        'votos': FieldValue.increment(1),
      });
}
```

---

## ⚠️ Notas Importantes

1. **Seguridad**: Las credenciales de Firebase (`firebase-credentials.json`) NUNCA deben subirse a GitHub. Están en `.gitignore`.

2. **CORS**: El backend ya está configurado para aceptar conexiones de cualquier origen en desarrollo. En producción, configura `allow_origins` con tu dominio específico.

3. **WebSocket vs Firestore**: 
   - WebSocket es útil para notificaciones push desde el backend
   - Firestore SDK es mejor para tiempo real continuo
   - Puedes usar ambos: Firestore para datos, WebSocket para eventos

4. **Límites de Firestore**: 
   - 1MB por documento
   - 1 write/segundo por documento (para evitar contención)
   - El incremento de votos usa operaciones atómicas

5. **Costos**: Firestore tiene un nivel gratuito generoso (50K lecturas/día, 20K escrituras/día).

---

## 🆘 Solución de Problemas

### Error: "Default Firebase app already exists"

El backend ya maneja esto automáticamente en `config/firebase.py`.

### Error: "Permission denied" en Firestore

Verifica las reglas de seguridad en Firebase Console.

### Error: "Address already in use" (puerto 8000 ocupado)

```bash
# Cambiar puerto
uvicorn app.main:app --reload --port 8001
```

### Flutter no conecta al backend

1. Verifica que el backend esté corriendo: `http://localhost:8000/docs`
2. Usa la IP correcta según tu dispositivo
3. Asegúrate que PC y móvil estén en la misma red WiFi
4. Desactiva temporalmente el firewall para probar

---

## 📞 Soporte

Si tienes problemas:

1. Revisa los logs del backend
2. Verifica la conexión con Firestore en Firebase Console
3. Prueba los endpoints con Postman o curl
4. Revisa la consola de Firebase para errores

---

**¡Listo!** Tu backend ahora usa Firestore y está listo para conectarse con Flutter. 🎉
