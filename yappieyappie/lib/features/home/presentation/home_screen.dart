import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yappieyappie/features/chat_list/presentation/chat_list_screen.dart';
import 'package:yappieyappie/features/profile/presentation/profile_screen.dart';
import 'package:yappieyappie/features/home/presentation/widgets/bottom_nav_bar.dart';
import 'package:yappieyappie/features/search/presentation/search_screen.dart';
import 'package:yappieyappie/core/globals/app_globals.dart';
import 'package:yappieyappie/features/chat/presentation/screens/private_chat_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    AppGlobals.isAppReady = true;

    // Process any deep link that was tapped while the app was killed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (AppGlobals.pendingChatUser != null) {
        final user = AppGlobals.pendingChatUser!;
        AppGlobals.pendingChatUser = null; // Clear it so it doesn't double-trigger
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PrivateChatScreen(otherUser: user),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // Prevent rendering when user is not authenticated
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("User not logged in")),
      );
    }

    // Each screen manages its own AppBar now
    final screens = [
      const ChatListScreen(),
      const SearchScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      // Keeps all tabs alive (no rebuild on switch)
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),

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
}
