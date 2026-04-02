import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String username;
  final String email;
  final String? profileimg;
  final String? bio;
  final DateTime? createdAt;
  final DateTime? lastActive;
  final bool isOnline;
  final bool showOnlineStatus;

  UserModel({
    required this.uid,
    required this.name,
    this.username = '',
    required this.email,
    this.bio,
    this.createdAt,
    this.lastActive,
    this.isOnline = false,
    this.showOnlineStatus = true,
    this.profileimg,
  });

  // Convert to Firestore Map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'username': username,
      'email': email,
      'bio': bio,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'lastActive': lastActive ?? FieldValue.serverTimestamp(),
      'isOnline': isOnline,
      'profileimg': profileimg,
      'showOnlineStatus': showOnlineStatus,
    };
  }

  // Convert from Firestore Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      profileimg: map['profileimg'],
      bio: map['bio'],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      lastActive: map['lastActive'] != null
          ? (map['lastActive'] as Timestamp).toDate()
          : null,
      isOnline: map['isOnline'] ?? false,
      showOnlineStatus: map['showOnlineStatus'] ?? true,
    );
  }

  // Helper method for updating specific fields easily
  UserModel copyWith({
    String? username,
    bool? isOnline,
    bool? showOnlineStatus,
    DateTime? lastActive,
  }) {
    return UserModel(
      uid: uid,
      name: name,
      username: username ?? this.username,
      email: email,
      profileimg: profileimg,
      bio: bio,
      createdAt: createdAt,
      lastActive: lastActive ?? this.lastActive,
      isOnline: isOnline ?? this.isOnline,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
    );
  }
}
