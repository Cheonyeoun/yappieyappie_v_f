import 'package:flutter/material.dart';

class ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const ChatInput({
    super.key,
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Type a message",
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[900],
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.blueAccent),
            onPressed: onSend,
          ),
        ],
      ),
    );
  }
}
