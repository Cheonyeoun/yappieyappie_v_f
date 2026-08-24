import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yappieyappie/models/profile/user_model.dart';
import 'package:yappieyappie/features/chat/presentation/screens/private_chat_screen.dart';
import 'package:yappieyappie/services/auth/auth_service.dart';
import 'package:yappieyappie/services/providers/profile/user_provider.dart'; // make sure this path is correct

class ProfileScreen extends ConsumerWidget {
  final UserModel? user; // null = own profile, else = other user

  const ProfileScreen({super.key, this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    // Decide which UID to load
    final profileUid = user?.uid ?? currentUid;

    if (profileUid == null) {
      return const Scaffold(
        body: Center(child: Text("User not found")),
      );
    }

    // Watch user data in real-time from Firestore
    final userAsync = ref.watch(userStreamProvider(profileUid));

    return userAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text("Error: $e")),
      ),
      data: (displayUser) {
        final isOwnProfile = displayUser.uid == currentUid;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              isOwnProfile ? "My Profile" : "@${displayUser.username}",
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () =>
                    _showMenu(context, ref, isOwnProfile, displayUser),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // Profile Picture
                CircleAvatar(
                  radius: 80,
                  backgroundColor: Colors.grey[800],
                  backgroundImage: displayUser.profileimg != null &&
                          displayUser.profileimg!.isNotEmpty
                      ? NetworkImage(displayUser.profileimg!)
                      : null,
                  child: (displayUser.profileimg == null ||
                          displayUser.profileimg!.isEmpty)
                      ? const Icon(Icons.person,
                          size: 90, color: Colors.white70)
                      : null,
                ),

                const SizedBox(height: 24),

                // Name
                Text(
                  displayUser.name.isNotEmpty
                      ? displayUser.name
                      : "No Name Set",
                  style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.bold),
                ),

                // Username
                Text(
                  "@${displayUser.username.isNotEmpty ? displayUser.username : 'unknown'}",
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),

                const SizedBox(height: 16),

                // Online Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.circle,
                      size: 14,
                      color: displayUser.isActuallyOnline ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      displayUser.isActuallyOnline ? "Online" : "Last seen recently",
                      style: TextStyle(
                        color:
                            displayUser.isActuallyOnline ? Colors.green : Colors.grey,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Bio
                if (displayUser.bio != null && displayUser.bio!.isNotEmpty)
                  Text(
                    displayUser.bio!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, height: 1.6),
                  ),

                const SizedBox(height: 60),

                // Message Button (only for other users)
                if (!isOwnProfile)
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () => _openChat(context, displayUser),
                      icon: const Icon(Icons.chat_bubble_outline),
                      label:
                          const Text("Message", style: TextStyle(fontSize: 17)),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Opens private chat screen
  void _openChat(BuildContext context, UserModel user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PrivateChatScreen(otherUser: user),
      ),
    );
  }

  void _showMenu(
    BuildContext context,
    WidgetRef ref,
    bool isOwnProfile,
    UserModel user,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            if (!isOwnProfile) ...[
              ListTile(
                leading: const Icon(Icons.message),
                title: const Text('Message'),
                onTap: () {
                  Navigator.pop(context);
                  _openChat(context, user);
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_add_alt),
                title: const Text('Send Friend Request'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Friend request coming soon')),
                  );
                },
              ),
            ] else ...[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Profile'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await ref.read(authServiceProvider).signOut();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
