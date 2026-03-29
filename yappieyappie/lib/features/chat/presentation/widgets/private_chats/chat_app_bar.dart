import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yappieyappie/features/profile/presentation/profile_screen.dart';
import 'package:yappieyappie/models/profile/user_model.dart';
import 'package:yappieyappie/services/providers/profile/user_provider.dart';
import 'package:yappieyappie/services/providers/chat/chat_selection_provider.dart';
import 'package:yappieyappie/services/providers/chat/chat_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final UserModel otherUser;
  const ChatAppBar({super.key, required this.otherUser});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userStreamProvider(otherUser.uid));
    final isSelectionMode = ref.watch(isSelectionModeProvider);
    final selectedMessages = ref.watch(selectedMessagesProvider);
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    final roomId = ref.read(chatServiceProvider).getChatRoomId(otherUser.uid);
    final messagesAsync = ref.watch(chatMessagesProvider(roomId));

    return AppBar(
      backgroundColor: Colors.black,
      elevation: 0.5,
      leading: isSelectionMode
          ? IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                ref.read(isSelectionModeProvider.notifier).state = false;
                ref.read(selectedMessagesProvider.notifier).state = {};
              },
            )
          : null,
      title: isSelectionMode
          ? Text(
              "${selectedMessages.length} selected",
              style: const TextStyle(color: Colors.white),
            )
          : InkWell(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ProfileScreen(user: otherUser)));
              },
              child: userAsync.when(
                data: (user) => Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundImage: user.profileimg?.isNotEmpty == true
                          ? NetworkImage(user.profileimg!)
                          : null,
                      child: user.profileimg?.isEmpty ?? true
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name.isNotEmpty ? user.name : 'User',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (user.showOnlineStatus)
                          Text(
                            user.isOnline ? "Active now" : "Offline",
                            style: TextStyle(
                              fontSize: 11,
                              color: user.isOnline
                                  ? Colors.greenAccent
                                  : Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                loading: () => const Text("Loading...",
                    style: TextStyle(color: Colors.white)),
                error: (_, __) =>
                    const Text("User", style: TextStyle(color: Colors.white)),
              ),
            ),
      actions: isSelectionMode
          ? [
              messagesAsync.when(
                data: (snapshot) {
                  bool canUnsend = true;

                  for (final doc in snapshot.docs) {
                    if (!selectedMessages.contains(doc.id)) continue;

                    final data = doc.data() as Map<String, dynamic>;

                    if (data['senderId'] != currentUid) {
                      canUnsend = false;
                      break;
                    }
                  }

                  return PopupMenuButton<String>(
                    onSelected: (value) async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("Confirm"),
                          content: Text(
                            value == 'delete'
                                ? "Delete selected messages?"
                                : "Unsend selected messages?",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text("OK"),
                            ),
                          ],
                        ),
                      );

                      if (confirm != true) return;

                      final chatService = ref.read(chatServiceProvider);

                      for (final id in selectedMessages) {
                        if (value == 'delete') {
                          await chatService.deleteForMe(roomId, id);
                        }

                        if (value == 'unsend') {
                          await chatService.deleteForEveryone(roomId, id);
                        }
                      }

                      ref.read(isSelectionModeProvider.notifier).state = false;
                      ref.read(selectedMessagesProvider.notifier).state = {};
                    },
                    itemBuilder: (context) {
                      final items = [
                        const PopupMenuItem(
                            value: 'delete', child: Text('Delete')),
                      ];

                      if (canUnsend) {
                        items.add(const PopupMenuItem(
                            value: 'unsend', child: Text('Unsend')));
                      }

                      return items;
                    },
                  );
                },
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              ),
            ]
          : [],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
