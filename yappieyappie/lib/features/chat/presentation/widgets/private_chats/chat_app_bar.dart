import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yappieyappie/features/profile/presentation/profile_screen.dart';
import 'package:yappieyappie/models/profile/user_model.dart';
import 'package:yappieyappie/services/providers/profile/user_provider.dart';

class ChatAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final UserModel otherUser;
  const ChatAppBar({super.key, required this.otherUser});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userStreamProvider(otherUser.uid));

    return AppBar(
      backgroundColor: Colors.black,
      elevation: 0.5,

      // WRAPPED TITLE IN INKWELL: Opens user profile when tapped
      title: InkWell(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ProfileScreen(user: otherUser)));
        },
        child: userAsync.when(
          data: (user) => Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: user.profileimg?.isNotEmpty == true
                    ? NetworkImage(user.profileimg!)
                    : null,
                child: user.profileimg?.isEmpty ?? true
                    ? const Icon(Icons.person)
                    : null,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name.isNotEmpty ? user.name : 'User',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (user.showOnlineStatus)
                    Text(
                      user.isOnline ? "Active now" : "Offline",
                      style: TextStyle(
                        fontSize: 11,
                        color: user.isOnline ? Colors.greenAccent : Colors.grey,
                      ),
                    ),
                ],
              ),
            ],
          ),
          loading: () =>
              const Text("Loading...", style: TextStyle(color: Colors.white)),
          error: (_, __) =>
              const Text("User", style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
