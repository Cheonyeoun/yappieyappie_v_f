import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class PushService {
  static final PushService instance = PushService._internal();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  PushService._internal();

  Future<void> initialize() async {
    try {
      // 1. Request permissions for Android 13+ and iOS
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted push notification permissions.');
        
        // 2. Get the FCM token and save it
        String? token = await _messaging.getToken();
        if (token != null) {
          await _saveTokenToFirestore(token);
        }

        // 3. Listen for token refreshes
        _messaging.onTokenRefresh.listen((newToken) {
          _saveTokenToFirestore(newToken);
        });

      } else {
        debugPrint('User declined push notification permissions.');
      }
    } catch (e) {
      debugPrint('Error initializing PushService: $e');
    }
  }

  Future<void> _saveTokenToFirestore(String token) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      await _db.collection('users').doc(uid).update({
        'fcmTokens': FieldValue.arrayUnion([token])
      });
      debugPrint('FCM Token securely saved to Firestore.');
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
      // If document doesn't have the field yet, set with merge
      await _db.collection('users').doc(uid).set({
        'fcmTokens': FieldValue.arrayUnion([token])
      }, SetOptions(merge: true));
    }
  }
}
