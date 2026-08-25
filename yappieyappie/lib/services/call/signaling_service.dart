import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class ISignalingService {
  String generateToken({
    required String roomName,
    required String participantName,
    required String participantIdentity,
  });

  Future<void> sendCallSignal({
    required String receiverId,
    required String callerId,
    required String callerName,
    required String callerAvatar,
    required String roomName,
    required String callId,
  });

  Future<void> sendCallCancelledSignal({
    required String receiverId,
    required String callerId,
    required String roomName,
  });
}

class SignalingService implements ISignalingService {
  static final SignalingService instance = SignalingService._internal();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  SignalingService._internal();

  @override
  String generateToken({
    required String roomName,
    required String participantName,
    required String participantIdentity,
  }) {
    final apiKey = dotenv.env['LIVEKIT_API_KEY'];
    final apiSecret = dotenv.env['LIVEKIT_API_SECRET'];

    if (apiKey == null || apiSecret == null) {
      throw Exception('LiveKit API credentials missing in .env');
    }

    final jwt = JWT(
      {
        'sub': participantIdentity,
        'name': participantName,
        'video': {
          'room': roomName,
          'roomJoin': true,
        },
      },
      issuer: apiKey,
    );

    return jwt.sign(
      SecretKey(apiSecret),
      expiresIn: const Duration(hours: 2),
      algorithm: JWTAlgorithm.HS256,
    );
  }

  Future<String?> _getReceiverFcmToken(String receiverId) async {
    final doc = await _db.collection('users').doc(receiverId).get();
    if (!doc.exists) return null;
    return doc.data()?['fcmToken'];
  }

  Future<AuthClient?> _getFcmAuthClient() async {
    final serviceAccountRaw = dotenv.env['FIREBASE_SERVICE_ACCOUNT_JSON'];
    if (serviceAccountRaw == null) {
      debugPrint("Error: FIREBASE_SERVICE_ACCOUNT_JSON missing in .env");
      return null;
    }

    final serviceAccount = jsonDecode(serviceAccountRaw);
    final credentials = ServiceAccountCredentials.fromJson(serviceAccount);
    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
    
    return await clientViaServiceAccount(credentials, scopes);
  }

  @override
  Future<void> sendCallSignal({
    required String receiverId,
    required String callerId,
    required String callerName,
    required String callerAvatar,
    required String roomName,
    required String callId,
  }) async {
    try {
      final receiverToken = await _getReceiverFcmToken(receiverId);
      if (receiverToken == null) {
        debugPrint("SignalingService: Receiver has no FCM token.");
        return;
      }

      final authClient = await _getFcmAuthClient();
      if (authClient == null) return;

      final serviceAccount = jsonDecode(dotenv.env['FIREBASE_SERVICE_ACCOUNT_JSON']!);
      final projectId = serviceAccount['project_id'];
      final url = Uri.parse('https://fcm.googleapis.com/v1/projects/$projectId/messages:send');

      final body = {
        "message": {
          "token": receiverToken,
          "data": {
            "type": "call",
            "callerId": callerId,
            "callerName": callerName,
            "callerAvatar": callerAvatar,
            "roomName": roomName,
            "callId": callId,
          },
          "android": {
            "priority": "high",
            "ttl": "0s"
          },
          "apns": {
            "headers": {
              "apns-priority": "10"
            }
          }
        }
      };

      final response = await authClient.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      debugPrint("SignalingService: FCM Call Signal Response: ${response.statusCode}");
      authClient.close();
      
    } catch (e) {
      debugPrint("SignalingService: Error sending call signal: $e");
    }
  }

  @override
  Future<void> sendCallCancelledSignal({
    required String receiverId,
    required String callerId,
    required String roomName,
  }) async {
    try {
      final receiverToken = await _getReceiverFcmToken(receiverId);
      if (receiverToken == null) return;

      final authClient = await _getFcmAuthClient();
      if (authClient == null) return;

      final serviceAccount = jsonDecode(dotenv.env['FIREBASE_SERVICE_ACCOUNT_JSON']!);
      final projectId = serviceAccount['project_id'];
      final url = Uri.parse('https://fcm.googleapis.com/v1/projects/$projectId/messages:send');

      final body = {
        "message": {
          "token": receiverToken,
          "data": {
            "type": "call_cancelled",
            "callerId": callerId,
            "roomName": roomName,
          },
          "android": {
            "priority": "high",
            "ttl": "0s"
          },
          "apns": {
            "headers": {
              "apns-priority": "10"
            }
          }
        }
      };

      await authClient.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      authClient.close();
      debugPrint("SignalingService: FCM Call Cancelled Signal Sent to $receiverId");
    } catch (e) {
      debugPrint("SignalingService: Error sending call cancelled signal: $e");
    }
  }
}
