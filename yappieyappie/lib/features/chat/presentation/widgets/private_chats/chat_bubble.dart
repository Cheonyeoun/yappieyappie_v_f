import 'package:flutter/material.dart';
import 'package:yappieyappie/core/theme/chat/chat_theme.dart';
import 'package:yappieyappie/models/profile/user_model.dart';
import 'package:yappieyappie/models/chat/message_model.dart';

class ChatBubble extends StatelessWidget {
  final MessageModel msg;
  final bool isMe;
  final double screenWidth;
  final UserModel otherUser;
  final ChatTheme theme;

  const ChatBubble({
    super.key,
    required this.msg,
    required this.isMe,
    required this.screenWidth,
    required this.otherUser,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    const round = Radius.circular(14);
    const tail = Radius.circular(2);
    final time = msg.timestamp != null
        ? TimeOfDay.fromDateTime(msg.timestamp!).format(context)
        : '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 💬 MESSAGE BUBBLE
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: screenWidth * 0.745),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? theme.myBubble : theme.otherBubble,
                borderRadius: BorderRadius.only(
                  topLeft: isMe ? round : tail,
                  topRight: isMe ? tail : round,
                  bottomLeft: isMe ? round : round,
                  bottomRight: isMe ? round : round,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // 📝 MESSAGE TEXT
                  Text(
                    msg.text ?? '',
                    style: TextStyle(
                      color: isMe ? theme.myText : theme.otherText,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // ⏱ TIME
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 11,
                      color: (isMe ? theme.myText : theme.otherText)
                          .withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
