import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:yappieyappie/models/profile/user_model.dart';
import 'package:yappieyappie/services/providers/chat/chat_provider.dart';
import 'package:yappieyappie/services/providers/chat/chat_selection_provider.dart';

import 'package:yappieyappie/features/chat/presentation/widgets/private_chats/chat_app_bar.dart';
import 'package:yappieyappie/features/chat/presentation/widgets/private_chats/chat_messages_list.dart';
import 'package:yappieyappie/features/chat/presentation/widgets/private_chats/chat_input.dart';
import 'package:yappieyappie/core/theme/chat/chat_theme.dart';

class PrivateChatScreen extends ConsumerStatefulWidget {
  final UserModel otherUser;
  const PrivateChatScreen({super.key, required this.otherUser});

  @override
  ConsumerState<PrivateChatScreen> createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends ConsumerState<PrivateChatScreen>
    with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();

  String get _roomId =>
      ref.read(chatServiceProvider).getChatRoomId(widget.otherUser.uid);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Mark as read immediately when entering the chat.
    ref.read(chatServiceProvider).markAsRead(_roomId);

    // Sync active chat presence to Firestore to suppress notifications
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      FirebaseFirestore.instance.collection('users').doc(uid).update({'currentChatId': _roomId});
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      FirebaseFirestore.instance.collection('users').doc(uid).update({'currentChatId': _roomId});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // If user resumes while still in this chat, clear unread right away.
      ref.read(chatServiceProvider).markAsRead(_roomId);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    
    // Clear active chat presence
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      FirebaseFirestore.instance.collection('users').doc(uid).update({'currentChatId': null});
    }

    super.dispose();
  }

  void _handleSendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    ref
        .read(chatServiceProvider)
        .sendMessage(widget.otherUser.uid, _messageController.text);

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ChatThemes.yappieDark;

    return WillPopScope(
      onWillPop: () async {
        final isSelectionMode = ref.read(isSelectionModeProvider);

        if (isSelectionMode) {
          ref.read(isSelectionModeProvider.notifier).setValue(false);
          ref.read(selectedMessagesProvider.notifier).clear();
          return false;
        }

        return true;
      },
      child: Scaffold(
        backgroundColor: theme.background,
        appBar: ChatAppBar(otherUser: widget.otherUser),
        body: Column(
          children: [
            Expanded(
              child:
                  ChatMessagesList(otherUser: widget.otherUser, theme: theme),
            ),
            ChatInput(
              controller: _messageController,
              onSend: _handleSendMessage,
            ),
          ],
        ),
      ),
    );
  }
}
