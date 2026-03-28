import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yappieyappie/models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user once (good for profile view)
  Future<UserModel> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();

    // Return fallback user if document does not exist
    if (!doc.exists || doc.data() == null) {
      return UserModel(
        uid: uid,
        name: 'User',
        email: '',
      );
    }

    return UserModel.fromMap(doc.data()!);
  }

  // Stream of user updates (used in chat, presence, etc.)
  Stream<UserModel> getUserStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      // Instead of throwing error, return safe fallback
      if (!snapshot.exists || snapshot.data() == null) {
        return UserModel(
          uid: uid,
          name: 'User',
          email: '',
        );
      }

      return UserModel.fromMap(snapshot.data()!);
    });
  }
}
