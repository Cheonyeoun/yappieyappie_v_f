import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yappieyappie/services/auth_service.dart';

class OnboardingDialog extends ConsumerStatefulWidget {
  const OnboardingDialog({super.key});

  @override
  ConsumerState<OnboardingDialog> createState() => _OnboardingDialogState();
}

class _OnboardingDialogState extends ConsumerState<OnboardingDialog> {
  final PageController _pageController = PageController();
  final _usernameController = TextEditingController();

  bool _isAvailable = false;
  bool _isChecking = false;
  String? _usernameError;
  Timer? _debounce;

  // Real-time check logic
  void _onUsernameChanged(String val) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (val.isEmpty) {
      setState(() {
        _isChecking = false;
        _isAvailable = false;
        _usernameError = null;
      });
      return;
    }

    setState(() => _isChecking = true);

    _debounce = Timer(const Duration(milliseconds: 600), () async {
      final available =
          await ref.read(authServiceProvider).isUsernameAvailable(val);
      if (mounted) {
        setState(() {
          _isAvailable = available;
          _isChecking = false;
          _usernameError = available ? null : "Username already taken! ❌";
        });
      }
    });
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 450),
        padding: const EdgeInsets.all(24),
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(), // Force buttons only
          children: [
            // --- SLIDE 1: USERNAME ---
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Identity",
                        style: TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: _nextPage, // Skips to PFP slide
                      child: const Text("Skip",
                          style: TextStyle(color: Colors.grey)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text("What do we call you?",
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text("Choose a unique @username for the circle.",
                    style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 30),
                TextField(
                  controller: _usernameController,
                  onChanged: _onUsernameChanged,
                  decoration: InputDecoration(
                    hintText: "username",
                    prefixText: "@ ",
                    errorText: _usernameError,
                    suffixIcon: _isChecking
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : (_isAvailable
                            ? const Icon(Icons.check_circle,
                                color: Colors.green)
                            : null),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _isAvailable ? _nextPage : null,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 55),
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text("Next Step",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),

            // --- SLIDE 2: PROFILE PICTURE ---
            Column(
              children: [
                const SizedBox(height: 20),
                const Text("Looking good!",
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const Text("Add a photo so your friends recognize you.",
                    style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 40),
                Stack(
                  children: [
                    const CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.blueAccent,
                      child: Icon(Icons.person, size: 60, color: Colors.white),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        backgroundColor: theme.cardColor,
                        radius: 18,
                        child: const Icon(Icons.add_a_photo_rounded,
                            size: 18, color: Colors.blueAccent),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () async {
                    final uid = FirebaseAuth.instance.currentUser!.uid;
                    // Finalize the profile (Updates username or auto-generates if skipped)
                    await ref.read(authServiceProvider).finalizeUsername(
                          uid: uid,
                          chosenUsername: _usernameController.text,
                        );
                    if (mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 55),
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text("Enter the Circle ☠️",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Maybe later",
                      style: TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
