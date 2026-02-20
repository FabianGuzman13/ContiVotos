import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> signInWithGoogle() async {
    // 🌐 WEB (Chrome)
    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      provider.setCustomParameters({
        'prompt': 'select_account'
      });
      final userCredential =
          await _auth.signInWithPopup(provider);
      return userCredential.user;
    }

    // 📱 ANDROID - Clear previous sign-in to allow account selection
    await _auth.signOut();
    
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential =
        await _auth.signInWithCredential(credential);

    return userCredential.user;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn().disconnect();
  }
}
