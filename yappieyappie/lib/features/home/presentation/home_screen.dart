import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yappieyappie/services/auth_service.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;

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
      body: StreamBuilder<DocumentSnapshot>(
        // Listen to the specific user document in Firestore
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Waiting for user data..."));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("USER IDENTITY",
                    style: TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text("Username: @${data['username']}",
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                Text("Email: ${data['email']}"),
                const SizedBox(height: 30),
                const Text("GHOST LOG DATA ☠️",
                    style: TextStyle(
                        color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _statusTile(
                    "Is Online",
                    data['isOnline'].toString(),
                    Icons.circle,
                    data['isOnline'] ? Colors.green : Colors.grey),
                _statusTile(
                    "Visibility Toggle",
                    data['showOnlineStatus'] ? "Visible" : "Hidden",
                    Icons.visibility,
                    Colors.blue),
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
