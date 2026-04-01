import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class NotificationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Initialize OneSignal and save device ID
  Future<void> init() async {
    const oneSignalAppId = '7230eef8-03e0-4a88-bdf6-1326777ce1dd';

    // Initialize OneSignal
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    OneSignal.initialize(oneSignalAppId);

    // Request permission
    await OneSignal.Notifications.requestPermission(true);

    // Small delay
    await Future.delayed(const Duration(seconds: 1));

    // Get player ID
    final playerId = OneSignal.User.pushSubscription.id;

    print("Player ID: $playerId");

    // Save playerId to Firestore
    final uid = _auth.currentUser?.uid;
    if (uid != null && playerId != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {'playerId': playerId},
        SetOptions(merge: true),
      );
    }

    // Foreground handler
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      event.notification.display();
    });

    // Notification clicked handler
    OneSignal.Notifications.addClickListener((event) {
      print(
          'Notification clicked: ${event.notification.title} -> ${event.notification.body}');
    });
  }

  // NOTE: sendNotification (REST API call) removed for security.
  // Use sendNotificationToBackend instead.
  /// Backend grouped notification
  Future<void> sendNotificationToBackend({
    required String receiverUid,
    required List<Map<String, dynamic>> messages,
    required String playerId,
    required String chatRoomId,
    required int unreadCount,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("https://yappieyappie-v-f.onrender.com/send-notification"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "playerId": playerId,
          "chatRoomId": chatRoomId,
          "unreadCount": unreadCount,
          "messages": messages
              .map((msg) => {
                    "senderName": msg["senderName"] ?? "Someone",
                    "text": msg["text"] ?? "",
                    "profileImg": msg["profileImg"] ?? "",
                  })
              .toList(),
        }),
      );

      if (response.statusCode != 200) {
        print("Backend error: ${response.body}");
      }
    } catch (e) {
      print("Notification error: $e");
    }
  }
}
