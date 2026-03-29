import 'package:flutter/material.dart';

class ChatTheme {
  final Color background;

  final Color myBubble;
  final Color otherBubble;

  final Color myText;
  final Color otherText;

  final Color inputBackground;
  final Color inputText;

  const ChatTheme({
    required this.background,
    required this.myBubble,
    required this.otherBubble,
    required this.myText,
    required this.otherText,
    required this.inputBackground,
    required this.inputText,
  });
}

class ChatThemes {
  static const ChatTheme yappieDark = ChatTheme(
    background: Color(0xFF000000),
    myBubble: Colors.blueAccent,
    otherBubble: Color(0xFF424242),
    myText: Colors.white,
    otherText: Colors.white,
    inputBackground: Color(0xFF1F1F1F),
    inputText: Colors.white,
  );
}
