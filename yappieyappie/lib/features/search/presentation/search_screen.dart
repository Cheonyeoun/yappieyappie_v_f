import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:yappieyappie/models/profile/user_model.dart';
import 'package:yappieyappie/features/profile/presentation/profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Search.."),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search username or name...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                filled: true,
                fillColor: const Color.fromARGB(255, 51, 51, 51),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final filteredUsers = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  final username =
                      (data['username'] ?? '').toString().toLowerCase();
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final email = (data['email'] ?? '').toString().toLowerCase();
                  final uid = data['uid'] ?? '';

                  return (username.contains(searchQuery) ||
                          name.contains(searchQuery) ||
                          email.contains(searchQuery)) &&
                      uid != currentUid;
                }).toList();

                if (filteredUsers.isEmpty && searchQuery.isNotEmpty) {
                  return const Center(child: Text("No matching users found"));
                }

                return ListView.builder(
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final data =
                        filteredUsers[index].data() as Map<String, dynamic>;

                    final userModel = UserModel.fromMap(data);

                    return ListTile(
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundImage: userModel.profileimg != null &&
                                userModel.profileimg!.isNotEmpty
                            ? NetworkImage(userModel.profileimg!)
                            : null,
                        child: (userModel.profileimg == null ||
                                userModel.profileimg!.isEmpty)
                            ? const Icon(Icons.person, size: 32)
                            : null,
                      ),
                      title: Text(userModel.name),
                      subtitle: Text('@${userModel.username}'),
                      trailing: userModel.isOnline == true
                          ? const Icon(Icons.circle,
                              size: 12, color: Colors.green)
                          : null,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProfileScreen(user: userModel),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
