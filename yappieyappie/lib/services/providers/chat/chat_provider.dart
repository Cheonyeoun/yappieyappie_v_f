import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yappieyappie/services/chat/chat_service.dart';

final chatServiceProvider = Provider((ref) => ChatService());

// A "family" provider that takes the chatRoomId and returns a stream of messages
final chatMessagesProvider =
    StreamProvider.family<QuerySnapshot, String>((ref, chatRoomId) {
  return ref.watch(chatServiceProvider).getMessages(chatRoomId);
});
