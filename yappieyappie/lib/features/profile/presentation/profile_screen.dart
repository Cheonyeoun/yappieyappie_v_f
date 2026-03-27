import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yappieyappie/models/user_model.dart';
import 'package:yappieyappie/services/auth/auth_service.dart';

class ProfileScreen extends ConsumerWidget {
  final UserModel? user;

  const ProfileScreen({super.key, this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isOwnProfile = user == null || (user!.uid == currentUid);

    final displayUser = user ??
        UserModel(
          uid: currentUid ?? '',
          name: '',
          username: '',
          email: '',
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(isOwnProfile ? "My Profile" : "@${displayUser.username}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showMenu(context, ref, isOwnProfile, displayUser),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 40),
            CircleAvatar(
              radius: 80,
              backgroundColor: Colors.grey[800],
              backgroundImage: displayUser.profileimg != null &&
                      displayUser.profileimg!.isNotEmpty
                  ? NetworkImage(displayUser.profileimg!)
                  : null,
              child: (displayUser.profileimg == null ||
                      displayUser.profileimg!.isEmpty)
                  ? const Icon(Icons.person, size: 90, color: Colors.white70)
                  : null,
            ),
            const SizedBox(height: 24),
            Text(
              displayUser.name.isEmpty ? "No Name" : displayUser.name,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            Text(
              "@${displayUser.username}",
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.circle,
                  size: 14,
                  color: displayUser.isOnline ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  displayUser.isOnline ? "Online" : "Last seen recently",
                  style: TextStyle(
                    color: displayUser.isOnline ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            if (displayUser.bio != null && displayUser.bio!.isNotEmpty)
              Text(
                displayUser.bio!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, height: 1.6),
              ),
            const Spacer(),
            if (!isOwnProfile)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Messaging @${displayUser.username} (coming soon)",
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text("Message", style: TextStyle(fontSize: 17)),
                ),
              ),
          ],
        ),
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
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.person_add_alt),
                title: const Text('Send Friend Request'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Friend request feature coming soon'),
                    ),
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
