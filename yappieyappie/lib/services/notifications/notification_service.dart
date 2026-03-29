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
    await Future.delayed(const Duration(seconds: 2));

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
      // `event` type is inferred, no import needed
      event.notification.display();
    });

    // Notification clicked handler
    OneSignal.Notifications.addClickListener((event) {
      // `openedResult` type is inferred automatically
      print(
          'Notification clicked: ${event.notification.title} -> ${event.notification.body}');
    });
  }

  /// Send notification using OneSignal REST API
  Future<void> sendNotification({
    required String playerId,
    required String title,
    required String body,
    String? bigPicture,
  }) async {
    const appId = '7230eef8-03e0-4a88-bdf6-1326777ce1dd';
    const restApiKey =
        'os_v2_app_oiyo56ad4bfirppwcmtho7hb3w54aahbkmcuha567q57i242hkfoklzj37a4kphi6cwqbejtbujoxg4fufyl6bvgdopcrdncs5mllgi';

    final url = Uri.parse('https://onesignal.com/api/v1/notifications');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Basic $restApiKey',
      },
      body: jsonEncode({
        'app_id': appId,
        'include_player_ids': [playerId],
        'headings': {'en': title},
        'contents': {'en': body},
        'big_picture': bigPicture ?? '',
        'android_background_layout': {
          'image': bigPicture ?? '',
          'headings_color': 'FF000000',
          'contents_color': 'FF000000',
        },
        'ios_attachments': {'id': bigPicture ?? ''},
      }),
    );

    if (response.statusCode != 200) {
      print('Notification failed: ${response.body}');
    }
  }

  /// Backend grouped notification
  Future<void> sendNotificationToBackend({
    required String receiverUid,
    required List<Map<String, dynamic>> messages,
    required String playerId, // FIXED: Added missing parameter
    required String chatRoomId, // FIXED: Added missing parameter
    required int unreadCount, // FIXED: Added missing parameter
  }) async {
    try {
      final response = await http.post(
        Uri.parse("http://10.180.146.36:3000/send-notification"),
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
