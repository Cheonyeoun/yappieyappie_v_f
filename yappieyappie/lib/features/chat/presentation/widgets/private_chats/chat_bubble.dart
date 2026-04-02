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
  final bool isLastMyMessage;
  final bool isSelectionMode;
  final bool isSelected;

  const ChatBubble({
    super.key,
    required this.msg,
    required this.isMe,
    required this.screenWidth,
    required this.otherUser,
    required this.theme,
    required this.isLastMyMessage,
    required this.isSelectionMode,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    const round = Radius.circular(14);
    const tail = Radius.circular(2);
    final time = msg.timestamp != null
        ? TimeOfDay.fromDateTime(msg.timestamp!).format(context)
        : '';

    // Determine seen status
    final otherUid = otherUser.uid; // the other person's UID
    final isSeen = isMe && msg.seenBy.contains(otherUid);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isSelectionMode && !isMe)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    isSelected ? Icons.close : Icons.check_box_outline_blank,
                    size: 20,
                    color: isSelected ? Colors.white : Colors.grey,
                  ),
                ),

              // 💬 MESSAGE BUBBLE
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: screenWidth * 0.745),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                        msg.text,
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
              if (isSelectionMode && isMe)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Icon(
                    isSelected ? Icons.close : Icons.check_box_outline_blank,
                    size: 20,
                    color: isSelected ? Colors.white : Colors.grey,
                  ),
                ),
            ],
          ),

          // Show only for latest message sent by current user
          if (isMe && isLastMyMessage)
            Padding(
              padding: const EdgeInsets.only(top: 2, right: 4),
              child: Text(
                isSeen ? "Seen" : "Sent",
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
