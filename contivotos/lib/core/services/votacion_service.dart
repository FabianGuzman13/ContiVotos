import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/candidato.dart';

class VotacionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Límite de votos para ganar
  static const int VOTOS_PARA_GANAR = 50;

  // StreamControllers para notificaciones en tiempo real
  final StreamController<List<Candidato>> _candidatosController = StreamController<List<Candidato>>.broadcast();
  final StreamController<Map<String, int>> _conteoController = StreamController<Map<String, int>>.broadcast();
  final StreamController<bool> _votoController = StreamController<bool>.broadcast();

  Stream<List<Candidato>> get candidatosStream => _candidatosController.stream;
  Stream<Map<String, int>> get conteoStream => _conteoController.stream;
  Stream<bool> get votoStream => _votoController.stream;

  // ===============================
  // SUSCRIPCIONES EN TIEMPO REAL
  // ===============================

  void iniciarListeners() {
    // Listener de candidatos en tiempo real
    _db.collection('candidatos').snapshots().listen((snap) {
      final candidatos = snap.docs
          .map((d) => Candidato.fromFirestore(d.id, d.data()))
          .toList();
      _candidatosController.add(candidatos);
    });

    // Listener de conteo de votos
    _db.collection('candidatos').snapshots().listen((snap) {
      Map<String, int> conteo = {};
      for (var doc in snap.docs) {
        conteo[doc.id] = (doc.data()['votos'] ?? 0) as int;
      }
      _conteoController.add(conteo);
    });

    // Listener del estado de voto del usuario actual
    final user = _auth.currentUser;
    if (user != null) {
      _db.collection('votos').doc(user.uid).snapshots().listen((doc) {
        _votoController.add(doc.exists);
      });
    }
  }

  void dispose() {
    _candidatosController.close();
    _conteoController.close();
    _votoController.close();
  }

  // ===============================
  // OBTENER CANDIDATOS (una vez)
  // ===============================
  Future<List<Candidato>> obtenerCandidatos() async {
    try {
      final snap = await _db.collection('candidatos').get();
      return snap.docs
          .map((d) => Candidato.fromFirestore(d.id, d.data()))
          .toList();
    } catch (e) {
      print('Error al obtener candidatos: $e');
      return [];
    }
  }

  // ===============================
  // VERIFICAR VOTO
  // ===============================
  Future<bool> yaVoto() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final doc = await _db.collection('votos').doc(user.uid).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  // ===============================
  // REGISTRAR VOTO
  // ===============================
  Future<Map<String, dynamic>> registrarVoto(String candidatoId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {'success': false, 'error': 'Usuario no autenticado'};

      // Verificar si ALGÚN candidato ya alcanzó el límite de votos (en tiempo real)
      final snap = await _db.collection('candidatos').get();
      for (var doc in snap.docs) {
        final votosActuales = (doc.data()['votos'] ?? 0) as int;
        if (votosActuales >= VOTOS_PARA_GANAR) {
          return {'success': false, 'error': 'La elección ya culminó. Hay un ganador proclamado.'};
        }
      }

      // Verificar si el candidato específico ya alcanzó el límite
      final candidatoDoc = await _db.collection('candidatos').doc(candidatoId).get();
      final votosActuales = (candidatoDoc.data()?['votos'] ?? 0) as int;
      
      if (votosActuales >= VOTOS_PARA_GANAR) {
        return {'success': false, 'error': 'Este candidato ya alcanzó el límite de ${VOTOS_PARA_GANAR} votos'};
      }

      await _db.collection('votos').doc(user.uid).set({
        'candidatoId': candidatoId,
        'correo': user.email,
        'fecha': Timestamp.now(),
      });

      // Incrementar contador del candidato
      await _db.collection('candidatos').doc(candidatoId).update({
        'votos': FieldValue.increment(1),
      });

      // Verificar si después de este voto alcanzó el límite (para proclamar ganador)
      final nuevosVotos = votosActuales + 1;
      if (nuevosVotos >= VOTOS_PARA_GANAR) {
        return {'success': true, 'ganador': true, 'candidatoId': candidatoId};
      }

      return {'success': true, 'ganador': false};
    } catch (e) {
      print('Error al registrar voto: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ===============================
  // BORRAR VOTO (para pruebas)
  // ===============================
  Future<void> borrarMiVoto() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Primero obtener el voto actual para saber qué candidato restar
      final votoDoc = await _db.collection('votos').doc(user.uid).get();
      
      if (votoDoc.exists) {
        final candidatoId = votoDoc.data()?['candidatoId'];
        
        // Eliminar el voto
        await _db.collection('votos').doc(user.uid).delete();
        
        // Decrementar contador del candidato
        if (candidatoId != null) {
          await _db.collection('candidatos').doc(candidatoId).update({
            'votos': FieldValue.increment(-1),
          });
        }
        
        print('✅ Voto eliminado correctamente');
      }
    } catch (e) {
      print('Error al borrar voto: $e');
    }
  }

  // ===============================
  // OBTENER CONTEO DE VOTOS
  // ===============================
  Future<Map<String, int>> obtenerConteoVotos() async {
    try {
      Map<String, int> conteo = {};
      final snap = await _db.collection('candidatos').get();

      for (var doc in snap.docs) {
        conteo[doc.id] = (doc.data()['votos'] ?? 0) as int;
      }

      return conteo;
    } catch (e) {
      return {};
    }
  }

  // ===============================
  // VERIFICAR SI HAY GANADOR
  // ===============================
  Future<Candidato?> obtenerGanador() async {
    try {
      final snap = await _db.collection('candidatos').get();
      
      for (var doc in snap.docs) {
        final votos = (doc.data()['votos'] ?? 0) as int;
        if (votos >= VOTOS_PARA_GANAR) {
          return Candidato.fromFirestore(doc.id, doc.data());
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  // ===============================
  // VERIFICAR SI UN CANDIDATO ALCANZÓ EL LÍMITE
  // ===============================
  Future<bool> candidatoAlcanzoLimite(String candidatoId) async {
    try {
      final doc = await _db.collection('candidatos').doc(candidatoId).get();
      final votos = (doc.data()?['votos'] ?? 0) as int;
      return votos >= VOTOS_PARA_GANAR;
    } catch (e) {
      return false;
    }
  }
}
