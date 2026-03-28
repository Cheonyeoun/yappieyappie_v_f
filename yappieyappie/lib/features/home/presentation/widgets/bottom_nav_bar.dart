import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      backgroundColor: const Color(0xFF0A0A0A),
      selectedItemColor: const Color.fromARGB(255, 255, 140, 0),
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      items: [
        // Chats Tab - Paper Plane Icon
        const BottomNavigationBarItem(
          icon: Icon(Icons.send_outlined),
          activeIcon: Icon(Icons.send),
          label: 'Talkies',
        ),

        // Search Tab
        const BottomNavigationBarItem(
          icon: Icon(Icons.search),
          activeIcon: Icon(Icons.search),
          label: 'Search',
        ),

        // Profile Tab - Dynamic Profile Picture
        BottomNavigationBarItem(
          icon: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser?.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Icon(Icons.person_outline, size: 28);
              }

              final data = snapshot.data!.data() as Map<String, dynamic>;
              final profileImg = data['profileimg'] as String?;

              if (profileImg != null && profileImg.isNotEmpty) {
                return CircleAvatar(
                  radius: 14,
                  backgroundImage: NetworkImage(profileImg),
                );
              } else {
                return const Icon(Icons.person_outline, size: 28);
              }
            },
          ),
          activeIcon: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser?.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Icon(Icons.person, size: 28);
              }

              final data = snapshot.data!.data() as Map<String, dynamic>;
              final profileImg = data['profileimg'] as String?;

              if (profileImg != null && profileImg.isNotEmpty) {
                return CircleAvatar(
                  radius: 14,
                  backgroundImage: NetworkImage(profileImg),
                );
              } else {
                return const Icon(Icons.person, size: 28);
              }
            },
          ),
          label: 'Profile',
        ),
      ],
    );
  }
}
