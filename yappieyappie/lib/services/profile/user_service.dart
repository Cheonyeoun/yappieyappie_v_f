// services/user_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yappieyappie/models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user once (good for profile view)
  Future<UserModel> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) {
      throw Exception('User document not found for uid: $uid');
    }
    return UserModel.fromMap(doc.data()!);
  }

  // Stream of user updates (good if you want live presence / profile updates)
  Stream<UserModel> getUserStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        throw Exception('User document not found for uid: $uid');
      }
      return UserModel.fromMap(snapshot.data()!);
    });
  }
}
