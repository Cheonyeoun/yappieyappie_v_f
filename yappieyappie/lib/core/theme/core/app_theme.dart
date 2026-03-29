import 'package:flutter/material.dart';

class AppTheme {
  static final darkTheme = ThemeData.dark().copyWith(
    primaryColor: Colors.blueAccent,
    scaffoldBackgroundColor: const Color(0xFF0A0A0A),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0A0A0A),
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[900],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
  );
}
