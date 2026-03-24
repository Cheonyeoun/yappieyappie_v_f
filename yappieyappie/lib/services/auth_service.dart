import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yappieyappie/models/user_model.dart';

final authServiceProvider = Provider((ref) => AuthService());

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream to listen to Auth State (Logged In / Logged Out)
  Stream<User?> get authStateChange => _auth.authStateChanges();

  // --- SIGN UP (MANDATORY: Name, Email, Password) ---
  Future<void> signUpWithEmail({
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
        // Initial Model: Username is empty string as per your model update
        UserModel newUser = UserModel(
          uid: result.user!.uid,
          name: name.trim(),
          username: '',
          email: email.trim(),
          createdAt: DateTime.now(),
          lastActive: DateTime.now(),
          isOnline: true,
          showOnlineStatus: true,
        );

        // Save to Firestore
        await _db
            .collection('users')
            .doc(result.user!.uid)
            .set(newUser.toMap());

        // SECRET LOG ☠️
        await _logSecretActivity(result.user!.uid, "ACCOUNT_CREATED",
            "Name: $name registered via Email");
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // --- LOGIN (IDENTIFIER: Username OR Email) ---
  Future<void> signIn({
    required String identifier,
    required String password,
  }) async {
    try {
      String email = identifier.trim();

      // If identifier is NOT an email, treat it as a username
      if (!identifier.contains('@')) {
        final userDoc = await _db
            .collection('users')
            .where('username', isEqualTo: identifier.trim().toLowerCase())
            .limit(1)
            .get();

        if (userDoc.docs.isEmpty) {
          throw Exception("No account found with that username.");
        }
        // Resolve the email linked to that unique username
        email = userDoc.docs.first.get('email');
      }

      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);

      if (result.user != null) {
        await _updatePresence(result.user!.uid, true);
        await _logSecretActivity(
            result.user!.uid, "LOGIN", "Logged in via: $identifier");
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // --- ONBOARDING: SET OR GENERATE USERNAME ---
  Future<void> finalizeUsername(
      {required String uid, String? chosenUsername}) async {
    String finalUsername;

    if (chosenUsername != null && chosenUsername.isNotEmpty) {
      // User set their own
      finalUsername = chosenUsername.toLowerCase().trim();
    } else {
      // USER SKIPPED: Generate unique one from Name/Email
      final doc = await _db.collection('users').doc(uid).get();
      final userData = doc.data();
      String base =
          userData?['name'] ?? userData?['email'].split('@')[0] ?? "user";
      finalUsername =
          _generateUniqueHandle(base.replaceAll(' ', '').toLowerCase());
    }

    await _db.collection('users').doc(uid).update({'username': finalUsername});
    await _logSecretActivity(uid, "USERNAME_SET", "Handle: @$finalUsername");
  }

  // --- REAL-TIME VALIDATION ---
  Future<bool> isUsernameAvailable(String username) async {
    if (username.length < 3) return false;
    final result = await _db
        .collection('users')
        .where('username', isEqualTo: username.toLowerCase().trim())
        .limit(1)
        .get();
    return result.docs.isEmpty;
  }

  // --- UTILS ---

  String _generateUniqueHandle(String base) {
    int suffix = Random().nextInt(8999) + 1000;
    return "$base$suffix";
  }

  Future<void> _updatePresence(String uid, bool isOnline) async {
    await _db.collection('users').doc(uid).update({
      'isOnline': isOnline,
      'lastActive': FieldValue.serverTimestamp(),
    });
  }

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
