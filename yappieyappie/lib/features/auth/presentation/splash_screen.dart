import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final List<String> _memes = [
    'https://media.tenor.com/N5XLu7zrh8kAAAAM/cat-catfish.gif',
    'https://media.giphy.com/media/3o72F8t9TDi2xVnxOE/giphy.gif',
    'https://media.giphy.com/media/26gsjCZpPolPr3sBy/giphy.gif',
  ];

  late String _selectedMeme;

  @override
  void initState() {
    super.initState();
    _selectedMeme = _memes[Random().nextInt(_memes.length)];

    _startApp();
  }

  Future<void> _startApp() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // 🔥 FIX: safe navigation after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.go('/auth');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
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
                errorBuilder: (c, e, s) =>
                    const Icon(Icons.bolt, color: Colors.blue),
              ),
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(color: Colors.blueAccent),
          ],
        ),
      ),
    );
  }
}
