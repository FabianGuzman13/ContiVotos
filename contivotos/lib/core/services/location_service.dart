import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

class LocationService {
  // Coordenadas campus (Universidad Continental - Campus Huancayo)
  // Av San Carlos 1980, Huancayo 12001
  static const double campusLat = -12.047505186140151;
  static const double campusLng = -75.19906082214352;

  static const double radioPermitido = 1000; // metros (1km para mayor precisión)

  /**
   * Verifica si está dentro del campus
   * (Este método se usa cuando se active la verificación de ubicación)
   */
  Future<bool> estaDentroCampus() async {
    // En web, la ubicación no funciona igual - permitir acceso
    if (kIsWeb) {
      return true; // En web siempre permitir (o implementar con HTML5 Geolocation)
    }

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return false;
      }

      // Obtener posición actual
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      double distancia = Geolocator.distanceBetween(
        campusLat,
        campusLng,
        pos.latitude,
        pos.longitude,
      );

      return distancia <= radioPermitido;
    } catch (e) {
      // Si hay error, no permitir acceso
      return false;
    }
  }
}
