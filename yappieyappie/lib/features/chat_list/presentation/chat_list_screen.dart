import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yappieyappie/features/chat/presentation/screens/private_chat_screen.dart';
import 'package:yappieyappie/models/profile/user_model.dart';
import 'package:yappieyappie/services/providers/profile/user_provider.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = FirebaseAuth.instance.currentUser;

    // If user is not logged in, show fallback UI
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("User not logged in")),
      );
    }

    // Query to get chats where current user is a participant
    final chatRoomsRef = FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: currentUser.uid)
        .orderBy('lastMessageTime', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Yapp List"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: chatRoomsRef.snapshots(),
        builder: (context, snapshot) {
          // Show loading indicator while data is being fetched
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final chatRooms = snapshot.data!.docs;

          // If no chats exist
          if (chatRooms.isEmpty) {
            return const Center(child: Text("No conversations yet"));
          }

          return ListView.builder(
            itemCount: chatRooms.length,
            itemBuilder: (_, index) {
              final doc = chatRooms[index];
              final data = doc.data() as Map<String, dynamic>;

              // Get participants list
              final participants =
                  List<String>.from(data['participants'] ?? []);

              // Find the other user's UID (not current user)
              final otherUsers =
                  participants.where((id) => id != currentUser.uid).toList();

              // If no valid other user, skip rendering
              if (otherUsers.isEmpty) {
                return const SizedBox();
              }

              final otherUid = otherUsers.first;

              // Last message details
              final lastMessage = data['lastMessage'] as String? ?? '';
              final lastSenderId = data['lastSenderId'] as String? ?? '';

              // Check if last message was sent by current user
              final isMe = lastSenderId == currentUser.uid;

              // Show "You: ..." if current user sent the last message
              final displayMessage = isMe ? "You: $lastMessage" : lastMessage;

              // Last message time formatting
              final lastMessageTime = data['lastMessageTime'] != null
                  ? (data['lastMessageTime'] as Timestamp).toDate()
                  : null;

              // Unread messages count for current user
              final unreadCounts =
                  data['unreadCounts'] as Map<String, dynamic>? ?? {};
              final unreadCount = unreadCounts[currentUser.uid] ?? 0;

              // Listen to user data using Riverpod provider
              final userAsync = ref.watch(userStreamProvider(otherUid));

              return userAsync.when(
                data: (user) => _ChatListItem(
                  user: user,
                  lastMessage: displayMessage,
                  lastMessageTime: lastMessageTime,
                  unreadCount: unreadCount,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PrivateChatScreen(otherUser: user),
                      ),
                    );
                  },
                ),

                // Lightweight loading state
                loading: () => const ListTile(
                  title: Text("Loading..."),
                ),

                // Basic error fallback
                error: (_, __) => const ListTile(
                  title: Text("Error loading user"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ChatListItem extends StatelessWidget {
  final UserModel user;
  final String lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final VoidCallback onTap;

  const _ChatListItem({
    required this.user,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Format time (HH:mm)
    final formattedTime = lastMessageTime != null
        ? DateFormat('HH:mm').format(lastMessageTime!)
        : '--:--';

    return ListTile(
      // Profile picture
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: user.profileimg != null && user.profileimg!.isNotEmpty
            ? NetworkImage(user.profileimg!)
            : null,
        child: (user.profileimg == null || user.profileimg!.isEmpty)
            ? const Icon(Icons.person)
            : null,
      ),

      // Username (bold if unread)
      title: Text(
        user.name.isNotEmpty ? user.name : 'User',
        style: TextStyle(
          fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
        ),
        overflow: TextOverflow.ellipsis,
      ),

      // Last message preview (bold if unread)
      subtitle: Text(
        lastMessage.isNotEmpty ? lastMessage : "No message yet",
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
        ),
      ),

      // Time + unread badge
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            formattedTime,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 5),

          // Show unread badge only if unreadCount > 0
          if (unreadCount > 0)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),

      onTap: onTap,
    );
  }
}
