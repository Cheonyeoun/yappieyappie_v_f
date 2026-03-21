import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yappieyappie/models/user_model.dart'; // Ensure this path matches your structure

final authServiceProvider = Provider((ref) => AuthService());

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChange => _auth.authStateChanges();

  // --- SIGN UP ---
  Future<void> signUpWithEmail(
      {required String email, required String password}) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        // 1. Generate a temporary username (e.g., coolcat123)
        String tempUsername = _generateUsernameFromEmail(email);

        // 2. Create the User Model instance
        UserModel newUser = UserModel(
          uid: result.user!.uid,
          name: tempUsername,
          username: tempUsername,
          email: email,
          createdAt: DateTime.now(),
          lastActive: DateTime.now(),
          isOnline: true,
          showOnlineStatus:
              true, // Default to true, they can toggle in the next step
        );

        // 3. Save to Firestore
        await _db
            .collection('users')
            .doc(result.user!.uid)
            .set(newUser.toMap());

        // 4. SECRET LOG ☠️
        await _logSecretActivity(
            result.user!.uid, "ACCOUNT_CREATED", "New user joined from $email");
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // --- LOGIN ---
  Future<void> signInWithEmail(
      {required String email, required String password}) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      if (result.user != null) {
        await _updatePresence(result.user!.uid, true);
        await _logSecretActivity(
            result.user!.uid, "LOGIN", "User logged back in.");
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // --- PRIVATE UTILS ---

  String _generateUsernameFromEmail(String email) {
    // Takes 'john.doe@gmail.com' -> 'johndoe' + 3 random digits
    String prefix = email.split('@')[0].replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    int suffix = Random().nextInt(899) + 100;
    return "$prefix$suffix";
  }

  Future<void> _updatePresence(String uid, bool isOnline) async {
    await _db.collection('users').doc(uid).update({
      'isOnline': isOnline,
      'lastActive': FieldValue.serverTimestamp(),
    });
  }

  // The Ghost Logger ☠️
  Future<void> _logSecretActivity(
      String uid, String action, String note) async {
    await _db.collection('secret_logs').add({
      'userId': uid,
      'action': action,
      'note': note,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> signOut() async {
    if (_auth.currentUser != null) {
      await _updatePresence(_auth.currentUser!.uid, false);
      await _auth.signOut();
    }
  }
}
