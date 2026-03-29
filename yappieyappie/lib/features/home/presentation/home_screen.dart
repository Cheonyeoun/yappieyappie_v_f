import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yappieyappie/features/chat_list/presentation/chat_list_screen.dart';
import 'package:yappieyappie/features/profile/presentation/profile_screen.dart';
import 'package:yappieyappie/features/home/presentation/widgets/bottom_nav_bar.dart';
import 'package:yappieyappie/models/profile/user_model.dart';
import 'package:yappieyappie/services/profile/user_service.dart';
import 'package:yappieyappie/features/search/presentation/search_screen.dart';
import 'package:yappieyappie/services/auth/auth_service.dart';

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

    // Prevent rendering when user is not authenticated
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("User not logged in")),
      );
    }

    final screens = [
      // Chat List Tab
      const ChatListScreen(),
      // Search tab
      const SearchScreen(),

      // Profile tab
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
        title: const Text("YappieYappie Circle"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => ref.read(authServiceProvider).signOut(),
          ),
        ],
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
      trailing: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}
