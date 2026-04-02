import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yappieyappie/models/profile/user_model.dart';
import 'package:yappieyappie/services/providers/chat/chat_provider.dart';
import 'package:yappieyappie/models/chat/message_model.dart';
import 'chat_bubble.dart';
import 'package:yappieyappie/core/theme/chat/chat_theme.dart';
import 'package:yappieyappie/services/providers/chat/chat_selection_provider.dart';

class ChatMessagesList extends ConsumerWidget {
  final UserModel otherUser;
  final ChatTheme theme;

  const ChatMessagesList(
      {super.key, required this.otherUser, required this.theme});

  // Date label helper (Today / Yesterday / Date)
  String getDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDate = DateTime(date.year, date.month, date.day);

    if (msgDate == today) return "Today";
    if (msgDate == today.subtract(const Duration(days: 1))) {
      return "Yesterday";
    }

    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSelectionMode = ref.watch(isSelectionModeProvider);
    final selectedMessages = ref.watch(selectedMessagesProvider);

    final roomId = ref.watch(chatServiceProvider).getChatRoomId(otherUser.uid);
    final messagesAsync = ref.watch(chatMessagesProvider(roomId));

    return messagesAsync.when(
      data: (snapshot) {
        final docs = snapshot.docs;

        // Find latest message sent by current user
        String? latestMyMessageId;
        for (final doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['senderId'] == currentUid) {
            latestMyMessageId = doc.id;
            break;
          }
        }

        return ListView.builder(
          reverse: true,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];

            final msg = MessageModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );

            // Hide deleted messages (UI-level filtering)
            if (msg.isDeletedForEveryone) return const SizedBox.shrink();
            if (msg.deletedFor.contains(currentUid)) {
              return const SizedBox.shrink();
            }

            final isMe = msg.senderId == currentUid;

            // Mark message as seen when rendered
            if (!isMe && !msg.seenBy.contains(currentUid)) {
              // Use post-frame callback to safely update Firestore after build
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref.read(chatServiceProvider).markAsSeen(roomId, msg.id);
              });
            }

            final isSelected = selectedMessages.contains(msg.id);

            // DATE DIVIDER LOGIC
            bool showDate = false;
            if (index == docs.length - 1) {
              showDate = true;
            } else {
              final prevDoc = docs[index + 1];
              final prevMsg = MessageModel.fromMap(
                prevDoc.data() as Map<String, dynamic>,
                prevDoc.id,
              );

              if (msg.timestamp != null && prevMsg.timestamp != null) {
                final currentDate = DateTime(msg.timestamp!.year,
                    msg.timestamp!.month, msg.timestamp!.day);
                final prevDate = DateTime(prevMsg.timestamp!.year,
                    prevMsg.timestamp!.month, prevMsg.timestamp!.day);

                if (currentDate != prevDate) {
                  showDate = true;
                }
              }
            }

            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Column(
                key: ValueKey(msg.id),
                children: [
                  if (showDate && msg.timestamp != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade800,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            getDateLabel(msg.timestamp!),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ),
                    ),
                  GestureDetector(
                    onLongPress: () {
                      ref.read(isSelectionModeProvider.notifier).setValue(true);
                      ref.read(selectedMessagesProvider.notifier).add(msg.id);
                    },
                    onTap: () {
                      if (!isSelectionMode) return;

                      if (selectedMessages.contains(msg.id)) {
                        ref
                            .read(selectedMessagesProvider.notifier)
                            .remove(msg.id);
                      } else {
                        ref.read(selectedMessagesProvider.notifier).add(msg.id);
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      color: isSelected
                          ? Colors.white.withOpacity(0.05)
                          : Colors.transparent,
                      child: ChatBubble(
                        msg: msg,
                        isMe: isMe,
                        screenWidth: screenWidth,
                        otherUser: otherUser,
                        theme: theme,
                        isLastMyMessage: msg.id == latestMyMessageId,
                        isSelectionMode: isSelectionMode,
                        isSelected: isSelected,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, __) => Center(child: Text("Error: $err")),
    );
  }
}
