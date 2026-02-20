import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/services/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool isLoading = false;
  String? error;
  User? user;

  Future<bool> loginWithGoogle() async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      user = await _authService.signInWithGoogle();

      if (user == null) {
        error = 'Inicio de sesión cancelado';
        return false;
      }

      // Validar correo institucional
      if (user!.email == null || !user!.email!.endsWith('@continental.edu.pe')) {
        await _authService.signOut();
        error = 'Solo correos institucionales UC';
        return false;
      }

      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.signOut();
    user = null;
    notifyListeners();
  }
}
