import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yappieyappie/features/profile/presentation/profile_screen.dart';
import 'package:yappieyappie/features/home/presentation/widgets/bottom_nav_bar.dart';
import 'package:yappieyappie/models/user_model.dart';
import 'package:yappieyappie/services/profile/user_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // 🔥 SAFETY: prevent null crash
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("User not logged in")),
      );
    }

    final screens = [
      // 🔹 Yapp Tab (your current Firestore UI)
      StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Waiting for user data..."));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final username = data['username'] ?? 'unknown';
          final email = data['email'] ?? 'no-email';
          final isOnline = data['isOnline'] ?? false;
          final showOnline = data['showOnlineStatus'] ?? false;

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("USER IDENTITY",
                    style: TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text("Username: @$username",
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                Text("Email: $email"),
                const SizedBox(height: 30),
                const Text("GHOST LOG DATA ☠️",
                    style: TextStyle(
                        color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _statusTile("Is Online", isOnline.toString(), Icons.circle,
                    isOnline ? Colors.green : Colors.grey),
                _statusTile(
                  "Visibility Toggle",
                  showOnline ? "Visible" : "Hidden",
                  Icons.visibility,
                  Colors.blue,
                ),
                const Spacer(),
                const Center(
                  child: Text("M2 Milestone: Auth & Sync Complete ✅",
                      style: TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          );
        },
      ),

      // 🔹 Search Tab
      const Center(
        child: Text(
          "Search Tab\n(Coming Soon)",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 4),
        ),
      ),

      // 🔹 Profile Tab (updated to use real UserModel)
      FutureBuilder<UserModel>(
        future: UserService().getUser(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text("Failed to load profile"));
          }

          final userModel = snapshot.data!;
          return ProfileScreen(user: userModel);
        },
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("YappieYappie"),
      ),
      body: screens[currentIndex],
      bottomNavigationBar: BottomNavBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
      ),
    );
  }

  Widget _statusTile(String title, String value, IconData icon, Color color) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color, size: 20),
      title: Text(title),
      trailing:
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
