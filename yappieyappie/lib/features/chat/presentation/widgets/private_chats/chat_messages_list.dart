import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yappieyappie/models/profile/user_model.dart';
import 'package:yappieyappie/services/providers/chat/chat_provider.dart';
import 'package:yappieyappie/models/chat/message_model.dart';
import 'chat_bubble.dart';
import 'package:yappieyappie/core/theme/chat/chat_theme.dart';

class ChatMessagesList extends ConsumerWidget {
  final UserModel otherUser;
  final ChatTheme theme;
  const ChatMessagesList(
      {super.key, required this.otherUser, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final screenWidth = MediaQuery.of(context).size.width;

    final roomId = ref.watch(chatServiceProvider).getChatRoomId(otherUser.uid);
    final messagesAsync = ref.watch(chatMessagesProvider(roomId));

    return messagesAsync.when(
      data: (snapshot) => ListView.builder(
        reverse: true,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        itemCount: snapshot.docs.length,
        itemBuilder: (context, index) {
          final doc = snapshot.docs[index];

          final msg = MessageModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );

          final isMe = msg.senderId == currentUid;

          return ChatBubble(
            msg: msg,
            isMe: isMe,
            screenWidth: screenWidth,
            otherUser: otherUser,
            theme: theme,
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, __) => Center(child: Text("Error: $err")),
    );
  }
}
