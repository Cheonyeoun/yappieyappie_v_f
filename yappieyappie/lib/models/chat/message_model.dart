import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String text;
  final String senderId;
  final DateTime? timestamp;

  // New fields for production features
  final List<String> deletedFor;
  final bool isDeletedForEveryone;
  final List<String> seenBy;

  MessageModel({
    required this.id,
    required this.text,
    required this.senderId,
    this.timestamp,
    this.deletedFor = const [],
    this.isDeletedForEveryone = false,
    this.seenBy = const [],
  });

  // Convert Firestore → Model
  factory MessageModel.fromMap(Map<String, dynamic> map, String docId) {
    return MessageModel(
      id: docId,
      text: map['text'] ?? '',
      senderId: map['senderId'] ?? '',
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] as Timestamp).toDate()
          : null,

      // Safe parsing (prevents crashes if fields are missing)
      deletedFor: List<String>.from(map['deletedFor'] ?? []),
      isDeletedForEveryone: map['isDeletedForEveryone'] ?? false,
      seenBy: List<String>.from(map['seenBy'] ?? []),
    );
  }

  // Convert Model → Firestore (for sending messages)
  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'senderId': senderId,
      'timestamp': timestamp != null
          ? Timestamp.fromDate(timestamp!)
          : FieldValue.serverTimestamp(),

      // Defaults for new messages
      'deletedFor': [],
      'isDeletedForEveryone': false,
      'seenBy': [],
    };
  }
}
