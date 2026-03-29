import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String text;
  final String senderId;
  final DateTime? timestamp;

  MessageModel({
    required this.id,
    required this.text,
    required this.senderId,
    this.timestamp,
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
    };
  }
}
