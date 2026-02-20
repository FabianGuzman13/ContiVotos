import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  Future<void> votar(String userId, String candidatoId) async {
    await _db.collection('votos').doc(userId).set({
      'candidato': candidatoId,
      'fecha': DateTime.now(),
    });
  }

  Future<bool> yaVoto(String userId) async {
    final doc = await _db.collection('votos').doc(userId).get();
    return doc.exists;
  }
}
