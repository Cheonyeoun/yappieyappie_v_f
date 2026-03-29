import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yappieyappie/models/profile/user_model.dart';
import 'package:yappieyappie/services/providers/chat/chat_provider.dart';

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

class _PrivateChatScreenState extends ConsumerState<PrivateChatScreen> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Mark as read immediately when entering the chat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final roomId =
          ref.read(chatServiceProvider).getChatRoomId(widget.otherUser.uid);
      ref.read(chatServiceProvider).markAsRead(roomId);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
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
    return Scaffold(
      backgroundColor: theme.background,
      appBar: ChatAppBar(otherUser: widget.otherUser),
      body: Column(
        children: [
          Expanded(
            child: ChatMessagesList(otherUser: widget.otherUser, theme: theme),
          ),
          ChatInput(
            controller: _messageController,
            onSend: _handleSendMessage,
          ),
        ],
      ),
    );
  }
}
