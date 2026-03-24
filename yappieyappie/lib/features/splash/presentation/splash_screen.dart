import 'dart:math';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Production-grade meme list
  final List<String> _memes = [
    'https://media.tenor.com/N5XLu7zrh8kAAAAM/cat-catfish.gif', // Pop Cat
    'https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExNHJueGZ3bmZ3bmZ3/3o72F8t9TDi2xVnxOE/giphy.gif', // Example 2
    'https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExNHJueGZ3bmZ3bmZ3/26gsjCZpPolPr3sBy/giphy.gif', // Example 3
  ];

  late String _selectedMeme;

  @override
  void initState() {
    super.initState();
    // Pick a random meme on every boot
    _selectedMeme = _memes[Random().nextInt(_memes.length)];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipOval(
              child: Image.network(
                _selectedMeme,
                width: 160,
                height: 160,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              "Yapping in progress...",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
