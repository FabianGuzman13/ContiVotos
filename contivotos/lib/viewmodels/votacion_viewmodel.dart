import 'dart:async';
import 'package:flutter/material.dart';
import '../core/services/votacion_service.dart';
import '../core/services/location_service.dart';
import '../core/services/auth_service.dart';
import '../data/models/candidato.dart';

class VotacionViewModel extends ChangeNotifier {
  final _service = VotacionService();
  final _location = LocationService();
  final _authService = AuthService();

  // Streams para tiempo real
  StreamSubscription? _candidatosSub;
  StreamSubscription? _conteoSub;
  StreamSubscription? _votoSub;

  List<Candidato> candidatos = [];
  Map<String, int> conteoVotos = {};
  bool cargando = true;
  bool yaVotoUsuario = false;
  bool dentroCampus = false;
  bool mostrarDialogoVoto = false;
  
  // Estado de elección culminada (alguien alcanzó 50 votos)
  bool eleccionCulminada = false;
  Candidato? candidatoGanador;

  // ✅ Verificación de ubicación ACTIVADA
  static const bool REQUERIR_UBICACION = true;

  VotacionViewModel() {
    _iniciarListeners();
  }

  void _iniciarListeners() {
    // Iniciar listeners de tiempo real
    _service.iniciarListeners();

    // Suscribirse a cambios en candidatos
    _candidatosSub = _service.candidatosStream.listen((candidatos) {
      // Ordenar candidatos por número
      candidatos.sort((a, b) => a.numero.compareTo(b.numero));
      this.candidatos = candidatos;
      cargando = false;
      notifyListeners();
    });

    // Suscribirse a cambios en conteo de votos
    _conteoSub = _service.conteoStream.listen((conteo) {
      conteoVotos = conteo;
      notifyListeners();
    });

    // Suscribirse a cambios en estado de voto
    _votoSub = _service.votoStream.listen((yaVoto) {
      yaVotoUsuario = yaVoto;
      notifyListeners();
    });
  }

  // Cargar datos iniciales
  Future<void> cargar() async {
    cargando = true;
    notifyListeners();

    // Verificar ubicación solo si está habilitada
    if (REQUERIR_UBICACION) {
      try {
        dentroCampus = await _location.estaDentroCampus();
      } catch (e) {
        dentroCampus = false;
      }
    } else {
      dentroCampus = true;
    }

    // Cargar candidatos inicial
    try {
      candidatos = await _service.obtenerCandidatos();
      // Ordenar candidatos por número
      candidatos.sort((a, b) => a.numero.compareTo(b.numero));
    } catch (e) {
      candidatos = [];
    }

    // Cargar conteo inicial
    try {
      conteoVotos = await _service.obtenerConteoVotos();
    } catch (e) {
      conteoVotos = {};
    }

    // Cargar estado de voto
    try {
      yaVotoUsuario = await _service.yaVoto();
    } catch (e) {
      yaVotoUsuario = false;
    }

    cargando = false;
    notifyListeners();
  }

  // Método para registrar voto
  Future<Map<String, dynamic>> votar(Candidato candidato) async {
    if (REQUERIR_UBICACION && !dentroCampus) {
      return {'success': false, 'error': 'Debes estar dentro del campus'};
    }
    if (yaVotoUsuario) {
      return {'success': false, 'error': 'Ya votaste'};
    }
    if (hayGanador) {
      return {'success': false, 'error': 'La elección ya culminó'};
    }

    // Verificar si el candidato ya alcanzó el límite
    final votosActuales = conteoVotos[candidato.id] ?? 0;
    if (votosActuales >= VotacionService.VOTOS_PARA_GANAR) {
      return {'success': false, 'error': 'Este candidato ya alcanzó el límite de ${VotacionService.VOTOS_PARA_GANAR} votos'};
    }

    final resultado = await _service.registrarVoto(candidato.id);

    // Actualizar estado local
    if (resultado['success'] == true) {
      yaVotoUsuario = true;
      mostrarDialogoVoto = true;
      
      // Verificar si hay ganador
      if (resultado['ganador'] == true) {
        eleccionCulminada = true;
        candidatoGanador = candidato;
      }
    }
    
    notifyListeners();
    return resultado;
  }

  // Método para borrar voto (para pruebas)
  Future<void> borrarMiVoto() async {
    await _service.borrarMiVoto();
    yaVotoUsuario = false;
    notifyListeners();
  }

  // Confirmar que el diálogo fue mostrado
  void confirmarDialogoMostrado() {
    mostrarDialogoVoto = false;
    notifyListeners();
  }

  // Reiniciar para ver los votos
  void reiniciarParaVerVotos() {
    mostrarDialogoVoto = false;
    notifyListeners();
  }

  // Método para cerrar sesión
  Future<void> logout() async {
    await _authService.signOut();
    notifyListeners();
  }

  // Verificar si un candidato alcanzó el límite de votos
  bool candidatoAlcanzoLimite(String candidatoId) {
    final votos = conteoVotos[candidatoId] ?? 0;
    return votos >= VotacionService.VOTOS_PARA_GANAR;
  }

  // Verificar si ALGÚN candidato ha alcanzado el límite (en tiempo real)
  bool get hayGanador {
    for (var candidato in candidatos) {
      if (candidatoAlcanzoLimite(candidato.id)) {
        return true;
      }
    }
    return false;
  }

  // Obtener el candidato que va ganando (el primero en alcanzar 50)
  Candidato? get candidatoLider {
    for (var candidato in candidatos) {
      if (candidatoAlcanzoLimite(candidato.id)) {
        return candidato;
      }
    }
    return null;
  }

  @override
  void dispose() {
    _candidatosSub?.cancel();
    _conteoSub?.cancel();
    _votoSub?.cancel();
    _service.dispose();
    super.dispose();
  }
}
