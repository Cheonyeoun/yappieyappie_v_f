import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yappieyappie/models/user_model.dart';
import 'package:yappieyappie/services/profile/user_provider.dart';

class PrivateChatScreen extends ConsumerStatefulWidget {
  final UserModel otherUser;

  const PrivateChatScreen({super.key, required this.otherUser});

  @override
  ConsumerState<PrivateChatScreen> createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends ConsumerState<PrivateChatScreen> {
  final TextEditingController _messageController = TextEditingController();

  // Generates a unique chat room ID based on both users' IDs
  // Sorting ensures same ID for both users (A_B == B_A)
  String get chatRoomId {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final ids = [currentUid, widget.otherUser.uid]..sort();
    return ids.join('_');
  }

  @override
  void initState() {
    super.initState();

    // Ensures unread messages are cleared AFTER UI loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markMessagesAsRead();
    });
  }

  // Reset unread count when this chat is opened
  Future<void> _markMessagesAsRead() async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return;

    await FirebaseFirestore.instance.collection('chats').doc(chatRoomId).set({
      'unreadCounts': {
        currentUid: 0,
      }
    }, SetOptions(merge: true));
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();

    // Prevent sending empty messages
    if (text.isEmpty) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final chatRef =
        FirebaseFirestore.instance.collection('chats').doc(chatRoomId);

    // Add message to subcollection
    await chatRef.collection('messages').add({
      'text': text,
      'senderId': currentUser.uid,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Update chat metadata for list screen
    await chatRef.set({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastSenderId': currentUser.uid,

      // Ensure both users are part of the chat
      'participants': [currentUser.uid, widget.otherUser.uid],

      // Keeps unread count separately for each user
      'unreadCounts': {
        currentUser.uid: 0,
        widget.otherUser.uid: FieldValue.increment(1),
      },
    }, SetOptions(merge: true));

    // Clear input field after sending
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    // Listen to real-time user data
    final userAsync = ref.watch(userStreamProvider(widget.otherUser.uid));

    return Scaffold(
      appBar: AppBar(
        title: userAsync.when(
          data: (user) => Row(
            children: [
              // User profile image
              CircleAvatar(
                radius: 20,
                backgroundImage:
                    user.profileimg != null && user.profileimg!.isNotEmpty
                        ? NetworkImage(user.profileimg!)
                        : null,
                child: (user.profileimg == null || user.profileimg!.isEmpty)
                    ? const Icon(Icons.person)
                    : null,
              ),
              const SizedBox(width: 12),

              // User name + online status
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name.isNotEmpty ? user.name : 'User'),

                  // NOTE: Controlled by user preference (showOnlineStatus)
                  Text(
                    user.showOnlineStatus
                        ? (user.isOnline ? "Online" : "Offline")
                        : "",
                    style: TextStyle(
                      fontSize: 12,
                      color: user.isOnline ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          loading: () => const Text("Loading..."),
          error: (_, __) => const Text("User"),
        ),
      ),
      body: Column(
        children: [
          // Messages list (latest at bottom visually)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatRoomId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                // Show loading state
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                // If no messages yet
                if (messages.isEmpty) {
                  return const Center(child: Text("No messages yet"));
                }

                return ListView.builder(
                  reverse: true, // Ensures newest messages appear at bottom
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index].data() as Map<String, dynamic>;

                    // Check if message is sent by current user
                    final isMe = msg['senderId'] == currentUid;

                    // Format timestamp safely
                    final timestamp = msg['timestamp'];
                    final time = timestamp != null
                        ? DateFormat('hh:mm a')
                            .format((timestamp as Timestamp).toDate())
                        : '';

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              isMe ? Colors.blueAccent : Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Message text
                            Text(msg['text'] ?? ''),

                            const SizedBox(height: 4),

                            // Message time
                            Text(
                              time,
                              style: const TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Message input field
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Type a message",
                      filled: true,
                      fillColor: Colors.grey[900],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                    ),

                    // Send message when user presses enter
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),

                // Send button
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
