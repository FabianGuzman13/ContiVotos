import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../data/models/candidato.dart';

/**
 * API Service - Comunicación con el Backend Node.js + Express
 * 
 * Este servicio reemplaza la comunicación directa con Firebase
 * y en su lugar usa HTTP para comunicarse con el backend
 */

class ApiService {
  // URL base del servidor backend
  // Cambiar según donde despliegues el servidor
  static const String baseUrl = 'http://10.0.2.2:3000/api';
  
  // Para dispositivo físico, usa la IP de tu computadora
  // static const String baseUrl = 'http://TU_IP:3000/api';

  final http.Client _client = http.Client();

  // ===============================
  // CANDIDATOS
  // ===============================

  /**
   * Obtiene todos los candidatos disponibles
   */
  Future<List<Candidato>> obtenerCandidatos() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/candidatos'),
        headers: {'Content-Type': 'application/json'}
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          List<dynamic> candidatosJson = data['data'];
          return candidatosJson.map((c) => Candidato.fromFirestore(c['id'], c)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error obtenerCandidatos: $e');
      return [];
    }
  }

  // ===============================
  // VOTOS
  // ===============================

  /**
   * Verifica si un usuario ya ha votado
   */
  Future<bool> yaVoto(String userId) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/votos/$userId'),
        headers: {'Content-Type': 'application/json'}
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['yaVoto'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error yaVoto: $e');
      return false;
    }
  }

  /**
   * Registra un nuevo voto
   */
  Future<bool> registrarVoto({
    required String userId,
    required String candidatoId,
    required String correo,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/votos'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'candidatoId': candidatoId,
          'correo': correo,
        })
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error registrarVoto: $e');
      return false;
    }
  }

  // ===============================
  // RESULTADOS
  // ===============================

  /**
   * Obtiene el conteo de votos de todos los candidatos
   */
  Future<Map<String, int>> obtenerConteoVotos() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/resultados'),
        headers: {'Content-Type': 'application/json'}
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          Map<String, int> conteo = {};
          List<dynamic> candidatos = data['data']['candidatos'];
          for (var c in candidatos) {
            conteo[c['id']] = c['votos'] ?? 0;
          }
          return conteo;
        }
      }
      return {};
    } catch (e) {
      print('Error obtenerConteoVotos: $e');
      return {};
    }
  }

  // ===============================
  // VERIFICACIONES
  // ===============================

  /**
   * Verifica si el usuario está dentro del campus universitario
   */
  Future<bool> verificarUbicacion(double lat, double lng) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/verificar-ubicacion?lat=$lat&lng=$lng'),
        headers: {'Content-Type': 'application/json'}
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['data']['dentroCampus'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error verificarUbicacion: $e');
      return false;
    }
  }

  /**
   * Verifica si un correo es institucional
   */
  Future<bool> verificarCorreo(String correo) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/verificar-correo/$correo'),
        headers: {'Content-Type': 'application/json'}
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['data']['esInstitucional'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error verificarCorreo: $e');
      return false;
    }
  }

  /**
   * Verifica el estado del servidor
   */
  Future<bool> verificarServidor() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/status'),
        headers: {'Content-Type': 'application/json'}
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    _client.close();
  }
}
