import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yappieyappie/models/profile/user_model.dart';

final authServiceProvider = Provider((ref) => AuthService());

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Listen to Auth State Changes
  Stream<User?> get authStateChange => _auth.authStateChanges();

  // --- SIGN UP ---
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (result.user != null) {
        String suggestedUsername = _generateSuggestedUsername(name, email);

        UserModel newUser = UserModel(
          uid: result.user!.uid,
          name: name.trim(),
          username: suggestedUsername,
          email: email.trim(),
          createdAt: DateTime.now(),
          lastActive: DateTime.now(),
          isOnline: true, // User starts online
        );

        await _db
            .collection('users')
            .doc(result.user!.uid)
            .set(newUser.toMap());
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // --- LOGIN ---
  Future<void> signIn({
    required String identifier,
    required String password,
  }) async {
    try {
      String email = identifier.trim();

      if (!identifier.contains('@')) {
        final query = await _db
            .collection('users')
            .where('username', isEqualTo: identifier.trim().toLowerCase())
            .limit(1)
            .get();

        if (query.docs.isEmpty) throw Exception("Username not found");
        email = query.docs.first.get('email');
      }

      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);

      if (result.user != null) {
        // Update presence to online after successful login
        await _updatePresence(result.user!.uid, true);
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // --- LOG OUT ---
  Future<void> signOut() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      // 1. Set status to offline in Firestore
      await _updatePresence(user.uid, false);
      // 2. Sign out from Firebase Auth
      await _auth.signOut();
    }
  }

  // --- PRIVATE UTILS ---

  Future<void> _updatePresence(String uid, bool isOnline) async {
    await _db.collection('users').doc(uid).update({
      'isOnline': isOnline,
      'lastActive': FieldValue.serverTimestamp(),
    });
  }

  String _generateSuggestedUsername(String name, String email) {
    String base = name.isNotEmpty
        ? name.replaceAll(' ', '').toLowerCase()
        : email.split('@')[0].replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    int suffix = Random().nextInt(899) + 100;
    return "$base$suffix";
  }
}
