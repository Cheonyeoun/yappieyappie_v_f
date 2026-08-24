import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Set<String> _seenWriteInFlight = <String>{};

  // Generates a unique ID shared by both users (e.g., "userA_userB")
  String getChatRoomId(String otherUid) {
    final currentUid = _auth.currentUser?.uid ?? '';
    final ids = [currentUid, otherUid]..sort();
    return ids.join('_');
  }

  // Provides a real-time stream of messages for a specific room
  Stream<QuerySnapshot> getMessages(String chatRoomId) {
    return _db
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Reset unread count for the current user only
  Future<void> markAsRead(String chatRoomId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final chatRef = _db.collection('chats').doc(chatRoomId);

      // Attempt update first (for existing documents)
      try {
        await chatRef.update({
          'unreadCounts.$uid': 0,
        });
      } catch (e) {
        // If document doesn't exist, create it with proper structure
        debugPrint('Document may not exist, attempting to create: $e');
        await chatRef.set(
          {
            'unreadCounts': {uid: 0}
          },
          SetOptions(merge: true),
        );
      }
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
  }

  // Sends message and updates chat metadata for the list screen
  Future<void> sendMessage(String otherUid, String text) async {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null || text.trim().isEmpty) return;

    final chatRoomId = getChatRoomId(otherUid);
    final chatRef = _db.collection('chats').doc(chatRoomId);

    // 1. Save the actual message
    final msgRef = await chatRef.collection('messages').add({
      'text': text.trim(),
      'senderId': currentUid,
      'receiverId': otherUid, // Added for notification purposes
      'timestamp': FieldValue.serverTimestamp(),

      // default values
      'deletedFor': [],
      'isDeletedForEveryone': false,
      'seenBy': [],
    });

    // 2. Update chat metadata
    await chatRef.set({
      'lastMessage': text.trim(),
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastSenderId': currentUid,
      'participants': [currentUid, otherUid],
    }, SetOptions(merge: true));

    // Increment the OTHER user's unread count using dot notation
    await chatRef.update({
      'unreadCounts.$otherUid': FieldValue.increment(1),
      'unreadCounts.$currentUid': 0,
    });

    // 3. Trigger OneSignal Direct Push
    await _sendNotificationPing(otherUid, chatRoomId, currentUid, chatRef);
  }

  Future<void> _sendNotificationPing(String receiverId, String chatId, String senderId, DocumentReference chatRef) async {
    try {
      // 1. Get Receiver's OneSignal Player ID
      final receiverDoc = await _db.collection('users').doc(receiverId).get();
      if (!receiverDoc.exists) return;
      
      final receiverData = receiverDoc.data();
      final oneSignalPlayerId = receiverData?['oneSignalPlayerId'];
      if (oneSignalPlayerId == null) return;

      // 2. Get Sender's Info (Name & Avatar)
      final senderDoc = await _db.collection('users').doc(senderId).get();
      final senderData = senderDoc.data();
      final senderName = senderData?['name'] ?? 'Someone';
      final senderAvatar = senderData?['profileimg'];

      // 3. Get Receiver's new unread count from the server (bypassing local cache for accuracy)
      final chatDoc = await chatRef.get(const GetOptions(source: Source.server));
      int unreadCount = 0;
      if (chatDoc.exists) {
        final chatData = chatDoc.data() as Map<String, dynamic>?;
        if (chatData != null && chatData['unreadCounts'] != null) {
          unreadCount = chatData['unreadCounts'][receiverId] ?? 0;
        }
      }
      
      // Calculate abstract text based on unread count
      String abstractMessage;
      if (unreadCount <= 1) {
        abstractMessage = 'Sent you a new message';
      } else if (unreadCount > 8) {
        abstractMessage = '8+ new messages';
      } else {
        abstractMessage = '$unreadCount new messages';
      }

      // 4. Fire Direct HTTP request to OneSignal
      final appId = dotenv.env['ONESIGNAL_APP_ID'];
      final restApiKey = dotenv.env['ONESIGNAL_REST_API_KEY'];
      
      if (appId == null || restApiKey == null) {
        debugPrint("Error: Missing OneSignal keys in .env");
        return;
      }

      final url = Uri.parse('https://onesignal.com/api/v1/notifications');
      final body = <String, dynamic>{
        'app_id': appId,
        'include_player_ids': [oneSignalPlayerId],
        'headings': {'en': senderName},
        'contents': {'en': abstractMessage},
        'data': {'chatId': chatId, 'senderId': senderId}, // Used by local suppression & deep linking
        'collapse_id': chatId, // Group and replace notifications PER PERSON, not globally
        'android_accent_color': 'FF7289DA', // A nice aesthetic brand color tint
      };

      if (senderAvatar != null && senderAvatar.isNotEmpty) {
        body['large_icon'] = senderAvatar; // Displays the sender's face!
      }

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Basic $restApiKey',
        },
        body: jsonEncode(body),
      );
      debugPrint('OneSignal Direct Ping Response: ${response.statusCode} - ${response.body}');
    } catch (e) {
      debugPrint('Error triggering OneSignal direct ping: $e');
    }
  }

  // Delete for current user only
  Future<void> deleteForMe(String chatRoomId, String messageId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final ref = _db
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .doc(messageId);

    await ref.update({
      'deletedFor': FieldValue.arrayUnion([uid]),
    });
  }

  // Unsend (delete for everyone)
  Future<void> deleteForEveryone(String chatRoomId, String messageId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final ref = _db
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .doc(messageId);

    final doc = await ref.get();
    if (!doc.exists) return;

    final data = doc.data() as Map<String, dynamic>;

    if (data['senderId'] != uid) return;

    await ref.update({
      'isDeletedForEveryone': true,
    });
  }

  // Mark message as seen
  Future<void> markAsSeen(String chatRoomId, String messageId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final seenKey = '$chatRoomId:$messageId:$uid';
    if (_seenWriteInFlight.contains(seenKey)) return;
    _seenWriteInFlight.add(seenKey);

    try {
      final messageRef = _db
          .collection('chats')
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageId);
      final chatRef = _db.collection('chats').doc(chatRoomId);

      final batch = _db.batch();
      batch.update(messageRef, {
        'seenBy': FieldValue.arrayUnion([uid]),
      });
      batch.update(chatRef, {
        'unreadCounts.$uid': 0,
      });
      await batch.commit();
    } finally {
      _seenWriteInFlight.remove(seenKey);
    }
  }
}
