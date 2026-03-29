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

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("User not logged in")),
      );
    }

    final chatRoomsRef = FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: currentUser.uid)
        .orderBy('lastMessageTime', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Yap Circle"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: chatRoomsRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final chatRooms = snapshot.data!.docs;

          if (chatRooms.isEmpty) {
            return const Center(child: Text("No conversations yet"));
          }

          return ListView.builder(
            itemCount: chatRooms.length,
            itemBuilder: (_, index) {
              final data = chatRooms[index].data() as Map<String, dynamic>;

              final participants =
                  List<String>.from(data['participants'] ?? []);

              final otherUid = participants.firstWhere(
                (id) => id != currentUser.uid,
                orElse: () => '',
              );

              if (otherUid.isEmpty) return const SizedBox();

              final lastMessage = data['lastMessage'] ?? '';
              final lastSenderId = data['lastSenderId'] ?? '';

              final isMe = lastSenderId == currentUser.uid;
              final displayMessage = isMe ? "You: $lastMessage" : lastMessage;

              final lastMessageTime =
                  (data['lastMessageTime'] as Timestamp?)?.toDate();

              final unreadCounts =
                  data['unreadCounts'] as Map<String, dynamic>? ?? {};
              final unreadCount = unreadCounts[currentUser.uid] ?? 0;

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
                loading: () => const ListTile(
                  title: Text("Loading..."),
                ),
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
