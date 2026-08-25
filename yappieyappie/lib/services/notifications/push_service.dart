import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:yappieyappie/core/globals/app_globals.dart';
import 'package:yappieyappie/services/router/app_router.dart';
import 'package:yappieyappie/models/profile/user_model.dart';
import 'package:yappieyappie/features/chat/presentation/screens/private_chat_screen.dart';

class PushService {
  static final PushService instance = PushService._internal();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  PushService._internal();

  Future<void> initialize() async {
    try {
      // 1. Initialize OneSignal
      final appId = dotenv.env['ONESIGNAL_APP_ID'];
      if (appId != null) {
        OneSignal.initialize(appId);
      } else {
        debugPrint("Error: ONESIGNAL_APP_ID not found in .env");
      }

      // 2. Request Notification Permissions
      OneSignal.Notifications.requestPermission(true);

      // 3. Save Player ID to Firestore when user logs in
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        OneSignal.login(uid); // Associates OneSignal ID with Firebase UID
        
        // Wait briefly for OneSignal to generate the Player ID
        await Future.delayed(const Duration(seconds: 1));
        final pushSubscriptionId = OneSignal.User.pushSubscription.id;
        
        if (pushSubscriptionId != null) {
          await _saveTokenToFirestore(pushSubscriptionId);
        }
        
        // Also get FCM token for CallKit (background VoIP/Data pushes)
        final fcmToken = await _fcm.getToken();
        if (fcmToken != null) {
          await _saveFCMTokenToFirestore(fcmToken);
        }
        
        _fcm.onTokenRefresh.listen((newToken) {
           _saveFCMTokenToFirestore(newToken);
        });
      }

      // 4. Native Local Suppression (The Magic)
      // This listener catches the push before it displays on screen.
      OneSignal.Notifications.addForegroundWillDisplayListener((event) {
        final additionalData = event.notification.additionalData;
        
        // If the push is for the chat we are currently looking at, SUPPRESS IT NATIVELY
        if (additionalData != null && additionalData['chatId'] == AppGlobals.activeChatId) {
          event.preventDefault(); 
          debugPrint("OneSignal: Natively Suppressed notification for active chat.");
        } else {
          // Allow it to display as a Heads-Up banner
          event.notification.display();
        }
      });

      // 5. Deep Linking (Tap-to-Open)
      // When a user taps the notification, route them to the specific chat.
      OneSignal.Notifications.addClickListener((event) async {
        final additionalData = event.notification.additionalData;
        if (additionalData != null) {
          final senderId = additionalData['senderId'] as String?;
          if (senderId != null) {
            try {
              final userDoc = await _db.collection('users').doc(senderId).get();
              if (userDoc.exists) {
                final userMap = userDoc.data()!;
                userMap['uid'] = userDoc.id; // Ensure uid is present for fromMap
                final user = UserModel.fromMap(userMap);
                
                // If the app is already fully loaded in the background, push immediately.
                // Otherwise, save it to pendingChatUser so HomeScreen can push it once Splash is done.
                if (AppGlobals.isAppReady && rootNavigatorKey.currentContext != null) {
                  Navigator.push(
                    rootNavigatorKey.currentContext!,
                    MaterialPageRoute(
                      builder: (_) => PrivateChatScreen(otherUser: user),
                    ),
                  );
                } else {
                  AppGlobals.pendingChatUser = user;
                  debugPrint("OneSignal: Saved pending deep link for cold boot.");
                }
              }
            } catch (e) {
              debugPrint('Error navigating to chat: $e');
            }
          }
        }
      });

    } catch (e) {
      debugPrint('Error initializing OneSignal: $e');
    }
  }

  Future<void> _saveTokenToFirestore(String token) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      await _db.collection('users').doc(uid).set({
        'oneSignalPlayerId': token
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving OneSignal token: $e');
    }
  }

  Future<void> _saveFCMTokenToFirestore(String token) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      await _db.collection('users').doc(uid).set({
        'fcmToken': token
      }, SetOptions(merge: true));
      debugPrint('FCM Token securely saved to Firestore for calls.');
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }
}
