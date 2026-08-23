import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AppLifecycleObserver extends StatefulWidget {
  final Widget child;
  const AppLifecycleObserver({super.key, required this.child});

  @override
  State<AppLifecycleObserver> createState() => _AppLifecycleObserverState();
}

class _AppLifecycleObserverState extends State<AppLifecycleObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = FirebaseFirestore.instance.collection('users').doc(uid);

    if (state == AppLifecycleState.resumed) {
      doc.update(
          {'isOnline': true, 'lastActive': FieldValue.serverTimestamp()});
    } else {
      // Handles Paused, Inactive, and Detached
      doc.update(
          {'isOnline': false, 'lastActive': FieldValue.serverTimestamp(), 'currentChatId': null});
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
