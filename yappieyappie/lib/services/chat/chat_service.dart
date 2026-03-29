import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

    await _db.collection('chats').doc(chatRoomId).update({
      'unreadCounts.$uid': 0,
    });
  }

  // Sends message and updates chat metadata for the list screen
  Future<void> sendMessage(String otherUid, String text) async {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null || text.trim().isEmpty) return;

    final chatRoomId = getChatRoomId(otherUid);
    final chatRef = _db.collection('chats').doc(chatRoomId);

    // 1. Save the actual message
    await chatRef.collection('messages').add({
      'text': text.trim(),
      'senderId': currentUid,
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

    final ref = _db
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .doc(messageId);

    await ref.update({
      'seenBy': FieldValue.arrayUnion([uid]),
    });
  }
}
