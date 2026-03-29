import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yappieyappie/services/providers/splash/splash_provider.dart';

/// Splash screen responsible for:
/// 1. Marking user as online in Firestore
/// 2. Holding UI for a short duration
/// 3. Signaling app navigation to proceed
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  late final String _selectedMeme;

  @override
  void initState() {
    super.initState();

    // Select a random meme once to avoid UI flicker on rebuilds
    final List<String> memes = [
      'https://media.tenor.com/N5XLu7zrh8kAAAAM/cat-catfish.gif',
      'https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExNHJueGZ3bmZ3bmZ3/3o72F8t9TDi2xVnxOE/giphy.gif',
      'https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExNHJueGZ3bmZ3bmZ3/26gsjCZpPolPr3sBy/giphy.gif',
    ];

    _selectedMeme = memes[Random().nextInt(memes.length)];

    // Run initialization logic
    _initializeSplash();
  }

  /// Handles all one-time startup logic
  Future<void> _initializeSplash() async {
    await _setupIsOnline();

    // Ensure splash is visible for a minimum duration
    Timer(const Duration(milliseconds: 1500), () {
      ref.read(splashScreenProvider.notifier).markSplashFinished();
    });
  }

  /// Updates user presence in Firestore
  /// Sets:
  /// - isOnline = true
  /// - lastActive = current server timestamp
  Future<void> _setupIsOnline() async {
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;

    // If no authenticated user exists, skip presence update
    if (user == null) return;

    final doc = FirebaseFirestore.instance.collection('users').doc(user.uid);

    await doc.set(
      {
        'isOnline': true,
        'lastActive': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true), // Prevent overwriting existing user data
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watching provider ensures rebuild when splash state changes
    final showSplash = ref.watch(splashScreenProvider);

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
                loadingBuilder: (context, child, loadingProgress) {
                  // Show loader while image is being fetched
                  if (loadingProgress == null) return child;
                  return const SizedBox(
                    width: 160,
                    height: 160,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                },
              ),
            ),
            const SizedBox(height: 30),
            Text(
              "YappieYappie Circle",
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall!
                  .copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              "Yapping in progress...",
              style: TextStyle(
                color: Colors.grey[400],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
